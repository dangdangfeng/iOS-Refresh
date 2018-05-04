
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, DTPullRefreshState) {
    DTPullRefreshNormal,
    DTPullRefreshPulling,
    DTPullRefreshPreload,
    DTPullRefreshLoading,
    DTPullRefreshComplete,
};

@class DTPullRefreshView;

@protocol DTPullRefreshViewDelegate <NSObject>

@optional
- (void)DTPullRefreshViewDidTriggerRefresh:(DTPullRefreshView *)view
                                    scrollView:(UIScrollView *)scrollView;
- (BOOL)DTPullRefreshViewDataSourceIsLoading:(DTPullRefreshView *)view;
- (BOOL)DTPullRefreshViewDataSourceLastUpdatedIsShow:(DTPullRefreshView *)view;
- (NSDate *)DTPullRefreshViewDataSourceLastUpdated:(DTPullRefreshView *)view;

@end

@interface DTPullRefreshView : UIView

@property (nonatomic, weak) id<DTPullRefreshViewDelegate> delegate;
@property (nonatomic) DTPullRefreshState state;

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView;
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView;
- (void)scrollViewDidScroll:(UIScrollView *)scrollView;

- (void)refreshDataDidFinishedLoading:(UIScrollView *)scrollView;
- (void)refreshDataDidFinishedLoading:(UIScrollView *)scrollView result:(NSString *)resultMessage delay:(NSTimeInterval)delay;
- (void)refreshDataDidFailedLoading:(UIScrollView *)scrollView result:(NSString *)resultMessage delay:(NSTimeInterval)delay;

- (void)refreshDataWithScrollView:(UIScrollView *)scrollView
                         callback:(BOOL)callback
                       completion:(void(^)())completion;

- (void)setStatusLabelContent:(NSString *)content state:(DTPullRefreshState)state;
- (void)setStatusLabelColor:(UIColor *)color;
- (void)setStatusLabelFont:(UIFont *)font;
- (void)setLastUpdatedLabelColor:(UIColor *)color;
- (void)setLastUpdateLabelFont:(UIFont *)font;

@end

@interface UIScrollView (RefreshView)

@property (nonatomic, strong) DTPullRefreshView *refreshHeaderView;

- (void)initRefreshHeaderView:(id<DTPullRefreshViewDelegate>)delegate;
- (void)removeRefreshHeaderView;
- (void)refreshData;

@end
