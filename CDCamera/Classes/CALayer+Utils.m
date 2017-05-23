//
//  CALayer+Utils.m
//  CircleAnimation
//
//  Created by Carlos Duclos on 5/18/17.
//  Copyright © 2017 Connect Network. All rights reserved.
//

#import "CALayer+Utils.h"

@implementation CALayer (Utils)

- (void)pauseLayer {
    CFTimeInterval pausedTime = [self convertTime:CACurrentMediaTime() fromLayer:nil];
    self.speed = 0.0;
    self.timeOffset = pausedTime;
}

- (void)resumeLayer {
    CFTimeInterval pausedTime = [self timeOffset];
    self.speed = 1.0;
    self.timeOffset = 0.0;
    self.beginTime = 0.0;
    CFTimeInterval timeSincePause = [self convertTime:CACurrentMediaTime() fromLayer:nil] - pausedTime;
    self.beginTime = timeSincePause;
}

@end
