//
//  UIImage+Crop.m
//  Pods
//
//  Created by Carlos Duclos on 5/30/17.
//
//

#import "UIImage+Crop.h"

@implementation UIImage (Crop)

CGRect CGRectCenteredInRect(CGRect rect, CGRect mainRect)
{
    CGFloat xOffset = CGRectGetMidX(mainRect)-CGRectGetMidX(rect);
    CGFloat yOffset = CGRectGetMidY(mainRect)-CGRectGetMidY(rect);
    return CGRectOffset(rect, xOffset, yOffset);
}

// Calculate the destination scale for filling
CGFloat CGAspectScaleFill(CGSize sourceSize, CGRect destRect)
{
    CGSize destSize = destRect.size;
    CGFloat scaleW = destSize.width / sourceSize.width;
    CGFloat scaleH = destSize.height / sourceSize.height;
    return MAX(scaleW, scaleH);
}


CGRect CGRectAspectFillRect(CGSize sourceSize, CGRect destRect)
{
    CGSize destSize = destRect.size;
    CGFloat destScale = CGAspectScaleFill(sourceSize, destRect);
    CGFloat newWidth = sourceSize.width * destScale;
    CGFloat newHeight = sourceSize.height * destScale;
    CGFloat dWidth = ((destSize.width - newWidth) / 2.0f);
    CGFloat dHeight = ((destSize.height - newHeight) / 2.0f);
    CGRect rect = CGRectMake (dWidth, dHeight, newWidth, newHeight);
    return rect;
}



- (UIImage *) applyAspectFillInRect: (CGRect) bounds
{
    CGRect destRect;
    
    UIGraphicsBeginImageContext(bounds.size);
    CGRect rect = CGRectAspectFillRect(self.size, bounds);
    destRect = CGRectCenteredInRect(rect, bounds);
    
    [self drawInRect: destRect];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
    
}

@end
