//
//  CDVideoViewController.h
//  CircleAnimation
//
//  Created by Carlos Duclos on 5/19/17.
//  Copyright © 2017 Connect Network. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CDVideoViewController;
@protocol CDVideoViewControllerDelegate <NSObject>

- (void)videoController:(CDVideoViewController *)controller didSelectVideo:(NSURL *)videoURL;

@end

@interface CDVideoViewController : UIViewController

@property (nonatomic, strong) NSURL *videoURL;
@property (nonatomic, weak) id<CDVideoViewControllerDelegate> delegate;

@end
