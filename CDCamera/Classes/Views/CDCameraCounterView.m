//
//  CDCameraCounterView.m
//  Pods
//
//  Created by Carlos Duclos on 6/2/17.
//
//

#import "CDCameraCounterView.h"

@interface CDCameraCounterView()

@property (weak, nonatomic) IBOutlet UIView *view;
@property (weak, nonatomic) IBOutlet UILabel *elapsedTimeLabel;
@property (weak, nonatomic) IBOutlet UIView *pointView;

@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, assign) NSInteger remainingSeconds;

@end

@implementation CDCameraCounterView

#pragma mark - Lifecycle

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setup];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.pointView.layer.cornerRadius = self.pointView.frame.size.width / 2;
}

- (void)dealloc {
    [self.timer invalidate];
}

#pragma mark - Private

- (void)setup {
    Class myClass = [CDCameraCounterView class];
    NSBundle *bundle = [NSBundle bundleForClass:myClass];
    self.view = [bundle loadNibNamed:NSStringFromClass(myClass) owner:self options:nil].firstObject;
    [self addSubview:self.view];
}

- (void)updateCounter:(NSTimer *)timer {
    if (self.remainingSeconds < 0) {
        [self.timer invalidate];
        return;
    }
    self.remainingSeconds -= 1;
    self.elapsedTimeLabel.text = [self formattedRemainingSeconsString];
}

- (NSString *)formattedRemainingSeconsString {
    NSUInteger minutes = (self.remainingSeconds % 3600) / 60;
    NSUInteger seconds = (self.remainingSeconds % 3600) % 60;
    return [NSString stringWithFormat:@"%02lu:%02lu", (unsigned long)minutes, (unsigned long)seconds];
}

#pragma mark - Public

- (void)startCounterWithSeconds:(NSUInteger)seconds {
    if (self.timer) {
        [self.timer invalidate];
    }
    
    self.remainingSeconds = seconds;
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateCounter:) userInfo:nil repeats:YES];
    self.elapsedTimeLabel.text = [self formattedRemainingSeconsString];
    
    [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionAutoreverse|UIViewAnimationOptionRepeat animations:^{
        self.pointView.alpha = 0.0;
    } completion:nil];
}

@end
