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

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSLog(@"CDPhotoViewController - viewWillAppear");
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    NSLog(@"CDPhotoViewController - viewWillDisappear");
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupView];
}

- (void)dealloc {
    NSLog(@"CDPhotoViewController - dealloc");
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
