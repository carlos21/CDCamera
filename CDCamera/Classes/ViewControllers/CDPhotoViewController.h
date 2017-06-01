//
//  CDPhotoViewController.h
//  CircleAnimation
//
//  Created by Carlos Duclos on 5/22/17.
//  Copyright © 2017 Connect Network. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CDPhotoViewController;
@protocol CDPhotoViewControllerDelegate <NSObject>

- (void)photoController:(CDPhotoViewController *)controller didSelectPhoto:(UIImage *)image;

@end

@interface CDPhotoViewController : UIViewController

@property (nonatomic, strong) UIImage *image;
@property (nonatomic, weak) id<CDPhotoViewControllerDelegate> delegate;

@end
