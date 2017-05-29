//
//  CDViewController.m
//  CDCamera
//
//  Created by carlos21 on 05/23/2017.
//  Copyright (c) 2017 carlos21. All rights reserved.
//

#import "CDViewController.h"
#import <CDCamera/CDCameraViewController.h>

@interface CDViewController () <CDCameraViewControllerDelegate>

@end

@implementation CDViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.customLabel.text = NSLocalizedString(@"test_key", @"test");
}

- (IBAction)showTapped:(id)sender {
    CDCameraViewController *cameraController = [CDCameraViewController instanceWithType:kCDCameraTypePhoto maxDuration:15.0];
    cameraController.delegate = self;
    [cameraController willMoveToParentViewController:self];
    [self addChildViewController:cameraController];
    [self.view addSubview:cameraController.view];
    [cameraController didMoveToParentViewController:self];
}

#pragma mark - CDCameraViewControllerDelegate

- (void)cameraControllerDidClose:(CDCameraViewController *)controller {
    [controller removeFromParentViewController];
    [controller.view removeFromSuperview];
}

- (void)cameraController:(CDCameraViewController *)controller didSelectVideo:(NSURL *)videoUrl {
    
}

- (void)cameraController:(CDCameraViewController *)controller didSelectPhoto:(UIImage *)image {
    
}

@end
