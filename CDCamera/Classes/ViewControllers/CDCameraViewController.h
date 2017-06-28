//
//  CDCameraViewController.h
//  CircleAnimation
//
//  Created by Carlos Duclos on 5/17/17.
//  Copyright © 2017 Connect Network. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CDCameraType.h"

@class CDCameraViewController;
@protocol CDCameraViewControllerDelegate <NSObject>

- (void)cameraControllerDidClose:(CDCameraViewController *)controller;
- (void)cameraController:(CDCameraViewController *)controller didSelectPhoto:(UIImage *)image;
- (void)cameraController:(CDCameraViewController *)controller didSelectVideo:(NSURL *)videoUrl;
- (void)cameraControllerWasInterrupted:(CDCameraViewController *)controller;

@end

@interface CDCameraViewController : UIViewController

@property (nonatomic, weak) id<CDCameraViewControllerDelegate> delegate;

+ (instancetype)instanceWithType:(kCDCameraType)type maxDuration:(CGFloat)maxDuration;

@end

