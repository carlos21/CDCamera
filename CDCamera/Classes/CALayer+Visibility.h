//
//  CALayer+Visibility.h
//  CircleAnimation
//
//  Created by Carlos Duclos on 5/18/17.
//  Copyright © 2017 Connect Network. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

typedef void (^ActionsBlock)(void);
@interface CALayer (Visibility)

+ (void)performWithoutAnimation:(ActionsBlock)actionsWithoutAnimation;
- (void)bringSublayerToFront:(CALayer *)layer;

@end
