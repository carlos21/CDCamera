//
//  CDCameraPreviewView.m
//  Pods
//
//  Created by Carlos Duclos on 5/29/17.
//
//

#import "CDCameraPreviewView.h"

@implementation CDCameraPreviewView

+ (Class)layerClass {
    return [AVCaptureVideoPreviewLayer class];
}

- (AVCaptureVideoPreviewLayer *)videoPreviewLayer {
    return (AVCaptureVideoPreviewLayer *)self.layer;
}

- (AVCaptureSession *)session {
    return self.videoPreviewLayer.session;
}

- (void)setSession:(AVCaptureSession *)session {
    self.videoPreviewLayer.session = session;
}

@end
