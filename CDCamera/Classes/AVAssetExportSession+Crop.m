//
//  AVAssetExportSession+Crop.m
//  Pods
//
//  Created by Carlos Duclos on 5/30/17.
//
//

#import "AVAssetExportSession+Crop.h"

@implementation AVAssetExportSession (Crop)

+ (void)cropVideoWithURL:(NSURL *)videoURL videoOrientation:(AVCaptureVideoOrientation)videoOrientation completionHandler:(void (^)(NSURL *convertedURL))completionHandler {
    AVAsset* asset = [AVAsset assetWithURL:videoURL];
    
    AVMutableComposition *composition = [AVMutableComposition composition];
    [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    
    AVAssetTrack *videoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    
    // crop clip to screen ratio
    UIInterfaceOrientation orientation = [self orientationForTrack:asset];
    BOOL isPortrait = (videoOrientation == AVCaptureVideoOrientationPortrait || orientation == AVCaptureVideoOrientationPortraitUpsideDown) ? YES: NO;
    CGFloat complimentSize = [self getComplimentSize:videoTrack.naturalSize.height];
    CGSize videoSize;
    NSLog(@"isPortrait: %d", isPortrait);
    if (isPortrait) {
        videoSize = CGSizeMake(videoTrack.naturalSize.height, videoTrack.naturalSize.width);
    } else {
        videoSize = CGSizeMake(complimentSize, videoTrack.naturalSize.height);
    }
    
    NSLog(@"videoSize: %f - %f", videoSize.width, videoSize.height);
    AVMutableVideoComposition* videoComposition = [AVMutableVideoComposition videoComposition];
    videoComposition.renderSize = videoSize;
    videoComposition.frameDuration = CMTimeMake(1, 30);
    
    AVMutableVideoCompositionInstruction *instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    instruction.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(60, 30));
    
    // rotate and position video
    AVMutableVideoCompositionLayerInstruction* transformer = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
    
    CGFloat tx = (videoTrack.naturalSize.width-complimentSize)/2;
    if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationLandscapeRight) {
        // invert translation
        tx *= -1;
    }
    
    // t1: rotate and position video since it may have been cropped to screen ratio
    CGAffineTransform t1 = CGAffineTransformTranslate(videoTrack.preferredTransform, tx, 0);
    // t2/t3: mirror video horizontally
//    CGAffineTransform t2 = CGAffineTransformTranslate(t1, isPortrait?0:videoTrack.naturalSize.width, isPortrait?videoTrack.naturalSize.height:0);
//    CGAffineTransform t3 = CGAffineTransformScale(t2, isPortrait?1:-1, isPortrait?-1:1);
    
    [transformer setTransform:t1 atTime:kCMTimeZero];
    instruction.layerInstructions = [NSArray arrayWithObject: transformer];
    videoComposition.instructions = [NSArray arrayWithObject: instruction];
    
    NSString *outputPath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mp4", [[NSUUID new] UUIDString]]];
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:asset presetName:AVAssetExportPresetHighestQuality] ;
    exporter.videoComposition = videoComposition;
    exporter.outputURL = [NSURL fileURLWithPath:outputPath];
    exporter.outputFileType = AVFileTypeMPEG4;
    
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        completionHandler(exporter.outputURL);
    }];
}

+ (CGFloat)getComplimentSize:(CGFloat)size {
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat ratio = screenRect.size.height / screenRect.size.width;
    
    // we have to adjust the ratio for 16:9 screens
    if (ratio == 1.775) ratio = 1.77777777777778;
    
    return size * ratio;
}

+ (UIInterfaceOrientation)orientationForTrack:(AVAsset *)asset {
    UIInterfaceOrientation orientation = UIInterfaceOrientationPortrait;
    NSArray *tracks = [asset tracksWithMediaType:AVMediaTypeVideo];
    
    if([tracks count] > 0) {
        AVAssetTrack *videoTrack = [tracks objectAtIndex:0];
        CGAffineTransform t = videoTrack.preferredTransform;
        
        // Portrait
        if(t.a == 0 && t.b == 1.0 && t.c == -1.0 && t.d == 0) {
            orientation = UIInterfaceOrientationPortrait;
            NSLog(@"orientation: UIInterfaceOrientationPortrait");
        }
        // PortraitUpsideDown
        if(t.a == 0 && t.b == -1.0 && t.c == 1.0 && t.d == 0) {
            orientation = UIInterfaceOrientationPortraitUpsideDown;
            NSLog(@"orientation: UIInterfaceOrientationPortraitUpsideDown");
        }
        // LandscapeRight
        if(t.a == 1.0 && t.b == 0 && t.c == 0 && t.d == 1.0) {
            orientation = UIInterfaceOrientationLandscapeRight;
            NSLog(@"orientation: UIInterfaceOrientationLandscapeRight");
        }
        // LandscapeLeft
        if(t.a == -1.0 && t.b == 0 && t.c == 0 && t.d == -1.0) {
            orientation = UIInterfaceOrientationLandscapeLeft;
            NSLog(@"orientation: UIInterfaceOrientationLandscapeLeft");
        }
    }
    return orientation;
}

@end
