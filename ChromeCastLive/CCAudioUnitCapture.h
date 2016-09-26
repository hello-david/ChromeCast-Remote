//
//  CCAudioUnitCapture.h
//  ChromeCastLive
//
//  Created by David.Dai on 16/9/22.
//  Copyright © 2016年 David.Dai. All rights reserved.
//

#import <Foundation/Foundation.h>
@import AVFoundation;
typedef void (^CCAudioUnitBlock)(const AudioTimeStamp *time,UInt32  frames,AudioBufferList *audio);

@interface CCAudioUnitCapture : NSObject
@property (nonatomic, assign) BOOL muted;
@property (nonatomic, assign) BOOL running;

- (void)startMicAudio:(CCAudioUnitBlock)block;
- (void)stopMicAudio;
@end
