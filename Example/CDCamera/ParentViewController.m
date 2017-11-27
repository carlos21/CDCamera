//
//  ParentViewController.m
//  CDCamera
//
//  Created by Carlos Duclos on 11/27/17.
//  Copyright © 2017 Connect Network. All rights reserved.
//

#import "ParentViewController.h"

@interface ParentViewController ()

@property (nonatomic, assign) kCDCameraType cameraType;
@property (nonatomic, assign) CGFloat maxDuration;

@end

@implementation ParentViewController

#pragma mark - Lifecycle

- (instancetype)initWithType:(kCDCameraType)cameraType maxDuration:(CGFloat)maxDuration {
    self = [super init];
    if (self) {
        self.cameraType = cameraType;
        self.maxDuration = maxDuration;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    ParentViewController *cameraController = [ParentViewController instanceWithType:self.cameraType maxDuration:self.maxDuration];
    cameraController.delegate = self.delegate;
    
    [cameraController willMoveToParentViewController:self];
    [self addChildViewController:cameraController];
    [self.view addSubview:cameraController.view];
    [cameraController didMoveToParentViewController:self];
}

@end
