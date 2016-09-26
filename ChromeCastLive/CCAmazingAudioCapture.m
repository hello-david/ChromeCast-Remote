//
//  CCAmazingAudioCapture.m
//  ChromeCastLive
//
//  Created by David.Dai on 16/9/21.
//  Copyright © 2016年 David.Dai. All rights reserved.
//

#import "CCAmazingAudioCapture.h"
#import "AEPlaythroughChannel.h"
#import "AERecorder.h"

@interface CCAmazingAudioCapture()
@property (nonatomic) AEAudioController     *audioController;
@property (nonatomic) AEAudioFilePlayer     *loop;
@property (nonatomic, strong) AERecorder    *recorder;
@property (nonatomic, strong) AEPlaythroughChannel *playthroughChannel;
@property (nonatomic, strong) AEAudioFilePlayer *player;
@property (nonatomic, strong) AEAudioUnitFilter *filter;
@end

@implementation CCAmazingAudioCapture
{
    AEPlaythroughChannel *_playthrough;
}

- (instancetype)init
{
    if(self = [super init])
    {
        self.audioController = [[AEAudioController alloc]initWithAudioDescription:AEAudioStreamBasicDescriptionNonInterleavedFloatStereo inputEnabled:YES];
        self.audioController.preferredBufferDuration = 0.005;
        self.audioController.useMeasurementMode = YES;
    }
    return self;
}

- (void)startMicAudio:(AEBlockAudioReceiverBlock)block
{
    [self stopMicAudio];
    id<AEAudioReceiver> receiver = [AEBlockAudioReceiver audioReceiverWithBlock:block];
    [_audioController addInputReceiver:receiver];
    
    self.filter = [[AEAudioUnitFilter alloc] initWithComponentDescription:AEAudioComponentDescriptionMake(kAudioUnitManufacturer_Apple,
                                                                                                          kAudioUnitType_Effect,
                                                                                                          kAudioUnitSubType_Reverb2)];
    AudioUnitSetParameter(self.filter.audioUnit, kReverb2Param_DryWetMix, kAudioUnitScope_Global, 0, 100.f, 0);
    [_audioController addFilter:self.filter];

//    NSURL *file = [[NSBundle mainBundle] URLForResource:@"sound_new" withExtension:@"mp3"];
//    self.loop = [AEAudioFilePlayer audioFilePlayerWithURL:file error:NULL];
//    _loop.loop = YES;
//    [_audioController addChannels:@[_loop]];
//    id<AEAudioReceiver> receiver = [AEBlockAudioReceiver audioReceiverWithBlock:^(void *source, const AudioTimeStamp *time, UInt32 frames, AudioBufferList *audio) {
//        if(block)
//            block(time,frames,audio);
//    }];
//    [self.audioController addOutputReceiver:receiver forChannel:_loop];
//    _loop.channelIsPlaying = YES;
//    _loop.channelIsMuted   = YES;
    
    NSError *error = nil;
    BOOL result = [_audioController start:&error];
    if (!result) {
        NSLog(@"Error starting TAEE Audio Controller: %@", error);
    }
}

- (void)stopMicAudio
{
    [_audioController stop];
}

- (void)recordAudio
{
    if (_recorder)
    {
        [_recorder finishRecording];
        [_audioController removeOutputReceiver:_recorder];
        [_audioController removeInputReceiver:_recorder];
        self.recorder = nil;
    }
    
    else
    {
        self.recorder = [[AERecorder alloc] initWithAudioController:_audioController];
        NSArray *documentsFolders = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *path = [documentsFolders[0] stringByAppendingPathComponent:@"Recording.m4a"];
        NSError *error = nil;
        if ( ![_recorder beginRecordingToFileAtPath:path fileType:kAudioFileM4AType error:&error] ) {
            [[[UIAlertView alloc] initWithTitle:@"Error"
                                        message:[NSString stringWithFormat:@"Couldn't start recording: %@", [error localizedDescription]]
                                       delegate:nil
                              cancelButtonTitle:nil
                              otherButtonTitles:@"OK", nil] show];
            self.recorder = nil;
            return;
        }
        [_audioController addOutputReceiver:_recorder];
        [_audioController addInputReceiver:_recorder];
    }
}

- (void)playAudio
{
    if (_player)
    {
        [_audioController removeChannels:@[_player]];
        self.player = nil;
    }
    else
    {
        NSArray *documentsFolders = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *path = [documentsFolders[0] stringByAppendingPathComponent:@"Recording.m4a"];
        
        if ( ![[NSFileManager defaultManager] fileExistsAtPath:path] ) return;
        
        NSError *error = nil;
        self.player = [AEAudioFilePlayer audioFilePlayerWithURL:[NSURL fileURLWithPath:path] error:&error];
        
        if ( !_player ) {
            [[[UIAlertView alloc] initWithTitle:@"Error"
                                        message:[NSString stringWithFormat:@"Couldn't start playback: %@", [error localizedDescription]]
                                       delegate:nil
                              cancelButtonTitle:nil
                              otherButtonTitles:@"OK", nil] show];
            return;
        }
        
        _player.removeUponFinish = YES;
        [_audioController addChannels:@[_player]];
    }
}

@end
