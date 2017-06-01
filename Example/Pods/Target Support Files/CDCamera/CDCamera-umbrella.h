#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "CALayer+Utils.h"
#import "UIImage+Crop.h"
#import "CDCameraType.h"
#import "CDCameraViewController.h"
#import "CDPhotoViewController.h"
#import "CDVideoViewController.h"
#import "CDCameraButton.h"
#import "CDCameraPreviewView.h"

FOUNDATION_EXPORT double CDCameraVersionNumber;
FOUNDATION_EXPORT const unsigned char CDCameraVersionString[];

