//
//  kVersion.m
//  ModuleDemo
//
//  Created by ak on 16/8/31.
//  Copyright © 2016年 ak. All rights reserved.
//

#import "kVersion.h"
#import "AppDelegate.h"

#define kiOS8_OR_LATER    ( [[[UIDevice currentDevice] systemVersion] compare:@"8.0"] != NSOrderedAscending )
static const double kduration = 86400;//1 day
static const NSString * kAppLookupURLFormat = @"http://itunes.apple.com/%@/lookup";

@interface kVersion()<UIAlertViewDelegate>
{
    
    NSString* _curBuildVersion,*_curAppVersion,*_bundleID,*_curSysVersion,*_curAppStoreUrl;
    
    NSString* _versionTitle, *_versionDes;
    
    bool _needUpdateAppStore,_needUpdateRemote;
    
    NSMutableDictionary* _versionDic;
    
    NSDictionary* _selectedDic;
}
@property (nonatomic, copy) NSString *appStoreCountry;
@property(nonatomic,strong)NSDate * lastCheckTime;
@end
@implementation kVersion


+(void)load{
    
    
    [self performSelectorOnMainThread:@selector(sharedVersion) withObject:nil waitUntilDone:NO];
//    [kVersion sharedVersion];
}


+(instancetype)sharedVersion{
    static id instance=nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance=  [kVersion new];
    });
    return instance;
}

-(instancetype)init{
    self = [super init];
    if (self) {

        //        用于itunes上显示的版本号，即对外的版本。（最多是3个部分组成即 x.y.z）
       _curAppVersion= [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];

        //        内部项目管理的版本号，不对外。所以可以定义任意形式。
        _curBuildVersion=[[NSBundle mainBundle]objectForInfoDictionaryKey:@"CFBundleVersion"];
        
        _bundleID = [[NSBundle mainBundle] bundleIdentifier];
        
        _curSysVersion  = [UIDevice currentDevice].systemVersion;
        
        
        _type=kVersionPerferHigerVersion;
        
        self.showAlert=YES;
        
        self.launchCheck=YES;
        
        self.appStoreCountry = [(NSLocale *)[NSLocale currentLocale] objectForKey:NSLocaleCountryCode];
        
        if ([self.appStoreCountry isEqualToString:@"150"])
        {
            self.appStoreCountry = @"eu";
        }
        else if ([[self.appStoreCountry stringByReplacingOccurrencesOfString:@"[A-Za-z]{2}" withString:@"" options:NSRegularExpressionSearch range:NSMakeRange(0, 2)] length])
        {
            self.appStoreCountry = @"us";
        }

        _versionDic=@{
                     @"appstore":@{@"v":@"",@"des":@"",@"url":@""},
                     @"remote":@{@"v":@"",@"des":@"",@"url":@""},
                     }.mutableCopy;
        
//        [self applicationLaunched];//cant get value of appstoreid
        
        //app launched
        [self performSelectorOnMainThread:@selector(launched) withObject:nil waitUntilDone:NO];
    }
    return self;
}


-(void)launched{
    if (!self.launchCheck) {
        NSLog(@"kVersion:not check cause [kVersion sharedVersion].launchCheck=NO;");
        return;
    }
    
    NSDate* now = [NSDate date];
    if (!self.debug&&self.lastCheckTime&&[self.lastCheckTime timeIntervalSinceDate:now]<kduration) {
        //daily check
        NSLog(@"kVersion:not check cause the daily check,lastCheckTime is %@",self.lastCheckTime);
        return;
    }
    
    [self check];
    
}

-(void)check{
   
    [self checkAppStoreUpdate];
    
    [self checkRemoteUpdate];
    

    switch (self.type) {
        case kVersionOnlyAppStore:
        {
            
            _selectedDic=_versionDic[@"appstore"];
        }
            break;
        case kVersionOnlyRemote:
        {
            _selectedDic=_versionDic[@"remote"];
        }
            break;
        case kVersionPerferHigerVersion:
        {
            NSString* vApp=_versionDic[@"appstore"][@"v"];
            NSString* vRemote=_versionDic[@"remote"][@"v"];
            if([vApp compare:vRemote] == NSOrderedAscending){
                
                _selectedDic=_versionDic[@"remote"];
            }
            if([vApp compare:vRemote] == NSOrderedDescending){
                
                _selectedDic=_versionDic[@"appstore"];
            }
            
        }
            break;
            
            break;
        default:
            break;
    }
    
    [self performSelectorOnMainThread:@selector(alert) withObject:nil waitUntilDone:NO];
    
}
#pragma mark - AppStore

//thanks to  https://github.com/nicklockwood/iVersion
-(bool)checkAppStoreUpdate{
    _needUpdateAppStore=NO;
    
    _curAppStoreUrl=[NSString stringWithFormat:@"https://itunes.apple.com/%@/app/id%@?mt=8",self.appStoreCountry,self.appStoreID];
    
    NSURL* url = [NSURL URLWithString:[NSString stringWithFormat:@"http://itunes.apple.com/%@/lookup?id=%@",self.appStoreCountry,self.appStoreID]];
    NSURLRequest * req = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:60];
    
    NSHTTPURLResponse* response = nil;
  
    NSData* data= [NSURLConnection sendSynchronousRequest:req returningResponse:&response error:nil];
    
    NSLog(@"kVersion checking appstore on %@",url);
    
    if (data&&response.statusCode==200) {
       id dic= [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        NSString* resultsCount =  [dic objectForKey:@"resultCount"];
        if ([resultsCount intValue]>0) {
            NSDictionary* results = [(NSArray*)dic[@"results"] firstObject];
            //1bundle shound be same
            //2app version
            //3system version
            //3whether current device  is supported Device
            
            NSString* bundle= results[@"bundleId"];
            NSString* sysVersion=results[@"minimumOsVersion"];
            NSString* appStoreVersion =results[@"version"];
            NSString* releaseNotes=results[@"releaseNotes"];

            
            NSArray* supportedDevices = results[@"supportedDevices"];
            
            //appStoreVersion>_curAppVersion
            bool versionNeed =[appStoreVersion compare:_curAppVersion]==NSOrderedDescending;
            //sysVersion <=_curSysVersion
            bool sysVerNeed = [sysVersion compare:_curSysVersion]!=NSOrderedDescending;
            
            bool deviceNeed = !supportedDevices||[supportedDevices containsObject:[UIDevice supportedDeviceName]];
            if ([_bundleID isEqualToString:bundle]
                &&versionNeed
                &&sysVerNeed
                &&deviceNeed
                ) {
                //find update on AppStore
                _needUpdateAppStore=YES;
                
                _versionDic[@"appstore"]=@{@"v":appStoreVersion,@"des":releaseNotes,@"url":_curAppStoreUrl};
                
                NSLog(@"kVersion: find a update on appstore:%@",appStoreVersion);
            }
            else{
                NSLog(@"kVersion:find new version but not fit");
            }
            
        }
    }else{
        //no loopup info
        
        NSLog(@"kVersion: no info  on appstore");
    }
    
    return NO;
}

-(void)checkRemoteUpdate{
    _needUpdateRemote=NO;
    
    NSURLRequest * req = [NSURLRequest requestWithURL:[NSURL URLWithString:self.remoteUrl] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:60];
    
    NSHTTPURLResponse* response = nil;
    
    NSData* data= [NSURLConnection sendSynchronousRequest:req returningResponse:&response error:nil];
    
    NSLog(@"kVersion checking remote on %@",self.remoteUrl);
    
    if (data&&response.statusCode==200) {
        
        id dic= [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        NSArray* resultsArr =  [dic objectForKey:@"results"];
        if (resultsArr&&resultsArr.count>0) {
            
            for (int i = 0 ; i<resultsArr.count; i++) {
                NSDictionary* results =resultsArr[i];

                NSString* bundle= results[@"bundleId"];
                NSString* sysVersion=results[@"minimumOsVersion"];
                NSString* remoteVersion =results[@"version"];
                NSString* releaseNotes=results[@"releaseNotes"];
                NSString* downloadUrl = results[@"downloadUrl"];
                NSArray* supportedDevices = results[@"supportedDevices"];
                
                downloadUrl=downloadUrl.length==0?_curAppStoreUrl:downloadUrl;

                
                //appStoreVersion>_curAppVersion
                bool versionNeed =[remoteVersion compare:_curAppVersion]==NSOrderedDescending;
                //sysVersion <=_curSysVersion
                bool sysVerNeed = [sysVersion compare:_curSysVersion]!=NSOrderedDescending;
                
                bool deviceNeed = !supportedDevices||[supportedDevices containsObject:[UIDevice supportedDeviceName]];
                if ([_bundleID isEqualToString:bundle]
                    &&versionNeed
                    &&sysVerNeed
                    &&deviceNeed
                    ) {
                    //find update on remote
                    
                    _needUpdateRemote=YES;
                    
                    _versionDic[@"remote"]=@{@"v":remoteVersion,@"des":releaseNotes,@"url":downloadUrl};
                    NSLog(@"kVersion: find remote version:%@",remoteVersion);
                }
                else{
                    NSLog(@"kVersion:find new version but not fit");
                }
            }
        }
        
    }else{
        
        NSLog(@"kVersion: no info  on remote");
    }

}



-(void)alert{
    
    NSString* t= _selectedDic[@"v"];
    NSString* msg= _selectedDic[@"des"];
    if (t.length<=0) {
        return;
    }
    if (kiOS8_OR_LATER) {
        
        UIAlertController* alert=  [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"版本更新(%@)",t] message:msg preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"马上更新" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self update];
        }]];
        
        
        [alert addAction:[UIAlertAction actionWithTitle:@"不再提醒" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self noMoreTip];
        }]];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self dismiss];
        }]];
        
        UIViewController*nav =[UIApplication sharedApplication].delegate.window.rootViewController;
        
        if ([nav isKindOfClass:UINavigationController.class]) {
            
            [nav presentViewController:alert animated:YES completion:^{
                
            }];
        }
    }else{
        
        UIAlertView* view = [[UIAlertView alloc]initWithTitle:[NSString stringWithFormat:@"版本更新(%@)",t] message:msg delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"马上更新",@"不再提醒", nil];
        [view show];
        
    }
  
    
}

#pragma mark - Alert 

-(void)update{
    self.lastCheckTime=[NSDate date];
    
    NSString* urlStr= _selectedDic[@"url"];

    if (urlStr.length>0) {
        
        NSURL * url = [NSURL URLWithString:_selectedDic[@"url"]];
        
        [[UIApplication sharedApplication] openURL:url];
        
    }else{
        
    }
}

-(void)dismiss{
    self.lastCheckTime=[NSDate date];
}

-(void)noMoreTip{
   
    //no tip during a week
   self.lastCheckTime=[[NSDate date]dateByAddingTimeInterval:kduration*7];
}

-(void)setLastCheckTime:(NSDate *)lastCheckTime{
    
    [[NSUserDefaults standardUserDefaults]setObject:lastCheckTime forKey:@"klastCheckTime"];
    [[NSUserDefaults standardUserDefaults]synchronize];
    
}
-(NSDate *)lastCheckTime{
    
   return  [[NSUserDefaults standardUserDefaults]objectForKey:@"klastCheckTime"];
    
}
#pragma mark - AlertView
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    NSLog(@"idx:%ld",(long)buttonIndex);
    switch (buttonIndex) {
        case 1:
            [self update];
            break;
        case 2:
            [self noMoreTip];
            break;
        case 0:
            [self dismiss];
            break;
            
        default:
            break;
    }
}

@end