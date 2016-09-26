//
//  RootViewController.m
//  ChromeCastLive
//
//  Created by David.Dai on 16/9/20.
//  Copyright © 2016年 David.Dai. All rights reserved.
//

#import "RootViewController.h"
#import "CastDeviceController.h"
#import "CastDeviceTableViewController.h"
#import "CastView.h"
#import "CCAudioCapture.h"
#import "CCAmazingAudioCapture.h"
#import "CCAudioUnitCapture.h"
#import "CCAudioCapture.h"

@interface RootViewController () <CastDeviceControllerDelegate,GCKRemoteDisplayChannelDelegate>
@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;

@end

@implementation RootViewController
{
    CastView            *castViewEvent;
    NSTimeInterval      _time;
    CCAudioUnitCapture    *_audioUnitCast;
    CCAmazingAudioCapture *_amazingAudioCast;
    CCAudioCapture      *_audioCast;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [CastDeviceController sharedInstance].delegate = self;
    [[CastDeviceController sharedInstance] clearPreviousSession];
    
//    _audioUnitCast = [[CCAudioUnitCapture alloc]init];
//    [_audioUnitCast startMicAudio:^(const AudioTimeStamp *time, UInt32 frames, AudioBufferList *audio)
//    {
//        CastDeviceController *ccdc = [CastDeviceController sharedInstance];
//        id<GCKRemoteDisplaySession> session = ccdc.remoteDisplaySession;
//        if (audio && session){
//            [session enqueueAudioBuffer:audio frames:frames pts:time];
//        }
//    }];
    
    
    _amazingAudioCast = [[CCAmazingAudioCapture alloc]init];
    [_amazingAudioCast startMicAudio:^(void *source, const AudioTimeStamp *time, UInt32 frames, AudioBufferList *audio) {
        CastDeviceController *ccdc = [CastDeviceController sharedInstance];
        id<GCKRemoteDisplaySession> session = ccdc.remoteDisplaySession;
        if (audio && session){
            [session enqueueAudioBuffer:audio frames:frames pts:time];
        }
    }];
    
    
//    _audioCast = [[CCAudioCapture alloc]init];
//    [_audioCast startMicAudio:^(const AudioTimeStamp *time, UInt32 frames, AudioBufferList *audio)
//    {
//        CastDeviceController *ccdc = [CastDeviceController sharedInstance];
//        id<GCKRemoteDisplaySession> session = ccdc.remoteDisplaySession;
//        if (audio && session){
//            [session enqueueAudioBuffer:audio frames:frames pts:time];
//        }
//    }];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self updateButtonDisplay];
    [CastDeviceController sharedInstance].delegate = self;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateButtonDisplay) name:kChromeCastScanChange object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark ---------------------------- UI ----------------------------
- (void)updateButtonDisplay
{
    if ([CastDeviceController sharedInstance].deviceScanner.devices.count > 0)
    {
        _playButton.hidden = NO;
    }
    else
    {
        _playButton.hidden = YES;
    }
}
- (IBAction)audioRecord:(id)sender {
    
    [_amazingAudioCast recordAudio];
}

- (IBAction)audioPlay:(id)sender {
    
    [_amazingAudioCast playAudio];
}

- (IBAction)tapPlayButton:(id)sender {
    _playButton.hidden = YES;
    CastDeviceTableViewController *deviceTableVC = [[CastDeviceTableViewController alloc]initWithStyle:UITableViewStyleGrouped];
    deviceTableVC.delegate       = [CastDeviceController sharedInstance];
    deviceTableVC.viewController = self;
    UINavigationController *nav  = [[UINavigationController alloc]initWithRootViewController:deviceTableVC];
    [self presentViewController:nav animated:YES completion:nil];
}

#pragma mark ---------------------------- CastDeviceControllerDelegate ----------------------------
- (void)didConnectToDevice:(GCKDevice *)device
{
    _playButton.hidden = YES;
    CastDeviceController *deviceController = [CastDeviceController sharedInstance];
    deviceController.remoteDisplayChannel  = [[GCKRemoteDisplayChannel alloc] init];
    deviceController.remoteDisplayChannel.delegate = self;
    [deviceController.deviceManager addChannel:deviceController.remoteDisplayChannel];
}

- (void)didDisconnect
{
    [self updateButtonDisplay];
}

#pragma mark ---------------------------- GCKRemoteDisplayChannelDelegate ----------------------------
- (void)remoteDisplayChannelDidConnect:(GCKRemoteDisplayChannel*)channel
{
    GCKRemoteDisplayConfiguration* configuration = [[GCKRemoteDisplayConfiguration alloc] init];
    configuration.videoStreamDescriptor.frameRate = GCKRemoteDisplayFrameRate60p;
    
    if (![channel beginSessionWithConfiguration:configuration error:NULL])
    {
        [self updateButtonDisplay];
    }
}

- (void)remoteDisplayChannel:(GCKRemoteDisplayChannel*)channel
             didBeginSession:(id<GCKRemoteDisplaySession>)session
{
    [CastDeviceController sharedInstance].remoteDisplaySession = session;
    [self updateButtonDisplay];
    castViewEvent = [[CastView alloc]initWithSession:session];
    
    [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(flashLabel) userInfo:nil repeats:YES];
    [castViewEvent setCastView:self.view frameInterval:1];
    [[CastDeviceController sharedInstance].deviceManager setMuted:NO];
}

- (void)flashLabel
{
    _time+= 0.01;
    dispatch_async(dispatch_get_main_queue(), ^{
        _timeLabel.text = [NSString stringWithFormat:@"Time:%f",_time];
    });
}

- (void)remoteDisplayChannel:(GCKRemoteDisplayChannel*)channel
 deviceRejectedConfiguration:(GCKRemoteDisplayConfiguration*)configuration
                       error:(NSError*)error
{
    [[CastDeviceController sharedInstance] disconnect];
    [self updateButtonDisplay];
}


@end
