//
//  CCAmazingAudioCapture.h
//  ChromeCastLive
//
//  Created by David.Dai on 16/9/21.
//  Copyright © 2016年 David.Dai. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CCAmazingAudioCapture : NSObject

- (void)startMicAudio:(AEBlockAudioReceiverBlock)block;
- (void)stopMicAudio;
- (void)recordAudio;
- (void)playAudio;
@end
