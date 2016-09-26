//
//  AppDelegate.m
//  ChromeCastLive
//
//  Created by David.Dai on 16/9/18.
//  Copyright © 2016年 David.Dai. All rights reserved.
//

#import "AppDelegate.h"
#import "CastDeviceController.h"
#import <GoogleCast/GoogleCast.h>

#define DEFAULT_MEDIA_RECEIVER_APPLICATION_ID @""

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [[CastDeviceController sharedInstance] enableLogging];
    [CastDeviceController sharedInstance].applicationID = DEFAULT_MEDIA_RECEIVER_APPLICATION_ID;
    return YES;
}


@end
