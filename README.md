kVersion
=========
- Appstore版本检测
- remote版本检测（自定义json）
- 版本数据下载和对比在后台线程，不阻塞ui

kVersion会对比版本文件中，App对应的bundle，system version,device supported,app version.
- kVersionPerferHigerVersion  对比appstore和remote的版本，取高者更新
- kVersionOnlyAppStore  仅对比更新appstore版本
- kVersionOnlyRemote    仅对比更新retmote版本
 

关于选项
- 马上更新  跳转appstore或者跳转自定义download url(如蒲公英地址)
- 取消   默认一天内不再提示
- 不再提示   默认一周内不在提示
 
用法
----------
kVersion文件引入项目即生效。

配置AppDelegate.m
```objective-c

    
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    //debug mode：跳过时间判断检测
    [kVersion sharedVersion].debug=YES;
    
    //上架的appid， 可为空
    [kVersion sharedVersion].appStoreID=@"1115493184";

    //remote的服务器路径
    [kVersion sharedVersion].remoteUrl=@"https://raw.githubusercontent.com/aklee/test/master/iversonJson.txt";
    
   
}
```

 
remote版本文件格式
----------
```objective-c
{
    "results": [
        {
            "bundleId": "com.xmns.www",
            "minimumOsVersion": "7.0",
            "releaseNotes": "完善推送功能,完善推送功能完善推送功能完善推送功能完善推送功能完善推送功能完善推送功能完善推送功能完善推送功能完善推送功能完善推送功能完善推送功能完善推送功能完善推送功能完善推送功能完善推送功能完善推送功能完善推送功能",
            "version": "1.0",
            "des": "update ui",
            "downloadUrl": "https://www.pgyer.com/xmns"
        }, 
        {
            "bundleId": "com.xmns.www",
            "minimumOsVersion": "7.0",
            "releaseNotes": "完善推送功能,完善推送功能完善推送功能完善推送功能完善推送功能完善推送功能完善推送功能完善推送功能完善推送功能完善推送功能完善推送功能完善推送功能完善推送功能完善推送功能完善推送功能完善推送功能完善推送功能完善推送功能",
            "version": "1.0.1",
            "des": "update apns",
            "downloadUrl": "https://www.pgyer.com/xmns"
        }
    ]
}
```

 
