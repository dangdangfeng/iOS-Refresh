
#import "DTPullRefreshView.h"
#import <objc/runtime.h>

static const int kSecondsOfMinute =   60;
static const int kSecondsOfHour =     60 * 60;
static const int kSecondsOfDay =      60 * 60 * 24;
static const int kSecondsOfMouth =    60 * 60 * 24 * 30;
static const int kSecondsOfYear =     60 * 60 * 24 * 30 * 12;

// 在拖拽动画中设置layer.speed = 0会导致稍后的屏幕旋转中界面卡死，原因不明。
// 尝试各种方法失败之后，决定删除layer.speed = 0代码，用一个几乎永久的时间替代速度为0的情况。
static const CFTimeInterval kDraggingAnimationDuration = 1000000000;

@interface DTPullRefreshView () {
    NSDate * requestTime;
    NSDictionary * statusContentDic;
    
    DTPullRefreshState _state;
    
    UILabel *_statusLabel;
    UIImageView *_arrowImage;
    UIImageView *_imageView2;
    UIImageView *_imageView3;
    
    NSString * _resultMessage;
}

@property (nonatomic, weak) UILabel *lastUpdatedLabel;

@end

@implementation DTPullRefreshView

- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        
        statusContentDic = [[NSMutableDictionary alloc] initWithDictionary:@{@(DTPullRefreshNormal).stringValue: NSLocalizedString(@"下拉刷新", nil), @(DTPullRefreshPulling).stringValue: NSLocalizedString(@"下拉刷新", nil), @(DTPullRefreshPreload).stringValue: NSLocalizedString(@"松开刷新", nil), @(DTPullRefreshLoading).stringValue: NSLocalizedString(@"正在加载", nil), @(DTPullRefreshComplete).stringValue: NSLocalizedString(@"更新成功", nil)}];
        
        UIColor *textColor = [UIColor colorWithRed:87.0/255.0 green:108.0/255.0 blue:137.0/255.0 alpha:1.0];
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, frame.size.height - 30.0f, self.frame.size.width, 20.0f)];
        label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        label.font = [UIFont systemFontOfSize:12.0f];
        label.textColor = textColor;
        label.backgroundColor = [UIColor clearColor];
        [self addSubview:label];
        _lastUpdatedLabel=label;
        
        label = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, frame.size.height - 48.0f, self.frame.size.width, 20.0f)];
        label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        label.font = [UIFont boldSystemFontOfSize:12.0f];
        label.textColor = textColor;
        label.backgroundColor = [UIColor clearColor];
        [self addSubview:label];
        _statusLabel=label;
        
        _arrowImage = [[UIImageView alloc] initWithFrame:CGRectMake(25.0f, frame.size.height - 40, 25, 25)];
        _arrowImage.backgroundColor = [UIColor clearColor];
        _arrowImage.image = [UIImage imageNamed:@"refresh_img1"];
        [self addSubview:_arrowImage];
        
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
        imageView.backgroundColor = [UIColor clearColor];
        imageView.image = [UIImage imageNamed:@"refresh_img2"];
        [self addSubview:imageView];
        _imageView2 = imageView;
        
        imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 25, 25)];
        imageView.backgroundColor = [UIColor clearColor];
        imageView.contentMode = UIViewContentModeLeft;
        imageView.clipsToBounds = YES;
        [self addSubview:imageView];
        _imageView3 = imageView;
        _imageView3.hidden = YES;
        
        [self setState:DTPullRefreshNormal];
    }
    return self;
}

- (void)dealloc {
    _statusLabel = nil;
    _arrowImage = nil;
    _lastUpdatedLabel = nil;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    CGFloat imageWidth = 25;
    CGFloat padding = 15;
    
    CGFloat contentWidth = self.frame.size.width;
    
    NSString *startString = [statusContentDic valueForKey:@(DTPullRefreshNormal).stringValue];
    CGSize startSize = [startString sizeWithAttributes:@{NSFontAttributeName:_statusLabel.font}];
    CGFloat originX = (contentWidth - imageWidth - padding - startSize.width)/2;
    _arrowImage.frame = CGRectMake(originX, self.frame.size.height - 40, imageWidth, imageWidth);
    _imageView2.center = _arrowImage.center;
    _imageView3.center = _arrowImage.center;
    BOOL isShow = YES;
    if ([_delegate respondsToSelector:@selector(DTPullRefreshViewDataSourceLastUpdatedIsShow:)]) {
        isShow = [_delegate DTPullRefreshViewDataSourceLastUpdatedIsShow:self];
    }
    if (isShow) {
        _statusLabel.frame = CGRectMake(CGRectGetMaxX(_arrowImage.frame) + padding, self.frame.size.height - 48, screenSize.width, 20);
        _lastUpdatedLabel.frame = CGRectMake(CGRectGetMinX(_statusLabel.frame), self.frame.size.height - 30, screenSize.width, 20);
    } else {
        _statusLabel.frame = CGRectMake(CGRectGetMaxX(_arrowImage.frame) + padding, self.frame.size.height - 38, screenSize.width, 20);
        _lastUpdatedLabel.hidden = YES;
    }
}

#pragma mark - Setters

- (void)refreshLastUpdatedDate {
    NSDate *date = nil;
    if ([_delegate respondsToSelector:@selector(DTPullRefreshViewDataSourceLastUpdated:)]) {
        date = [_delegate DTPullRefreshViewDataSourceLastUpdated:self];
    }
    _lastUpdatedLabel.text = [DTPullRefreshView stringFromDate:date];
}

+ (NSString *)stringFromDate:(NSDate *)date {
    if (!date) {
        return @"从未更新";
    } else if (0 == [date timeIntervalSince1970]) {
        return @"从未更新";
    }
    int seconds = [[NSDate date] timeIntervalSinceDate:date];
    if (seconds < kSecondsOfMinute) {
        return @"刚刚更新";
    } else if (seconds < kSecondsOfHour) {
        return [NSString stringWithFormat:@"%d分钟前更新", seconds/kSecondsOfMinute];
    } else if (seconds < kSecondsOfDay) {
        return [NSString stringWithFormat:@"%d小时前更新", seconds/kSecondsOfHour];
    } else if (seconds < kSecondsOfMouth) {
        return [NSString stringWithFormat:@"%d天前更新", seconds/kSecondsOfDay];
    } else if (seconds < kSecondsOfYear) {
        return [NSString stringWithFormat:@"%d月前更新", seconds/kSecondsOfMouth];
    } else {
        return [NSString stringWithFormat:@"%d年前更新", seconds/kSecondsOfYear];
    }
}

- (void)setState:(DTPullRefreshState)aState {
    if (self.state == aState) {
        return;
    }
    switch (self.state) {
        case DTPullRefreshNormal:
        case DTPullRefreshPulling:
        case DTPullRefreshPreload:
        case DTPullRefreshLoading:
        case DTPullRefreshComplete:
        default:
            break;
    }
    switch (aState) {
        case DTPullRefreshNormal:
            _statusLabel.text = [statusContentDic valueForKey:@(DTPullRefreshNormal).stringValue];
            break;
        case DTPullRefreshPulling:
            _statusLabel.text = [statusContentDic valueForKey:@(DTPullRefreshPulling).stringValue];
            [self refreshLastUpdatedDate];
            _imageView2.alpha = 0;
            break;
        case DTPullRefreshPreload:
            _statusLabel.text = [statusContentDic valueForKey:@(DTPullRefreshPreload).stringValue];
            break;
        case DTPullRefreshLoading:
            _statusLabel.text = [statusContentDic valueForKey:@(DTPullRefreshLoading).stringValue];
            [self startLoadingAnimation];
            break;
        case DTPullRefreshComplete:
            _statusLabel.text = [statusContentDic valueForKey:@(DTPullRefreshComplete).stringValue];
        default:
            break;
    }
    
    _state = aState;
    [self setNeedsLayout];
}

- (void)setStatusLabelContent:(NSString *)content state:(DTPullRefreshState)state {
    [statusContentDic setValue:content forKey:@(state).stringValue];
    [self setState:_state];
}

- (void)setStatusLabelColor:(UIColor *)color {
    [_statusLabel setTextColor:color];
}

- (void)setStatusLabelFont:(UIFont *)font {
    [_statusLabel setFont:font];
}

- (void)setLastUpdatedLabelColor:(UIColor *)color {
    [_lastUpdatedLabel setTextColor:color];
}

- (void)setLastUpdateLabelFont:(UIFont *)font {
    [_lastUpdatedLabel setFont:font];
}

- (void)refreshDataWithScrollView:(UIScrollView *)scrollView
                         callback:(BOOL)callback
                       completion:(void(^)())completion {
    [self startDraggingAnimationWithDuration:0.3];
    self.state = DTPullRefreshPulling;
    [UIView animateWithDuration:0.3 animations:^{
        scrollView.contentInset = UIEdgeInsetsMake(60, 0, 0, 0);
        scrollView.contentOffset = CGPointMake(0, -60);
    } completion:^(BOOL finished) {
        self.state = DTPullRefreshPreload;
        [self startLoadingWithScrollView:scrollView callback:callback];
        if (completion) {
            completion();
        }
    }];
}

- (void)startLoadingAnimation {
    CABasicAnimation *rotationAnimation;
    rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimation.toValue = [NSNumber numberWithFloat: M_PI * 3.0 ];
    rotationAnimation.duration = 1;
    rotationAnimation.cumulative = YES;
    rotationAnimation.repeatCount = CGFLOAT_MAX;
    rotationAnimation.fillMode = kCAFillModeForwards;
    rotationAnimation.timingFunction = [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionLinear];
    
    [_arrowImage.layer addAnimation:rotationAnimation forKey:@"rotationAnimation"];
    _arrowImage.layer.speed = 1;
    
    rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimation.toValue = [NSNumber numberWithFloat: M_PI * 2.0 ];
    rotationAnimation.duration = 1;
    rotationAnimation.cumulative = YES;
    rotationAnimation.repeatCount = CGFLOAT_MAX;
    rotationAnimation.timingFunction = [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionLinear];
    
    [_imageView2.layer addAnimation:rotationAnimation forKey:@"rotationAnimation"];
    _imageView2.layer.speed = 1;
    
    [UIView animateWithDuration:0.3 animations:^{
        _imageView2.alpha = 1;
    }];
}

- (void)stopLoadingAnimation:(BOOL)success {
    [UIView animateWithDuration:0.3 animations:^{
        _imageView2.alpha = 0;
    } completion:^(BOOL finished) {
        CFTimeInterval mediaTime = CACurrentMediaTime();
        CFTimeInterval timeOffset = [_imageView2.layer convertTime:mediaTime fromLayer:nil];
        _imageView2.layer.speed = LONG_MAX;
        _imageView2.layer.timeOffset = timeOffset;
        
        timeOffset = [_arrowImage.layer convertTime:mediaTime fromLayer:nil];
        _arrowImage.layer.speed = LONG_MAX;
        _arrowImage.layer.timeOffset = timeOffset;

        if (success) {
            CGRect frame = _imageView3.frame;
            frame.size.width = 0;
            _imageView3.image = [UIImage imageNamed:@"refresh_img3"];
            _imageView3.frame = frame;
            _imageView3.hidden = NO;
            frame.size.width = 25;
            [UIView animateWithDuration:0.3 animations:^{
                _imageView3.frame = frame;
            }];
        } else {
            _imageView3.image = [UIImage imageNamed:@"refresh_img4"];
            _imageView3.alpha = 0;
            _imageView3.hidden = NO;
            [UIView animateWithDuration:0.3 animations:^{
                _imageView3.alpha = 1;
            }];
        }
    }];
}

- (void)finishLoadingAnimation:(UIScrollView *)scrollView message:(NSString *)message success:(BOOL)success {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeoutLoadingWithScrollView:) object:scrollView];
    
    self.state = DTPullRefreshComplete;
    if (message && message.length > 0) {
        _statusLabel.text = message;
        [self stopLoadingAnimation:success];
    }
    [UIView animateWithDuration:0.3 delay:0.8 options:UIViewAnimationOptionCurveLinear animations:^{
        [scrollView setContentInset:UIEdgeInsetsZero];
    } completion:^(BOOL finished) {
        _imageView3.hidden = YES;
        _arrowImage.layer.speed = 1;
        _imageView2.layer.speed = 1;
        [_arrowImage.layer removeAllAnimations];
        [_imageView2.layer removeAllAnimations];
    }];
}

- (void)startDraggingAnimation {
    [self startDraggingAnimationWithDuration:kDraggingAnimationDuration];
}

- (void)startDraggingAnimationWithDuration:(CFTimeInterval)duration {
    [_arrowImage.layer removeAllAnimations];
    _arrowImage.transform = CGAffineTransformIdentity;
    
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    animation.fromValue = [NSNumber numberWithFloat:0];
    animation.toValue = [NSNumber numberWithFloat:1];
    animation.duration = duration;
    animation.cumulative = YES;
    animation.repeatCount = 1;
    animation.removedOnCompletion = NO;
    animation.fillMode = kCAFillModeForwards;
    
    [_arrowImage.layer addAnimation:animation forKey:@"draggingAnimation1"];
    
    animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    animation.toValue = [NSNumber numberWithFloat: M_PI * 2 ];
    animation.duration = duration;
    animation.cumulative = YES;
    animation.repeatCount = 1;
    animation.removedOnCompletion = NO;
    animation.fillMode = kCAFillModeForwards;
    
    [_arrowImage.layer addAnimation:animation forKey:@"draggingAnimation2"];
}

- (void)finishDraggingAnimation {
    [_arrowImage.layer removeAllAnimations];
}

- (void)setDraggingAnimationPercent:(CGFloat)percent {
    _arrowImage.layer.timeOffset = percent * kDraggingAnimationDuration;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    static const CGFloat MAX_CONTENT_HEIGHT = 60;
    if (scrollView.isDragging) {
        CGFloat offsetY = -scrollView.contentOffset.y;
        CGFloat percent;
        if (offsetY <= 0) {
            percent = 0;
            self.state = DTPullRefreshNormal;
        } else if (offsetY >= MAX_CONTENT_HEIGHT) {
            percent = 1;
            self.state = DTPullRefreshPreload;
        } else {
            percent = offsetY / MAX_CONTENT_HEIGHT;
            self.state = DTPullRefreshPulling;
        }
        [self setDraggingAnimationPercent:percent];
    } else if (self.state == DTPullRefreshLoading) {
        CGFloat offsetY = MAX(-scrollView.contentOffset.y, 0);
        offsetY = MIN(offsetY, MAX_CONTENT_HEIGHT);
        scrollView.contentInset = UIEdgeInsetsMake(offsetY, 0.0f, 0.0f, 0.0f);
    } else if (self.state == DTPullRefreshPreload) {
        CGFloat offsetY = -scrollView.contentOffset.y;
        if (offsetY <= 0) {
            [self finishDraggingAnimation];
            self.state = DTPullRefreshNormal;
        } else if (offsetY < MAX_CONTENT_HEIGHT) {
            self.state = DTPullRefreshPulling;
        }
    } else if (self.state == DTPullRefreshPulling) {
        CGFloat offsetY = -scrollView.contentOffset.y;
        CGFloat percent = offsetY / MAX_CONTENT_HEIGHT;
        if (percent > 0 && percent < 1) {
            [self setDraggingAnimationPercent:percent];
        } else if (percent == 0) {
            [self finishDraggingAnimation];
            self.state = DTPullRefreshNormal;
        }
    }
    [scrollView setNeedsDisplay];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if (self.state != DTPullRefreshLoading) {
        [self startDraggingAnimation];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView {
    BOOL _loading = NO;
    if ([_delegate respondsToSelector:@selector(DTPullRefreshViewDataSourceIsLoading:)]) {
        _loading = [_delegate DTPullRefreshViewDataSourceIsLoading:self];
    }
    if (!_loading) {
        /*没有正在请求或正在请求但是状态不是loading的情况 需要置下状态*/
        [self startLoadingWithScrollView:scrollView callback:YES];
    }
}

- (void)startLoadingWithScrollView:(UIScrollView *)scrollView callback:(BOOL)callback {
    if (self.state == DTPullRefreshPreload) {
        if (callback && [_delegate respondsToSelector:@selector(DTPullRefreshViewDidTriggerRefresh:scrollView:)]) {
            [_delegate DTPullRefreshViewDidTriggerRefresh:self scrollView:scrollView];
        }
        [self finishDraggingAnimation];
        self.state = DTPullRefreshLoading;
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.3 animations:^{
                scrollView.contentInset = UIEdgeInsetsMake(60, 0, 0, 0);
                [scrollView setContentOffset:CGPointMake(0, -60) animated:YES];
            }];
        });
        [self performSelector:@selector(timeoutLoadingWithScrollView:) withObject:scrollView afterDelay:10];
    }
}

- (void)timeoutLoadingWithScrollView:(UIScrollView *)scrollView {
    [self refreshDataDidFailedLoading:scrollView result:@"更新超时" delay:0];
}

- (void)refreshDataDidFinishedLoading:(UIScrollView *)scrollView {
    [self finishLoadingAnimation:scrollView message:nil success:YES];
}

- (void)refreshDataDidFinishedLoading:(UIScrollView *)scrollView result:(NSString *)resultMessage delay:(NSTimeInterval)delay {
    [self finishLoadingAnimation:scrollView message:resultMessage success:YES];
}

- (void)refreshDataDidFailedLoading:(UIScrollView *)scrollView result:(NSString *)resultMessage delay:(NSTimeInterval)delay {
    [self finishLoadingAnimation:scrollView message:resultMessage success:NO];
}

@end

@implementation UIScrollView (RefreshView)

- (void)initRefreshHeaderView:(id<DTPullRefreshViewDelegate>)delegate {
    CGRect frame = self.bounds;
    frame.origin.y = -frame.size.height;
    self.refreshHeaderView = [[DTPullRefreshView alloc] initWithFrame:frame];
    self.refreshHeaderView.delegate = delegate;
    [self addSubview:self.refreshHeaderView];
}

- (void)removeRefreshHeaderView {
    if (self.refreshHeaderView) {
        [self.refreshHeaderView removeFromSuperview];
        self.refreshHeaderView = nil;
    }
}

- (DTPullRefreshView *)refreshHeaderView {
    return objc_getAssociatedObject(self, @selector(refreshHeaderView));
}

- (void)setRefreshHeaderView:(DTPullRefreshView *)refreshHeaderView {
    objc_setAssociatedObject(self, @selector(refreshHeaderView), refreshHeaderView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)refreshData {
    [self.refreshHeaderView refreshDataWithScrollView:self callback:YES completion:nil];
}

@end
