//
//  CDVideoViewController.m
//  CircleAnimation
//
//  Created by Carlos Duclos on 5/19/17.
//  Copyright © 2017 Connect Network. All rights reserved.
//

#import "CDVideoViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface CDVideoViewController ()
@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerLayer *playerLayer;
@end

@implementation CDVideoViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupView];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidReachEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:[self.player currentItem]];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.playerLayer.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Actions

- (IBAction)cancelTapped:(id)sender {
    if ([self.delegate respondsToSelector:@selector(videoController:didSelectVideo:)]) {
        [self.delegate videoController:self didSelectVideo:nil];
    }
}

- (IBAction)selectTapped:(id)sender {
    if ([self.delegate respondsToSelector:@selector(videoController:didSelectVideo:)]) {
        [self.delegate videoController:self didSelectVideo:self.videoURL];
    }
}

#pragma mark - Private

- (void)setupView {
    NSOperationQueue *queue = [NSOperationQueue new];
    [queue addOperationWithBlock:^{
        self.player = [[AVPlayer alloc] initWithURL:self.videoURL];
        self.player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
        self.player.muted = YES;
        
        self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
        self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            self.playerLayer.frame = self.view.bounds;
            [self.view.layer insertSublayer:self.playerLayer atIndex:0];
            [self.player play];
        }];
    }];
}

- (void)playerItemDidReachEnd:(NSNotification *)notification {
    AVPlayerItem *playerItem = [notification object];
    [playerItem seekToTime:kCMTimeZero];
}

@end
