//
//  CastDeviceController.m
//  ChromeCastLive
//
//  Created by David.Dai on 16/9/18.
//  Copyright © 2016年 David.Dai. All rights reserved.
//

#import "CastDeviceController.h"

 NSString * const connectedDeviceID = @"lastDeviceID";

@interface CastDeviceController() <GCKDeviceScannerListener,GCKDeviceManagerDelegate,GCKLoggerDelegate>

@property(nonatomic) BOOL isReconnecting;
@property(nonatomic) NSString *sessionID;

@end

@implementation CastDeviceController

+ (instancetype)sharedInstance
{
    static dispatch_once_t point = 0;
    __strong static id _sharedDeviceController = nil;
    dispatch_once(&point, ^{
        _sharedDeviceController = [[self alloc] init];
    });
    return _sharedDeviceController;
}

- (void)setApplicationID:(NSString *)applicationID
{
    _applicationID = applicationID;
    GCKFilterCriteria *filterCriteria = [GCKFilterCriteria criteriaForAvailableApplicationWithID:applicationID];
    self.deviceScanner = [[GCKDeviceScanner alloc] initWithFilterCriteria:filterCriteria];
    NSLog(@"Starting Scan");
    [self.deviceScanner addListener:self];
    [self.deviceScanner startScan];
}

#pragma mark ------------------------ GCKDeviceManagerDelegate ------------------------
- (void)deviceManagerDidConnect:(GCKDeviceManager *)deviceManager
{
    if (_isReconnecting && deviceManager.applicationMetadata && deviceManager.applicationMetadata.applicationID != self.applicationID)
    {
        [deviceManager disconnect];
        self.isReconnecting = NO;
        return;
    }
    
    [self.deviceScanner stopScan];
    
    NSInteger requestID = [self.deviceManager launchApplication:_applicationID];
    if (requestID == kGCKInvalidRequestID)
    {
        [deviceManager disconnect];
    }
}

- (void)deviceManager:(GCKDeviceManager *)deviceManager didConnectToCastApplication:(GCKApplicationMetadata *)applicationMetadata
            sessionID:(NSString *)sessionID
  launchedApplication:(BOOL)launchedApplication
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kChromeCastAppConnected object:self];
    
    if ([self.delegate respondsToSelector:@selector(didConnectToDevice:)]) {
        [self.delegate didConnectToDevice:deviceManager.device];
    }
    
    self.isReconnecting = NO;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:deviceManager.device.deviceID forKey:connectedDeviceID];
    [defaults synchronize];
    
    self.sessionID = sessionID;
}

- (void)deviceManager:(GCKDeviceManager *)deviceManage volumeDidChangeToLevel:(float)volumeLevel
              isMuted:(BOOL)isMuted
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kChromeCastVolumeChanged object:self];
}

- (void)deviceManager:(GCKDeviceManager *)deviceManager didFailToConnectWithError:(GCKError *)error
{
    [self clearPreviousSession];
}

- (void)deviceManager:(GCKDeviceManager *)deviceManager didDisconnectWithError:(GCKError *)error
{
    NSLog(@"Received notification that device disconnected");
    
    if (!error || (error.code == GCKErrorCodeDeviceAuthenticationFailure ||
                   error.code == GCKErrorCodeDisconnected ||
                   error.code == GCKErrorCodeApplicationNotFound))
    {
        [self clearPreviousSession];
    }
    
    if (_delegate && [_delegate respondsToSelector:@selector(didDisconnect)])
    {
        [_delegate didDisconnect];
    }
    
    [self.deviceScanner startScan];
}

- (void)deviceManager:(GCKDeviceManager *)deviceManager didDisconnectFromApplicationWithError:(NSError *)error
{
    NSLog(@"Received notification that app disconnected");
    
    if (error) {
        NSLog(@"Application disconnected with error: %@", error);
    }
    
    if (_delegate && [_delegate respondsToSelector:@selector(didDisconnect)]) {
        [_delegate didDisconnect];
    }
}

#pragma mark ------------------------ Reconnection ------------------------
- (void)clearPreviousSession
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:connectedDeviceID];
    [defaults synchronize];
    self.sessionID = nil;
    [_deviceScanner startScan];
}

#pragma mark ------------------------ GCKDeviceScannerListener ------------------------
- (void)deviceDidComeOnline:(GCKDevice *)device
{
    NSLog(@"device found - %@", device.friendlyName);
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *lastDeviceID   = [defaults objectForKey:connectedDeviceID];
    
    if (lastDeviceID != nil && [[device deviceID] isEqualToString:lastDeviceID])
    {
        self.isReconnecting = YES;
        [self connectToDevice:device];
    }
    
    if ([self.delegate respondsToSelector:@selector(didDiscoverDeviceOnNetwork)]) {
        [self.delegate didDiscoverDeviceOnNetwork];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kChromeCastScanChange object:self];
}

- (void)deviceDidGoOffline:(GCKDevice *)device
{
    NSLog(@"device went offline - %@", device.friendlyName);
    [[NSNotificationCenter defaultCenter] postNotificationName:kChromeCastScanChange object:self];
}

- (void)deviceDidChange:(GCKDevice *)device
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kChromeCastScanChange object:self];
}

#pragma mark ------------------------ Device & Media Management ------------------------
- (void)connectToDevice:(GCKDevice *)device
{
    NSLog(@"Connecting to device address: %@:%d", device.ipAddress, (unsigned int)device.servicePort);
    NSDictionary *info      = [[NSBundle mainBundle] infoDictionary];
    NSString *appIdentifier = [info objectForKey:@"CFBundleIdentifier"];
    self.deviceManager = [[GCKDeviceManager alloc] initWithDevice:device clientPackageName:appIdentifier];
    self.deviceManager.delegate = self;
    [self.deviceManager connect];
}

- (void)disconnect
{
    [self.deviceManager stopApplicationWithSessionID:_sessionID];
    [self.deviceManager disconnectWithLeave:YES];
}

#pragma mark ------------------------ GCKLoggerDelegate implementation ------------------------
- (void)enableLogging
{
    [[GCKLogger sharedInstance] setDelegate:self];
}

- (void)logFromFunction:(const char *)function message:(NSString *)message
{
    NSLog(@"%s  %@", function, message);
}


@end
