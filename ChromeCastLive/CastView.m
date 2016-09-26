//
//  CastView.m
//  ChromeCastLive
//
//  Created by David.Dai on 16/9/20.
//  Copyright © 2016年 David.Dai. All rights reserved.
//

#import "CastView.h"

@implementation CastView
{
    GCKViewVideoFrameInput *_castInput;
}

- (instancetype)initWithSession:(id<GCKRemoteDisplaySession>)session
{
    if(self = [super init])
    {
        self.castRemoteDisplaySession = session;
    }
    return self;
}

- (id<GCKRemoteDisplaySession>)castRemoteDisplaySession
{
    return _castInput.session;
}

- (void)setCastRemoteDisplaySession:(id<GCKRemoteDisplaySession>)castRemoteDisplaySession
{
    if (castRemoteDisplaySession == _castInput.session)
        return;
    
    if (castRemoteDisplaySession)
        _castInput = [[GCKViewVideoFrameInput alloc] initWithSession:castRemoteDisplaySession];
}

- (void)setCastView:(UIView *)view frameInterval:(NSInteger)frameInterval
{
    _castInput.view = view;
    if(frameInterval)_castInput.frameInterval = frameInterval;
}

- (void)pauseCastView:(BOOL)pause
{
    _castInput.paused = pause;
}


@end
