//
//  CALayer+Visibility.m
//  CircleAnimation
//
//  Created by Carlos Duclos on 5/18/17.
//  Copyright © 2017 Connect Network. All rights reserved.
//

#import "CALayer+Visibility.h"

@implementation CALayer (Visibility)

+ (void)performWithoutAnimation:(ActionsBlock)actionsWithoutAnimation {
    if (actionsWithoutAnimation) {
        // Wrap actions in a transaction block to avoid implicit animations.
        [CATransaction begin];
        [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
        
        actionsWithoutAnimation();
        
        [CATransaction commit];
    }
}

- (void)bringSublayerToFront:(CALayer *)layer {
    // Bring to front only if already in this layer's hierarchy.
    if ([layer superlayer] == self) {
        [CALayer performWithoutAnimation:^{
            
            // Add 'layer' to the end of the receiver's sublayers array.
            // If 'layer' already has a superlayer, it will be removed before being added.
            [self addSublayer:layer];
        }];
    }
}


@end
