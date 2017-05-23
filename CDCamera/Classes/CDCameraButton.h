//
//  CDRecordButtonView.h
//  CircleAnimation
//
//  Created by Carlos Duclos on 5/17/17.
//  Copyright © 2017 Connect Network. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CDCameraType.h"

@class CDCameraButton;
@protocol CDCameraButtonDelegate <NSObject>

- (void)cameraButtonDidBeginLongPress;
- (void)cameraButtonDidEndLongPress;
- (void)cameraButtonDidReachMaximumDuration;
- (void)cameraButtonDidTap;

@end

@interface CDCameraButton : UIView

@property (nonatomic, weak) id<CDCameraButtonDelegate> delegate;
@property (nonatomic, assign) NSUInteger maxDuration;
@property (nonatomic, assign) kCDCameraType type;

- (void)reset;

@end
