//
//  CastView.h
//  ChromeCastLive
//
//  Created by David.Dai on 16/9/20.
//  Copyright © 2016年 David.Dai. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CastView : NSObject

@property(nonatomic, weak) id<GCKRemoteDisplaySession> castRemoteDisplaySession;

- (instancetype)initWithSession:(id<GCKRemoteDisplaySession>)session;

- (void)setCastView:(UIView *)view frameInterval:(NSInteger)frameInterval;
- (void)pauseCastView:(BOOL)pause;

@end
