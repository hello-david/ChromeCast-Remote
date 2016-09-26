//
//  CCAudioUnitCapture.m
//  ChromeCastLive
//
//  Created by David.Dai on 16/9/22.
//  Copyright © 2016年 David.Dai. All rights reserved.
//

#import "CCAudioUnitCapture.h"
#define kOutputBus  0
#define kInputBus   1

@interface  CCAudioUnitCapture()
{
    AudioBuffer buffer;
    AudioBufferList bufferList;
}
@property (nonatomic, assign) AudioComponentInstance componetInstance;
@property (nonatomic, assign) AudioComponent component;
@property (nonatomic, strong) dispatch_queue_t taskQueue;
@property (nonatomic, assign) BOOL isRunning;
@property (nonatomic, copy)   CCAudioUnitBlock getBlock;

@end

@implementation CCAudioUnitCapture


- (instancetype)init
{
    if (self = [super init]) {
        [self requestAccessForAudio];
    }
    return self;
}
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    dispatch_sync(self.taskQueue, ^
                  {
                      if (self.componetInstance)
                      {
                          AudioOutputUnitStop(self.componetInstance);
                          AudioComponentInstanceDispose(self.componetInstance);
                          self.componetInstance = nil;
                          self.component = nil;
                      }
                  });
}

- (void)setRunning:(BOOL)running
{
    if (_running == running) return;
    _running = running;
    if (_running)
    {
        dispatch_async(self.taskQueue, ^{
            self.isRunning = YES;
            NSLog(@"MicrophoneSource: startRunning");
            [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker | AVAudioSessionCategoryOptionInterruptSpokenAudioAndMixWithOthers error:nil];
            AudioOutputUnitStart(self.componetInstance);
        });
    } else {
        self.isRunning = NO;
    }
}

- (void)startMicAudio:(CCAudioUnitBlock)block
{
    _getBlock = block;
    self.running = YES;
}

- (void)stopMicAudio
{
    _getBlock = nil;
    self.running = NO;
}

- (void)requestAccessForAudio
{
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    switch (status) {
        case AVAuthorizationStatusNotDetermined:
        {
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL granted)
             {
                 if(granted)
                     [self setupAudioCapture];
                 else
                     NSLog(@"microPhone access fail");
             }];
            break;
        }
            
        case AVAuthorizationStatusAuthorized:
        {
            [self setupAudioCapture];
            break;
        }
        case AVAuthorizationStatusDenied:
        case AVAuthorizationStatusRestricted:
            break;
        default:
            break;
    }
}

- (void)setupAudioCapture
{
    self.isRunning = NO;
    self.taskQueue = dispatch_queue_create("com.audioCapture.Queue", NULL);
    
    AVAudioSession *session = [AVAudioSession sharedInstance];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleRouteChange:)
                                                 name: AVAudioSessionRouteChangeNotification
                                               object: session];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleInterruption:)
                                                 name: AVAudioSessionInterruptionNotification
                                               object: session];
    AudioComponentDescription acd;
    acd.componentType           = kAudioUnitType_Output;
    acd.componentSubType        = kAudioUnitSubType_RemoteIO;
    acd.componentManufacturer   = kAudioUnitManufacturer_Apple;
    acd.componentFlags          = 0;
    acd.componentFlagsMask      = 0;
    self.component = AudioComponentFindNext(NULL, &acd);
    
    OSStatus status = noErr;
    status = AudioComponentInstanceNew(self.component, &_componetInstance);
    if (noErr != status) {
        NSLog(@"Audio Componet Instance New Error");
    }
    UInt32 flagOne = 1;
    //define that we want record io on the input bus
    AudioUnitSetProperty(self.componetInstance, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, kInputBus, &flagOne, sizeof(flagOne));
    
    //set the format on the input stream
    AudioStreamBasicDescription audioFormat = {0};
    audioFormat.mSampleRate        = 44100;
    audioFormat.mFormatID          = kAudioFormatLinearPCM;
    audioFormat.mFormatFlags       = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagsNativeEndian | kAudioFormatFlagIsPacked;
    audioFormat.mChannelsPerFrame  = 2;
    audioFormat.mFramesPerPacket   = 1;
    audioFormat.mBitsPerChannel    = 16;
    audioFormat.mBytesPerFrame     = audioFormat.mBitsPerChannel / 8 * audioFormat.mChannelsPerFrame;
    audioFormat.mBytesPerPacket    = audioFormat.mBytesPerFrame * audioFormat.mFramesPerPacket;
    AudioUnitSetProperty(self.componetInstance, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, kInputBus, &audioFormat, sizeof(audioFormat));
    
    // set input callback callback on the input bus
    AURenderCallbackStruct callBack;
    callBack.inputProcRefCon = (__bridge void *)(self);
    callBack.inputProc = handleInputBuffer;
    AudioUnitSetProperty(self.componetInstance, kAudioOutputUnitProperty_SetInputCallback, kAudioUnitScope_Global, kInputBus, &callBack, sizeof(callBack));
    
    status = AudioUnitInitialize(self.componetInstance);
    if (noErr != status) {
        NSLog(@"Audio UnitInit Fail");
    }
    
    [session setPreferredSampleRate:44100 error:nil];
    [session setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker | AVAudioSessionCategoryOptionInterruptSpokenAudioAndMixWithOthers error:nil];
    [session setActive:YES withOptions:kAudioSessionSetActiveFlag_NotifyOthersOnDeactivation error:nil];
    [session setActive:YES error:nil];
}

#pragma mark -- NSNotification
- (void)handleRouteChange:(NSNotification *)notification {
    AVAudioSession *session = [ AVAudioSession sharedInstance];
    NSString *seccReason = @"";
    NSInteger reason = [[[notification userInfo] objectForKey:AVAudioSessionRouteChangeReasonKey] integerValue];
    //  AVAudioSessionRouteDescription* prevRoute = [[notification userInfo] objectForKey:AVAudioSessionRouteChangePreviousRouteKey];
    switch (reason) {
        case AVAudioSessionRouteChangeReasonNoSuitableRouteForCategory:
            seccReason = @"The route changed because no suitable route is now available for the specified category.";
            break;
        case AVAudioSessionRouteChangeReasonWakeFromSleep:
            seccReason = @"The route changed when the device woke up from sleep.";
            break;
        case AVAudioSessionRouteChangeReasonOverride:
            seccReason = @"The output route was overridden by the app.";
            break;
        case AVAudioSessionRouteChangeReasonCategoryChange:
            seccReason = @"The category of the session object changed.";
            break;
        case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:
            seccReason = @"The previous audio output path is no longer available.";
            break;
        case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
            seccReason = @"A preferred new audio output path is now available.";
            break;
        case AVAudioSessionRouteChangeReasonUnknown:
        default:
            seccReason = @"The reason for the change is unknown.";
            break;
    }
    NSLog(@"handleRouteChange reason is %@", seccReason);
    
    AVAudioSessionPortDescription *input = [[session.currentRoute.inputs count] ? session.currentRoute.inputs : nil objectAtIndex:0];
    if (input.portType == AVAudioSessionPortHeadsetMic) {
        
    }
}

- (void)handleInterruption:(NSNotification *)notification {
    NSInteger reason = 0;
    NSString *reasonStr = @"";
    if ([notification.name isEqualToString:AVAudioSessionInterruptionNotification]) {
        //Posted when an audio interruption occurs.
        reason = [[[notification userInfo] objectForKey:AVAudioSessionInterruptionTypeKey] integerValue];
        if (reason == AVAudioSessionInterruptionTypeBegan) {
            if (self.isRunning) {
                dispatch_sync(self.taskQueue, ^{
                    NSLog(@"MicrophoneSource: stopRunning");
                    AudioOutputUnitStop(self.componetInstance);
                });
            }
        }
        
        if (reason == AVAudioSessionInterruptionTypeEnded) {
            reasonStr = @"AVAudioSessionInterruptionTypeEnded";
            NSNumber *seccondReason = [[notification userInfo] objectForKey:AVAudioSessionInterruptionOptionKey];
            switch ([seccondReason integerValue]) {
                case AVAudioSessionInterruptionOptionShouldResume:
                    if (self.isRunning) {
                        dispatch_async(self.taskQueue, ^{
                            NSLog(@"MicrophoneSource: stopRunning");
                            AudioOutputUnitStart(self.componetInstance);
                        });
                    }
                    // Indicates that the audio session is active and immediately ready to be used. Your app can resume the audio operation that was interrupted.
                    break;
                default:
                    break;
            }
        }
        
    };
    NSLog(@"handleInterruption: %@ reason %@", [notification name], reasonStr);
}

static OSStatus handleInputBuffer(void *inRefCon,
                                  AudioUnitRenderActionFlags *ioActionFlags,
                                  const AudioTimeStamp *inTimeStamp,
                                  UInt32 inBusNumber,
                                  UInt32 inNumberFrames,
                                  AudioBufferList *ioData)
{
    CCAudioUnitCapture *source = (__bridge CCAudioUnitCapture *)inRefCon;
    if (!source) return -1;
    
    source->buffer.mData = NULL;
    source->buffer.mDataByteSize      = 0;
    source->buffer.mNumberChannels    = 1;
    source->bufferList.mNumberBuffers = 1;
    source->bufferList.mBuffers[0]    = source->buffer;
    
    OSStatus status = AudioUnitRender(source.componetInstance,
                                      ioActionFlags,
                                      inTimeStamp,
                                      inBusNumber,
                                      inNumberFrames,
                                      &(source->bufferList));
    
    if (!source.isRunning)
    {
        dispatch_sync(source.taskQueue, ^{
            NSLog(@"MicrophoneSource: stopRunning");
            AudioOutputUnitStop(source.componetInstance);
        });
        
        return status;
    }
    
    if (source.muted)
    {
        for (int i = 0; i < (source->bufferList).mNumberBuffers; i++) {
            AudioBuffer ab = (source->bufferList).mBuffers[i];
            memset(ab.mData, 0, ab.mDataByteSize);
        }
    }
    
    if (!status)
    {
        if(source.getBlock)
            source.getBlock(inTimeStamp,inNumberFrames,&(source->bufferList));
    }
    
    return status;
}

@end
