//
//  kVersion.h
//  ModuleDemo
//
//  Created by ak on 16/8/31.
//  Copyright © 2016年 ak. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef NS_OPTIONS(NSUInteger, kVersionPerfer){
    //check appstore first
    kVersionPerferHigerVersion=1<<0,
    //only check appstore
    kVersionOnlyAppStore=1<<1,
    //only check remote
    kVersionOnlyRemote=1<<2,
    
    
};
@interface kVersion : NSObject

//if yes,will not compare the time,default no
@property(nonatomic,assign)bool debug;

//check when app launch ,default yes
@property(nonatomic,assign)bool launchCheck;

@property(nonatomic,assign)kVersionPerfer type;

@property (nonatomic, copy)NSString* appStoreID;
 

@property(nonatomic,copy)NSString* remoteUrl;


+(instancetype)sharedVersion;

-(void)check;
@end
