//
//  CCAudioCapture.h
//  ChromeCastLive
//
//  Created by David.Dai on 16/9/20.
//  Copyright © 2016年 David.Dai. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef void (^CCAudioBlock)(const AudioTimeStamp *time,UInt32  frames,AudioBufferList *audio);

@interface CCAudioCapture : NSObject

- (void)startMicAudio:(CCAudioBlock)block;
- (void)stopMicAudio;
@end
