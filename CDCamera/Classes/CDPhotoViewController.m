//
//  CDPhotoViewController.m
//  CircleAnimation
//
//  Created by Carlos Duclos on 5/22/17.
//  Copyright © 2017 Connect Network. All rights reserved.
//

#import "CDPhotoViewController.h"

@interface CDPhotoViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *photoView;
@end

@implementation CDPhotoViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupView];
}

#pragma mark - Actions

- (IBAction)cancelTapped:(id)sender {
    if ([self.delegate respondsToSelector:@selector(photoController:didSelectPhoto:)]) {
        [self.delegate photoController:self didSelectPhoto:nil];
    }
}

- (IBAction)selectTapped:(id)sender {
    if ([self.delegate respondsToSelector:@selector(photoController:didSelectPhoto:)]) {
        [self.delegate photoController:self didSelectPhoto:self.image];
    }
}

#pragma mark - Private

- (void)setupView {
    self.photoView.contentMode = UIViewContentModeScaleAspectFill;
    self.photoView.image = self.image;
}

@end
