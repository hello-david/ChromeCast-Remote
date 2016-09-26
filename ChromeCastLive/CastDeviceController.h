//
//  CastDeviceController.h
//  ChromeCastLive
//
//  Created by David.Dai on 16/9/18.
//  Copyright © 2016年 David.Dai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CastDeviceTableViewController.h"

@protocol CastDeviceControllerDelegate <NSObject>

@optional
- (void)didConnectToDevice:(GCKDevice*)device;
- (void)didDisconnect;
- (void)didDiscoverDeviceOnNetwork;
@end

@interface CastDeviceController : NSObject <DeviceTableViewControllerDelegate>

@property (nonatomic, copy)   NSString *applicationID;
@property (nonatomic, weak)   id<CastDeviceControllerDelegate> delegate;
@property (nonatomic, strong) GCKDeviceManager *deviceManager;
@property (nonatomic, strong) GCKDeviceScanner *deviceScanner;
@property (nonatomic, strong) GCKRemoteDisplayChannel *remoteDisplayChannel;
@property (nonatomic, strong) id<GCKRemoteDisplaySession> remoteDisplaySession;

+ (instancetype)sharedInstance;
- (void)enableLogging;
- (void)connectToDevice:(GCKDevice *)device;
- (void)clearPreviousSession;
- (void)disconnect;

@end
