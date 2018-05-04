
#import "ViewController.h"
#import "DTPullRefreshView.h"

@interface ViewController ()<UITableViewDelegate,UITableViewDataSource,DTPullRefreshViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, assign) BOOL isLoading;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initHeaderView];
}

- (void)initHeaderView {
    if (!_tableView.refreshHeaderView) {
        [_tableView initRefreshHeaderView:self];
        [_tableView.refreshHeaderView setStatusLabelContent:@"下拉同步" state:DTPullRefreshPulling];
        [_tableView.refreshHeaderView setStatusLabelContent:@"松开同步" state:DTPullRefreshPulling];
        [_tableView.refreshHeaderView setStatusLabelContent:@"同步更新中" state:DTPullRefreshPulling];
        
        [_tableView.refreshHeaderView setStatusLabelFont:[UIFont systemFontOfSize:12]];
        [_tableView.refreshHeaderView setLastUpdateLabelFont:[UIFont systemFontOfSize:11]];
        _isLoading = NO;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 100;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"Cell"];
    }
    cell.textLabel.text = @"Hello";
    return cell;
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if (_tableView.refreshHeaderView) {
        [_tableView.refreshHeaderView scrollViewWillBeginDragging:scrollView];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (_tableView.refreshHeaderView) {
        [_tableView.refreshHeaderView scrollViewDidScroll:scrollView];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (_tableView.refreshHeaderView) {
        [_tableView.refreshHeaderView scrollViewDidEndDragging:scrollView];
    }
}

#pragma mark - DTPullRefreshViewDelegate
- (void)DTPullRefreshViewDidTriggerRefresh:(DTPullRefreshView *)view
                                scrollView:(UIScrollView *)scrollView {
    // 延迟
    __weak __typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [weakSelf synchronize];
    });
}

- (void)synchronize{
    if (_isLoading) {
        return;
    }
    _isLoading = YES;
    
    if (_tableView.refreshHeaderView) {
        _isLoading = NO;
        [_tableView.refreshHeaderView refreshDataDidFinishedLoading:_tableView result:@"更新成功" delay:1.0];
    }
}
- (BOOL)DTPullRefreshViewDataSourceIsLoading:(DTPullRefreshView *)view {
    return _isLoading;
}
- (NSDate *)DTPullRefreshViewDataSourceLastUpdated:(DTPullRefreshView *)view {
    NSUserDefaults * userDefault = [NSUserDefaults standardUserDefaults];
    double second = [userDefault doubleForKey:@"last_update"];
    if (second <= 0) {
        second = [[NSDate date] timeIntervalSince1970];
    }
    return [NSDate dateWithTimeIntervalSince1970:second];
}

@end
