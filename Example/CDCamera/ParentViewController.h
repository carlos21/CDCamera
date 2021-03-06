//
//  ParentViewController.h
//  CDCamera
//
//  Created by Carlos Duclos on 11/27/17.
//  Copyright © 2017 Connect Network. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CDCamera/CDCameraViewController.h>

@interface ParentViewController : UIViewController

@property (weak, nonatomic) id<CDCameraViewControllerDelegate> delegate;

- (instancetype)initWithType:(kCDCameraType)cameraType maxDuration:(CGFloat)maxDuration;

@end
