//
//  CDCameraButton.m
//  CircleAnimation
//
//  Created by Carlos Duclos on 5/17/17.
//  Copyright © 2017 Connect Network. All rights reserved.
//

#import "CDCameraButton.h"
#import "CDCameraViewController.h"
#import "CALayer+Utils.h"

@interface CDCameraButton()
@property (nonatomic, strong) CAShapeLayer *containerLayer;
@property (nonatomic, strong) CAShapeLayer *circleLayer;
@property (nonatomic, strong) CAShapeLayer *borderLayer;
@property (nonatomic, strong) CAShapeLayer *borderFillLayer;
@property (nonatomic, assign) CGFloat circleRadius;
@property (nonatomic, assign, readonly) CGRect circleFrame;
@property (nonatomic, strong, readonly) UIBezierPath *circlePath;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, assign) double timeElapsed;
@end

@implementation CDCameraButton

#pragma mark - Lifecycle

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self setupView];
        [self setupGestures];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setupView];
        [self setupGestures];
    }
    return self;
}

#pragma mark - Custom Accesors

- (CGRect)circleFrame {
    CGRect frame = CGRectMake(0, 0, 2*self.circleRadius, 2*self.circleRadius);
    frame.origin.x = CGRectGetMidX(self.borderLayer.bounds) - CGRectGetMidX(frame);
    frame.origin.y = CGRectGetMidY(self.borderLayer.bounds) - CGRectGetMidY(frame);
    return frame;
}

- (UIBezierPath *)circlePath {
    CGFloat startAngle = M_PI + M_PI_2;
    CGFloat endAngle = M_PI * 3 + M_PI_2;
    CGPoint centerPoint = CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2);
    return [UIBezierPath bezierPathWithArcCenter:centerPoint radius:self.frame.size.width / 2 - 2 startAngle:startAngle endAngle:endAngle clockwise:YES];
}

- (CAShapeLayer *)containerLayer {
    if (!_containerLayer) {
        _containerLayer = [CAShapeLayer layer];
        _containerLayer.frame = self.bounds;
        _containerLayer.lineWidth = 7;
        _containerLayer.fillColor = [UIColor clearColor].CGColor;
        _containerLayer.strokeColor = [UIColor whiteColor].CGColor;
    }
    return _containerLayer;
}

- (CAShapeLayer *)borderLayer {
    if (!_borderLayer) {
        _borderLayer = [CAShapeLayer layer];
        _borderLayer.frame = self.bounds;
        _borderLayer.lineWidth = 4;
        _borderLayer.fillColor = [UIColor clearColor].CGColor;
        _borderLayer.strokeColor = [UIColor whiteColor].CGColor;
    }
    return _borderLayer;
}

- (CAShapeLayer *)borderFillLayer {
    if (!_borderFillLayer) {
        _borderFillLayer = [CAShapeLayer layer];
        _borderFillLayer.frame = self.bounds;
        _borderFillLayer.lineWidth = 4;
        _borderFillLayer.fillColor = [UIColor clearColor].CGColor;
        _borderFillLayer.strokeColor = [UIColor redColor].CGColor;
        _borderFillLayer.strokeEnd = 0.0;
    }
    return _borderFillLayer;
}

- (CAShapeLayer *)circleLayer {
    if (!_circleLayer) {
        CGFloat width = 1.0f; //self.circleRadius * 2 * 0.76;
        CGFloat height = width;
        _circleLayer = [CAShapeLayer layer];
        _circleLayer.path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, width, height) cornerRadius:0.5].CGPath;
        _circleLayer.anchorPoint = CGPointMake(0.5, 0.5);
        _circleLayer.frame = CGRectMake(0, 0, width, height);
        _circleLayer.position = CGPointMake(self.frame.size.width * 0.5, self.frame.size.height * 0.5);
        _circleLayer.fillColor = [UIColor redColor].CGColor;
    }
    return _circleLayer;
}

- (void)setDelegate:(id<CDCameraButtonDelegate>)delegate {
    _delegate = delegate;
}

#pragma mark - Override

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.borderLayer.frame = self.bounds;
    self.borderLayer.path = self.circlePath.CGPath;
    self.borderFillLayer.frame = self.bounds;
    self.borderFillLayer.path = self.circlePath.CGPath;
}

#pragma mark - Actions

- (void)longPressEvent:(UILongPressGestureRecognizer *)gesture {
    if (self.type == kCDCameraTypePhoto) {
        return;
    }
    
    if (gesture.state == UIGestureRecognizerStateBegan) {
        [self startTimer];
        [self startRecordingAnimation];
        if ([self.delegate respondsToSelector:@selector(cameraButtonDidBeginLongPress)]) {
            [self.delegate cameraButtonDidBeginLongPress];
        }
    } else if (gesture.state == UIGestureRecognizerStateEnded) {
        [self timerFinishedEvent];
        [self endRecordingAnimation];
        if ([self.delegate respondsToSelector:@selector(cameraButtonDidEndLongPress)]) {
            [self.delegate cameraButtonDidEndLongPress];
        }
    }
}

- (void)tapEvent:(UITapGestureRecognizer *)gesture {
    if (self.type == kCDCameraTypeVideo) {
        return;
    }
    
    if ([self.delegate respondsToSelector:@selector(cameraButtonDidTap)]) {
        [self.delegate cameraButtonDidTap];
    }
}

#pragma mark - Private

- (void)setupView {
    self.circleRadius = self.bounds.size.width * 0.5;
    self.backgroundColor = [UIColor clearColor];
    
    [self.containerLayer insertSublayer:self.borderLayer atIndex:0];
    [self.containerLayer insertSublayer:self.borderFillLayer above:self.borderLayer];
    
    [self.layer insertSublayer:self.containerLayer atIndex:0];
    [self.layer insertSublayer:self.circleLayer above:self.containerLayer];
}

- (void)setupGestures {
    UILongPressGestureRecognizer *longGesture = [UILongPressGestureRecognizer new];
    [longGesture addTarget:self action:@selector(longPressEvent:)];
    [self addGestureRecognizer:longGesture];
    
    UITapGestureRecognizer *tapGesture = [UITapGestureRecognizer new];
    [tapGesture addTarget:self action:@selector(tapEvent:)];
    [self addGestureRecognizer:tapGesture];
}

- (void)startTimer {
    self.timer = [NSTimer scheduledTimerWithTimeInterval:self.maxDuration target:self selector:@selector(timerFinishedEvent) userInfo:nil repeats:NO];
    self.timeElapsed = 0;
}

- (void)timerFinishedEvent {
    [self invalidateTimer];
    [self endRecordingAnimation];
    if ([self.delegate respondsToSelector:@selector(cameraButtonDidReachMaximumDuration)]) {
        [self.delegate cameraButtonDidReachMaximumDuration];
    }
}

- (void)invalidateTimer {
    [self.timer invalidate];
    self.timer = nil;
}

- (void)startRecordingAnimation {
    CABasicAnimation *scaleContainerAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    scaleContainerAnimation.fromValue = @(1.0);
    scaleContainerAnimation.toValue = @(1.37);
    scaleContainerAnimation.duration = 1.4f;
    scaleContainerAnimation.removedOnCompletion = NO;
    scaleContainerAnimation.fillMode = kCAFillModeForwards;
    scaleContainerAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [self.containerLayer addAnimation:scaleContainerAnimation forKey:@"scaleParentAnimation"];
    
    CGRect newCircleBounds = CGRectMake(0, 0, 2 * self.circleRadius * 0.82, 2 * self.circleRadius * 0.82);
    UIBezierPath *newPath = [UIBezierPath bezierPathWithRoundedRect:newCircleBounds cornerRadius:self.circleRadius];
    
    CABasicAnimation* circlePathAnim = [CABasicAnimation animationWithKeyPath:@"path"];
    circlePathAnim.toValue = (id)newPath.CGPath;
    
    CABasicAnimation* circleBoundsAnim = [CABasicAnimation animationWithKeyPath:@"bounds"];
    circleBoundsAnim.toValue = [NSValue valueWithCGRect:newCircleBounds];
    
    CAAnimationGroup *circleGroupAnimations = [CAAnimationGroup animation];
    circleGroupAnimations.animations = [NSArray arrayWithObjects:circlePathAnim, circleBoundsAnim, nil];
    circleGroupAnimations.removedOnCompletion = NO;
    circleGroupAnimations.duration = 1.4f;
    circleGroupAnimations.fillMode = kCAFillModeForwards;
    circleGroupAnimations.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [self.circleLayer addAnimation:circleGroupAnimations forKey:@"scaleCircleAnimation"];
    
    CABasicAnimation *strokeAnimation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
    strokeAnimation.fromValue = @(0.0);
    strokeAnimation.toValue = @(1.0);
    strokeAnimation.duration = self.maxDuration;
    strokeAnimation.removedOnCompletion = NO;
    strokeAnimation.fillMode = kCAFillModeForwards;
    strokeAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    
    self.borderFillLayer.strokeEnd = 1.0;
    [self.borderFillLayer addAnimation:strokeAnimation forKey:@"strokeAnimation"];
}

- (void)endRecordingAnimation {
    self.containerLayer.transform = CATransform3DMakeScale(1.0, 1.0, 1.0);
    self.circleLayer.transform = CATransform3DMakeScale(1.0, 1.0, 1.0);
    self.borderFillLayer.strokeEnd = 0.0;
    
    [self.borderFillLayer pauseLayer];
    [self.containerLayer pauseLayer];
    [self.circleLayer pauseLayer];
}

#pragma mark - Public

- (void)reset {
    [self.containerLayer removeFromSuperlayer];
    [self.circleLayer removeFromSuperlayer];
    self.containerLayer = nil;
    self.circleLayer = nil;
    self.borderFillLayer = nil;
    self.borderLayer = nil;
    
    [self setupView];
}

@end
