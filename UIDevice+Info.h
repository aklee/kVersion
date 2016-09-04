//
//  UIDevice+Info.h
//
//  Created by ak on 14-9-24.
//  Copyright (c) 2014年 ak. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIDevice (Info) 



#pragma  - SupportedDevices
+ (NSString *)machineName;
+ (NSString *)simulatorNamePhone;
+ (NSString *)simulatorNamePad;
+ (NSString *)supportedDeviceName;

@end
