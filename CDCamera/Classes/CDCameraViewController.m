//
//  CDCameraViewController.m
//  CircleAnimation
//
//  Created by Carlos Duclos on 5/17/17.
//  Copyright © 2017 Connect Network. All rights reserved.
//

#import "CDCameraViewController.h"
#import "CDVideoViewController.h"
#import "CDPhotoViewController.h"
#import "CDCameraButton.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreGraphics/CoreGraphics.h>

static NSString *kStoryboardName = @"CDCamera";

@interface CDCameraViewController ()<AVCaptureFileOutputRecordingDelegate, CDCameraButtonDelegate, CDVideoViewControllerDelegate, CDPhotoViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UIView *previewView;
@property (weak, nonatomic) IBOutlet CDCameraButton *cameraButton;
@property (weak, nonatomic) IBOutlet UIButton *toggleButton;
@property (weak, nonatomic) IBOutlet UIButton *flashButton;
@property (weak, nonatomic) IBOutlet UIButton *closeButton;

@property (weak, nonatomic) IBOutlet UILabel *instructionsLabel;

@property (assign, nonatomic, readonly) AVCaptureVideoOrientation previewLayerOrientation;
@property (assign, nonatomic, readonly) AVCaptureVideoOrientation videoOrientation;
@property (assign, nonatomic, readonly) UIImageOrientation imageOrientation;
@property (assign, nonatomic) UIDeviceOrientation deviceOrientation;

@property (strong, nonatomic) AVCaptureVideoPreviewLayer *previewLayer;
@property (strong, nonatomic) AVCaptureSession *session;
@property (strong, nonatomic) AVCaptureDevice *videoDevice;
@property (strong, nonatomic) AVCaptureDeviceInput *videoInputDevice;
@property (strong, nonatomic) AVCaptureMovieFileOutput *movieFileOutput;
@property (strong, nonatomic) AVCaptureStillImageOutput *photoFileOutput;

@property (strong, nonatomic) dispatch_queue_t sessionQueue;

@property (assign, nonatomic) BOOL useFrontCamera;
@property (assign, nonatomic) BOOL useFlash;

@property (nonatomic, assign) NSUInteger maxDuration;
@property (nonatomic, assign) kCDCameraType type;

@end

@implementation CDCameraViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceDidRotate:) name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (!self.previewLayer) {
        [self setupView];
        [self setupSession];
        [self setupCameraButton];
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.previewLayer.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
}

- (void)dealloc {
    NSLog(@"CDCameraViewController - dealloc");
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Custom Accesors

- (AVCaptureSession *)session {
    if (!_session) {
        _session = [AVCaptureSession new];
        _session.sessionPreset = AVCaptureSessionPresetHigh;
    }
    return _session;
}

- (void)setUseFlash:(BOOL)useFlash {
    _useFlash = useFlash;
    NSString *imageName = _useFlash ? @"flash" : @"flashOutline";
    NSBundle *bundle = [NSBundle bundleForClass:[CDCameraViewController class]];
    UIImage *image = [UIImage imageNamed:imageName inBundle:bundle compatibleWithTraitCollection:nil];
    [self.toggleButton setImage:image forState:UIControlStateNormal];
}

#pragma mark - Actions

- (IBAction)closeTapped:(id)sender {
    if ([self.delegate respondsToSelector:@selector(cameraControllerDidClose:)]) {
        [self.delegate cameraControllerDidClose:self];
    }
}

- (IBAction)toggleCameraTapped:(id)sender {
    self.useFrontCamera = !self.useFrontCamera;
    [self.session stopRunning];
    
    dispatch_async(self.sessionQueue, ^{
        for (AVCaptureInput *input in self.session.inputs) {
            [self.session removeInput:input];
        }
        
        [self addInputs];
        [self.session startRunning];
    });
}

- (IBAction)toggleFlashTapped:(id)sender {
    self.useFlash = !self.useFlash;
}

//- (IBAction)toggleFlashTapped:(id)sender {
//    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
//    if (device.hasTorch) {
//        NSError *error = nil;
//        [device lockForConfiguration:&error];
//        
//        if (!error) {
//            if (device.torchMode == AVCaptureTorchModeOn) {
//                device.torchMode = AVCaptureTorchModeOff;
//                self.useFlash = NO;
//            } else {
//                [device setTorchModeOnWithLevel:1.0 error:&error];
//                
//                if (!error) {
//                    self.useFlash = YES;
//                } else {
//                    NSLog(@"Error: %@", error.localizedDescription);
//                }
//            }
//            [device unlockForConfiguration];
//        } else {
//            NSLog(@"Error: %@", error.localizedDescription);
//        }
//    }
//}

#pragma mark - Private

- (void)setupView {
    self.previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
    self.previewLayer.frame = self.previewView.frame;
    [self.previewView.layer insertSublayer:self.previewLayer atIndex:0];
    
    NSBundle *bundle = [NSBundle bundleForClass:[CDCameraViewController class]];
    switch (self.type) {
        case kCDCameraTypePhoto:
            self.instructionsLabel.text = NSLocalizedStringFromTableInBundle(@"camera_instructions_tap", nil, bundle, @"");
            break;
        case kCDCameraTypeVideo:
            self.instructionsLabel.text = NSLocalizedStringFromTableInBundle(@"camera_instructions_press_and_hold", nil, bundle, @"");
            break;
    }
}

- (void)setupSession {
    self.sessionQueue = dispatch_queue_create("com.carlosduclos.videotest", DISPATCH_QUEUE_CONCURRENT);
    
    dispatch_async(self.sessionQueue, ^{
        [self configureSession];
        [self.session startRunning];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.previewLayer.connection.videoOrientation = self.previewLayerOrientation;
        });
    });
}

- (void)setupCameraButton {
    self.cameraButton.delegate = self;
    self.cameraButton.maxDuration = self.maxDuration;
    self.cameraButton.type = self.type;
}

- (void)deviceDidRotate:(NSNotification *)notification {
    if ([UIDevice currentDevice].orientation != UIDeviceOrientationFaceUp && [UIDevice currentDevice].orientation != UIDeviceOrientationFaceDown) {
        self.deviceOrientation = [UIDevice currentDevice].orientation;
    }
}

- (AVCaptureDevice *)deviceWithMediaType:(NSString *)mediaType withPosition:(AVCaptureDevicePosition)position {
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:mediaType];
    for (AVCaptureDevice *device in devices) {
        if (device.position == position) {
            return device;
        }
    }
    return nil;
}

- (AVCaptureVideoOrientation)previewLayerOrientation {
    switch ([[UIApplication sharedApplication] statusBarOrientation]) {
        case UIInterfaceOrientationLandscapeLeft:
            return AVCaptureVideoOrientationLandscapeLeft;
        case UIInterfaceOrientationLandscapeRight:
            return AVCaptureVideoOrientationLandscapeRight;
        case UIInterfaceOrientationPortraitUpsideDown:
            return AVCaptureVideoOrientationPortraitUpsideDown;
        default:
            return AVCaptureVideoOrientationPortrait;
    }
}

- (AVCaptureVideoOrientation)videoOrientation {
    if (!self.deviceOrientation) {
        return self.previewLayer.connection.videoOrientation;
    }
    
    switch (self.deviceOrientation) {
        case UIDeviceOrientationLandscapeLeft:
            return AVCaptureVideoOrientationLandscapeRight;
        case UIDeviceOrientationLandscapeRight:
            return AVCaptureVideoOrientationLandscapeLeft;
        case UIDeviceOrientationPortraitUpsideDown:
            return AVCaptureVideoOrientationPortraitUpsideDown;
        default:
            return AVCaptureVideoOrientationPortrait;
    }
}

- (UIImageOrientation)imageOrientation {
    switch (self.deviceOrientation) {
        case UIDeviceOrientationLandscapeLeft:
            return !self.useFrontCamera ? UIImageOrientationUp : UIImageOrientationDownMirrored;
        case UIDeviceOrientationLandscapeRight:
            return !self.useFrontCamera ? UIImageOrientationDown : UIImageOrientationUpMirrored;
        case UIDeviceOrientationPortraitUpsideDown:
            return !self.useFrontCamera ? UIImageOrientationLeft : UIImageOrientationRightMirrored;
        default:
            return !self.useFrontCamera ? UIImageOrientationRight : UIImageOrientationLeftMirrored;
    }
}

- (void)configureSession {
    [self.session beginConfiguration];
    [self.session setSessionPreset:AVCaptureSessionPresetHigh];
    [self addVideoInput];
    [self addAudioInput];
    
    switch (self.type) {
        case kCDCameraTypePhoto:
            [self addPhotoOutput];
            break;
        case kCDCameraTypeVideo:
            [self addVideoOutput];
            break;
    }
    
    [self.session commitConfiguration];
}

- (void)addInputs {
    [self.session beginConfiguration];
    [self.session setSessionPreset:AVCaptureSessionPresetHigh];
    [self addVideoInput];
    [self addAudioInput];
    [self.session commitConfiguration];
}

- (void)addAudioInput {
    NSError *error = nil;
    AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    AVCaptureDeviceInput *audioDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:&error];
    
    if ([self.session canAddInput:audioDeviceInput]) {
        [self.session addInput:audioDeviceInput];
    }
}

- (void)addVideoInput {
    AVCaptureDevicePosition position = self.useFrontCamera ? AVCaptureDevicePositionFront: AVCaptureDevicePositionBack;
    AVCaptureDevice *device = [self deviceWithMediaType:(NSString *)AVMediaTypeVideo withPosition:position];
    
    NSError *error = nil;
    if (![device lockForConfiguration:&error]) {
        NSLog(@"addVideoInput - error: %@", error.localizedDescription);
        return;
    }
    
    if ([device isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
        device.focusMode = AVCaptureFocusModeContinuousAutoFocus;
        if (device.isSmoothAutoFocusSupported) {
            [device setSmoothAutoFocusEnabled:YES];
        }
    }
    
    if ([device isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]) {
        device.exposureMode = AVCaptureExposureModeContinuousAutoExposure;
    }
    
    if ([device isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance]) {
        device.whiteBalanceMode = AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance;
    }
    
    if (device.isLowLightBoostSupported) {
        device.automaticallyEnablesLowLightBoostWhenAvailable = YES;
    }
    
    [device unlockForConfiguration];
    self.videoDevice = device;
    
    AVCaptureDeviceInput *inputDevice = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    if ([self.session canAddInput:inputDevice]) {
        [self.session addInput:inputDevice];
        self.videoInputDevice = inputDevice;
    }
}

- (void)addVideoOutput {
    AVCaptureMovieFileOutput *movieFileOutput = [AVCaptureMovieFileOutput new];
    if ([self.session canAddOutput:movieFileOutput]) {
        [self.session addOutput:movieFileOutput];
        
        AVCaptureConnection *connection = [movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
        if (connection.isVideoStabilizationSupported) {
            connection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
        }
        self.movieFileOutput = movieFileOutput;
    }
}

- (void)addPhotoOutput {
    AVCaptureStillImageOutput *photoFileOutput = [AVCaptureStillImageOutput new];
    if ([self.session canAddOutput:photoFileOutput]) {
        photoFileOutput.outputSettings = @{AVVideoCodecKey: AVVideoCodecJPEG};
        [self.session addOutput:photoFileOutput];
        self.photoFileOutput = photoFileOutput;
    }
}

- (void)changeFlashSettings:(AVCaptureDevice *)device withMode:(AVCaptureFlashMode)mode {
    NSError *error = nil;
    [device lockForConfiguration:&error];
    device.flashMode = mode;
    [device unlockForConfiguration];
    
    if (error) {
        NSLog(@"error: %@", error.localizedDescription);
    }
}

- (UIImage *)processPhotoWithData:(NSData *)data {
    CFDataRef cfData = CFDataCreate(NULL, [data bytes], [data length]);
    struct CGDataProvider *dataProvider = CGDataProviderCreateWithCFData(cfData);
    struct CGImage *cgImage = CGImageCreateWithJPEGDataProvider(dataProvider, nil, YES, kCGRenderingIntentDefault);
    UIImage *image = [UIImage imageWithCGImage:cgImage scale:1.0 orientation:self.imageOrientation];
    return image;
}

- (void)showPhotoController:(UIImage *)image {
    CDPhotoViewController *photoController = [self.storyboard instantiateViewControllerWithIdentifier:NSStringFromClass([CDPhotoViewController class])];
    photoController.delegate = self;
    photoController.image = image;
    
    [photoController willMoveToParentViewController:self];
    [self addChildViewController:photoController];
    [self.view addSubview:photoController.view];
    [photoController didMoveToParentViewController:self];
}

- (void)showVideoController:(NSURL *)videoURL {
    CDVideoViewController *videoController = [self.storyboard instantiateViewControllerWithIdentifier:NSStringFromClass([CDVideoViewController class])];
    videoController.delegate = self;
    videoController.videoURL = videoURL;
    
    [videoController willMoveToParentViewController:self];
    [self addChildViewController:videoController];
    [self.view addSubview:videoController.view];
    [videoController didMoveToParentViewController:self];
}

- (void)showUIElements:(BOOL)flag {
    CGFloat newAlpha = flag ? 1.0 : 0.0;
    [UIView animateWithDuration:0.2 animations:^{
        self.closeButton.alpha = newAlpha;
        self.instructionsLabel.alpha = newAlpha;
        self.flashButton.alpha = newAlpha;
        self.toggleButton.alpha = newAlpha;
    }];
}

- (void)capturePhotoAsynchronouslyWithCompletion:(void(^)(BOOL success))completionHandler {
    AVCaptureConnection *connection = [self.photoFileOutput connectionWithMediaType:AVMediaTypeVideo];
    [self.photoFileOutput captureStillImageAsynchronouslyFromConnection:connection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
        if (!imageDataSampleBuffer) {
            if (completionHandler) {
                completionHandler(NO);
            }
            return;
        }
        
        NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
        UIImage *image = [self processPhotoWithData:imageData];
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self showPhotoController:image];
        }];
        
        if (completionHandler) {
            completionHandler(YES);
        }
    }];
}

- (void)startRecording {
    dispatch_async(self.sessionQueue, ^{
        if (self.movieFileOutput.isRecording) {
            [self.movieFileOutput stopRecording];
            return;
        }
        
        AVCaptureConnection *movieFileOutputConnection = [self.movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
        if (self.useFrontCamera) {
            [movieFileOutputConnection setVideoMirrored:YES];
        }
        movieFileOutputConnection.videoOrientation = self.videoOrientation;
        
        NSString *outputFilename = [[NSUUID UUID] UUIDString];
        NSString *outputFilePath = [[NSTemporaryDirectory() stringByAppendingPathComponent:outputFilename] stringByAppendingPathExtension:@"mov"];
        NSURL *outputURL = [NSURL fileURLWithPath:outputFilePath];
        [self.movieFileOutput startRecordingToOutputFileURL:outputURL recordingDelegate:self];
    });
}

- (void)stopRecording {
    if (!self.movieFileOutput.isRecording) {
        return;
    }
    
    [self.movieFileOutput stopRecording];
}

- (void)takePhoto {
    if (!self.videoDevice) {
        return;
    }
    
    if (!self.videoDevice.hasFlash && self.useFlash && self.useFrontCamera) {
        UIView *flashView = [[UIView alloc] initWithFrame:self.view.frame];
        flashView.alpha = 0.0;
        flashView.backgroundColor = [UIColor whiteColor];
        [self.view addSubview:flashView];
        
        CGFloat previousBrightness = [[UIScreen mainScreen] brightness];
        [[UIScreen mainScreen] setBrightness:1.0];
        
        [UIView animateWithDuration:0.1 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            flashView.alpha = 1.0;
        } completion:^(BOOL finished) {
            [self capturePhotoAsynchronouslyWithCompletion:^(BOOL success){
                [UIView animateWithDuration:0.1 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                    flashView.alpha = 0.0;
                } completion:^(BOOL finished) {
                    [flashView removeFromSuperview];
                    [[UIScreen mainScreen] setBrightness:previousBrightness];
                }];
            }];
        }];
        
        return;
    }
    
    if (self.videoDevice.hasFlash && self.useFlash) {
        [self changeFlashSettings:self.videoDevice withMode:AVCaptureFlashModeOn];
        [self capturePhotoAsynchronouslyWithCompletion:nil];
        return;
    }
    
    if (self.videoDevice.isFlashActive) {
        [self changeFlashSettings:self.videoDevice withMode:AVCaptureFlashModeOff];
    }
    
    [self capturePhotoAsynchronouslyWithCompletion:nil];
}

#pragma mark - Public

+ (instancetype)instanceWithType:(kCDCameraType)type maxDuration:(CGFloat)maxDuration {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:kStoryboardName bundle:[NSBundle bundleForClass:[CDCameraViewController class]]];
    CDCameraViewController *cameraController = [storyboard instantiateViewControllerWithIdentifier:NSStringFromClass([CDCameraViewController class])];
    cameraController.type = type;
    cameraController.maxDuration = maxDuration;
    return cameraController;
}

#pragma mark - AVCaptureFileOutputRecordingDelegate

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections {
    
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self showVideoController:outputFileURL];
    }];
}

#pragma mark - CDCameraButtonDelegate

- (void)cameraButtonDidReachMaximumDuration {
    [self stopRecording];
}

- (void)cameraButtonDidBeginLongPress {
    [self startRecording];
    [self showUIElements:NO];
}

- (void)cameraButtonDidEndLongPress {
    [self stopRecording];
}

- (void)cameraButtonDidTap {
    [self takePhoto];
    [self showUIElements:NO];
}

#pragma mark - CDVideoViewControllerDelegate

- (void)videoController:(CDVideoViewController *)controller didSelectVideo:(NSURL *)videoURL {
    [controller removeFromParentViewController];
    [controller.view removeFromSuperview];
    [self.cameraButton reset];
    [self showUIElements:YES];
    
    if (videoURL) {
        [self.delegate cameraController:self didSelectVideo:videoURL];
    }
}

#pragma mark - CDPhotoViewControllerDelegate

- (void)photoController:(CDPhotoViewController *)controller didSelectPhoto:(UIImage *)image {
    [controller removeFromParentViewController];
    [controller.view removeFromSuperview];
    [self.cameraButton reset];
    [self showUIElements:YES];
    
    if (image) {
         [self.delegate cameraController:self didSelectPhoto:image];
    }
}

@end
