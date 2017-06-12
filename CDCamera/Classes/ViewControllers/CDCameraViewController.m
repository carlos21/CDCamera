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
#import "CDCameraPreviewView.h"
#import "UIImage+Crop.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import "CDCameraCounterView.h"

static NSString *kStoryboardName = @"CDCamera";

@interface CDCameraViewController ()<AVCaptureFileOutputRecordingDelegate, CDCameraButtonDelegate, CDVideoViewControllerDelegate, CDPhotoViewControllerDelegate>

@property (weak, nonatomic) IBOutlet CDCameraButton *cameraButton;
@property (weak, nonatomic) IBOutlet UIButton *toggleCameraButton;
@property (weak, nonatomic) IBOutlet UIButton *toggleFlashButton;
@property (weak, nonatomic) IBOutlet UIButton *closeButton;
@property (weak, nonatomic) IBOutlet UILabel *instructionsLabel;
@property (weak, nonatomic) IBOutlet CDCameraPreviewView *previewView;
@property (weak, nonatomic) IBOutlet CDCameraCounterView *counterView;

@property (assign, nonatomic, readonly) AVCaptureVideoOrientation videoOrientation;
@property (assign, nonatomic, readonly) UIImageOrientation imageOrientation;
@property (assign, nonatomic) UIDeviceOrientation deviceOrientation;

@property (strong, nonatomic) AVCaptureSession *session;
@property (strong, nonatomic) AVCaptureDevice *videoDevice;
@property (strong, nonatomic) AVCaptureDeviceInput *videoInputDevice;
@property (strong, nonatomic) AVCaptureMovieFileOutput *movieFileOutput;
@property (strong, nonatomic) AVCaptureStillImageOutput *photoFileOutput;

@property (strong, nonatomic) dispatch_queue_t sessionQueue;

@property (assign, nonatomic) BOOL useFrontCamera;
@property (assign, nonatomic) BOOL useFlash;
@property (assign, nonatomic) BOOL statusBarWasHidden;

@property (nonatomic, assign) NSUInteger maxDuration;
@property (nonatomic, assign) kCDCameraType type;

@property (nonatomic, assign) CGFloat zoomScale;

@end

@implementation CDCameraViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.statusBarWasHidden = [UIApplication sharedApplication].isStatusBarHidden;
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self setupView];
    [self setupSession];
    [self setupCameraButton];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
    if (UIDeviceOrientationIsPortrait(deviceOrientation) || UIDeviceOrientationIsLandscape(deviceOrientation)) {
        self.previewView.videoPreviewLayer.connection.videoOrientation = (AVCaptureVideoOrientation)deviceOrientation;
    }
    
    [self stopRecording];
}

- (void)dealloc {
    [[UIApplication sharedApplication] setStatusBarHidden:self.statusBarWasHidden];
}

#pragma mark - Custom Accesors

- (AVCaptureSession *)session {
    if (!_session) {
        _session = [AVCaptureSession new];
        _session.sessionPreset = AVCaptureSessionPresetPhoto;
    }
    return _session;
}

- (void)setUseFlash:(BOOL)useFlash {
    _useFlash = useFlash;
    NSString *imageName = _useFlash ? @"flash" : @"flashOutline";
    NSBundle *bundle = [NSBundle bundleForClass:[CDCameraViewController class]];
    UIImage *image = [UIImage imageNamed:imageName inBundle:bundle compatibleWithTraitCollection:nil];
    [self.toggleFlashButton setImage:image forState:UIControlStateNormal];
}

#pragma mark - Override

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

#pragma mark - Actions

- (IBAction)closeTapped:(id)sender {
    if ([self.delegate respondsToSelector:@selector(cameraControllerDidClose:)]) {
        [self.delegate cameraControllerDidClose:self];
    }
}

- (IBAction)toggleCameraTapped:(id)sender {
    self.useFrontCamera = !self.useFrontCamera;
    self.toggleFlashButton.enabled = !(self.type == kCDCameraTypeVideo && self.useFrontCamera);
    
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

- (void)zoomGestureEvent:(UIPinchGestureRecognizer *)gesture {
    if (self.useFrontCamera || !self.videoDevice) {
        return;
    }
    
    NSError *error = nil;
    [self.videoDevice lockForConfiguration:&error];
    
    switch (gesture.state) {
        case UIGestureRecognizerStateBegan:
            self.zoomScale = self.videoDevice.videoZoomFactor;
            break;
        case UIGestureRecognizerStateChanged: {
            CGFloat factor = self.zoomScale * gesture.scale;
            factor = MAX(1.0, MIN(factor, self.videoDevice.activeFormat.videoMaxZoomFactor));
            self.videoDevice.videoZoomFactor = factor;
            break;
        }
        default:
            break;
    }
    
    [self.videoDevice unlockForConfiguration];
}

#pragma mark - Private

- (UIDeviceOrientation)deviceOrientation {
    UIInterfaceOrientation statusBarOrientation = [UIApplication sharedApplication].statusBarOrientation;
    if (statusBarOrientation == UIInterfaceOrientationLandscapeRight) {
        return UIDeviceOrientationLandscapeLeft;
    } else if (statusBarOrientation == UIInterfaceOrientationLandscapeLeft) {
        return UIDeviceOrientationLandscapeRight;
    } else if (statusBarOrientation == UIInterfaceOrientationPortraitUpsideDown) {
        return UIDeviceOrientationPortraitUpsideDown;
    } else {
        return UIDeviceOrientationPortrait;
    }
    
}

- (void)setupView {
    NSBundle *bundle = [NSBundle bundleForClass:[CDCameraViewController class]];
    UIImage *imageDisabled = [UIImage imageNamed:@"flashOutlineDisabled" inBundle:bundle compatibleWithTraitCollection:nil];
    [self.toggleFlashButton setImage:imageDisabled forState:UIControlStateDisabled];
    self.view.backgroundColor = [UIColor redColor];
    
    self.previewView.session = self.session;
    self.previewView.videoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    
    self.counterView.alpha = 0.0;
    self.zoomScale = 1.0;
    
    if ([UIDevice currentDevice].orientation != UIDeviceOrientationFaceUp && [UIDevice currentDevice].orientation != UIDeviceOrientationFaceDown) {
        self.deviceOrientation = [UIDevice currentDevice].orientation;
    }
    
    NSArray *languages = @[@"en", @"es"];
    NSString *lang = [[NSLocale currentLocale] objectForKey: NSLocaleLanguageCode];
    if (![languages containsObject:lang]) {
        lang = @"en";
    }
    
    NSString *table = [NSString stringWithFormat:@"CDCamera_%@", lang];
    switch (self.type) {
        case kCDCameraTypePhoto:
            self.instructionsLabel.text = NSLocalizedStringFromTableInBundle(@"camera_instructions_tap", table, bundle, @"");
            break;
        case kCDCameraTypeVideo:
            self.instructionsLabel.text = NSLocalizedStringFromTableInBundle(@"camera_instructions_press_and_hold", table, bundle, @"");
            break;
    }
    
    UIPinchGestureRecognizer *zoomGesture = [UIPinchGestureRecognizer new];
    [zoomGesture addTarget:self action:@selector(zoomGestureEvent:)];
    [self.view addGestureRecognizer:zoomGesture];
}

- (void)setupSession {
    self.sessionQueue = dispatch_queue_create("com.carlosduclos.videotest", DISPATCH_QUEUE_CONCURRENT);
    
    dispatch_async(self.sessionQueue, ^{
        [self configureSession];
        [self.session startRunning];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            UIInterfaceOrientation statusBarOrientation = [UIApplication sharedApplication].statusBarOrientation;
            AVCaptureVideoOrientation initialVideoOrientation = AVCaptureVideoOrientationPortrait;
            if ( statusBarOrientation != UIInterfaceOrientationUnknown ) {
                initialVideoOrientation = (AVCaptureVideoOrientation)statusBarOrientation;
            }
            
            self.previewView.videoPreviewLayer.connection.videoOrientation = initialVideoOrientation;
        });
    });
}

- (void)setupCameraButton {
    self.cameraButton.delegate = self;
    self.cameraButton.maxDuration = self.maxDuration;
    self.cameraButton.type = self.type;
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

- (AVCaptureVideoOrientation)videoOrientation {
    if (!self.deviceOrientation) {
        return self.previewView.videoPreviewLayer.connection.videoOrientation;
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
        self.toggleCameraButton.alpha = newAlpha;
        self.toggleFlashButton.alpha = newAlpha;
        
        if (!flag && self.type == kCDCameraTypeVideo) {
            self.counterView.alpha = 0.65;
        }
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
        image = [image applyAspectFillInRect:self.previewView.frame];
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self showPhotoController:image];
        }];
        
        if (completionHandler) {
            completionHandler(YES);
        }
    }];
}

- (void)enableFlash:(BOOL)flag {
    if (self.useFrontCamera || !self.videoDevice) {
        return;
    }
    
    if (self.videoDevice.hasTorch) {
        NSError *error = nil;
        [self.videoDevice lockForConfiguration:&error];
        
        if (flag) {
            self.videoDevice.torchMode = AVCaptureTorchModeOn;
            [self.videoDevice setTorchModeOnWithLevel:1.0 error:&error];
        } else {
            self.videoDevice.torchMode = AVCaptureTorchModeOff;
        }
        
        [self.videoDevice unlockForConfiguration];
    }
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
        
        [self enableFlash:self.useFlash];
    });
}

- (void)stopRecording {
    dispatch_async(self.sessionQueue, ^{
        if (!self.movieFileOutput.isRecording) {
            return;
        }
        [self.movieFileOutput stopRecording];
    });
    
    self.counterView.alpha = 0.0;
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
    [self enableFlash:NO];
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
    [self.counterView startCounterWithSeconds:self.maxDuration];
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
