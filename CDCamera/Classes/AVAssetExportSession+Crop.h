//
//  AVAssetExportSession+Crop.h
//  Pods
//
//  Created by Carlos Duclos on 5/30/17.
//
//

#import <AVFoundation/AVFoundation.h>

@interface AVAssetExportSession (Crop)

+ (void)cropVideoWithURL:(NSURL *)videoURL videoOrientation:(AVCaptureVideoOrientation)videoOrientation completionHandler:(void (^)(NSURL *convertedURL))completionHandler;

@end
