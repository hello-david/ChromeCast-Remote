//
//  CCAudioCapture.m
//  ChromeCastLive
//
//  Created by David.Dai on 16/9/20.
//  Copyright © 2016年 David.Dai. All rights reserved.
//

#import "CCAudioCapture.h"
@import AVFoundation;

@interface CCAudioCapture() <AVCaptureAudioDataOutputSampleBufferDelegate>
@property (nonatomic, copy)  CCAudioBlock getBlock;
@end

@implementation CCAudioCapture
{
    AVCaptureSession        *_caputreSession;
    AVCaptureConnection     *_audioConnection;
    dispatch_queue_t        _audioQueue;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _caputreSession = [[AVCaptureSession alloc]init];
        _audioQueue = dispatch_queue_create("com.GPAudioLive", DISPATCH_QUEUE_SERIAL);
        [self setupAudioCapture];
    }
    return self;
}

- (void)setupAudioCapture
{
    NSError *error = nil;
    AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    AVCaptureDeviceInput *audioInput = [[AVCaptureDeviceInput alloc]initWithDevice:audioDevice error:&error];
    
    if (error){
        NSLog(@"Error getting audio input device:%@",error.description);
    }
    
    if ([_caputreSession canAddInput:audioInput]) {
        [_caputreSession addInput:audioInput];
    }
    
    AVCaptureAudioDataOutput *audioOutput = [AVCaptureAudioDataOutput new];
    [audioOutput setSampleBufferDelegate:self queue:_audioQueue];
    if ([_caputreSession canAddOutput:audioOutput]) {
        [_caputreSession addOutput:audioOutput];
    }
    
    _audioConnection = [audioOutput connectionWithMediaType:AVMediaTypeAudio];
}

- (void)startMicAudio:(CCAudioBlock)block
{
    _getBlock = block;
    [_caputreSession startRunning];
}

- (void)stopMicAudio
{
    [_caputreSession stopRunning];
    _getBlock = nil;
}


#pragma mark ---------------------Capture audio output delegate----------------------------------
- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{
    if(connection == _audioConnection)
    {
//        CMSampleTimingInfo timing_info;
//        CMSampleBufferGetSampleTimingInfo(sampleBuffer, 0, &timing_info);
//        const AudioStreamBasicDescription *audioDescription = CMAudioFormatDescriptionGetStreamBasicDescription(CMSampleBufferGetFormatDescription(sampleBuffer));
//        AudioBufferList *buffer = nil;
//        CMSampleBufferCopyPCMDataIntoAudioBufferList(sampleBuffer, 0, (int32_t)CMSampleBufferGetNumSamples(sampleBuffer), buffer);
    }
}


@end
