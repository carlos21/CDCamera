//
//  CDViewController.m
//  CDCamera
//
//  Created by carlos21 on 05/23/2017.
//  Copyright (c) 2017 carlos21. All rights reserved.
//

#import "CDViewController.h"
#import <CDCamera/CDCameraViewController.h>
#import "ParentViewController.h"

@interface CDViewController () <CDCameraViewControllerDelegate>

@end

@implementation CDViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.customLabel.text = NSLocalizedString(@"test_key", @"test");
}

- (IBAction)showTapped:(id)sender {
    ParentViewController *cameraController = [[ParentViewController alloc] initWithType:kCDCameraTypeVideo maxDuration:60.0];
    //CDCameraViewController *cameraController = [CDCameraViewController instanceWithType:kCDCameraTypeVideo maxDuration:60.0];
    cameraController.delegate = self;
    [self presentViewController:cameraController animated:YES completion:nil];
    
//    CDCameraViewController *cameraController = [CDCameraViewController instanceWithType:kCDCameraTypeVideo maxDuration:60.0];
//    cameraController.delegate = self;
//    [self presentViewController:cameraController animated:YES completion:nil];
}

#pragma mark - CDCameraViewControllerDelegate

- (void)cameraControllerDidClose:(CDCameraViewController *)controller {
    [controller dismissViewControllerAnimated:YES completion:nil];
}

- (void)cameraController:(CDCameraViewController *)controller didSelectVideo:(NSURL *)videoUrl {
    [controller dismissViewControllerAnimated:YES completion:nil];
}

- (void)cameraController:(CDCameraViewController *)controller didSelectPhoto:(UIImage *)image {
    [controller dismissViewControllerAnimated:YES completion:nil];
}

- (void)cameraControllerWasInterrupted:(CDCameraViewController *)controller {
    NSLog(@"cameraControllerWasInterrupted");
}

@end
