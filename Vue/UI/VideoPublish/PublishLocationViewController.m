//
//  PublishLocationViewController.m
//  Babypai
//
//  Created by ning on 16/5/17.
//  Copyright © 2016年 Babypai. All rights reserved.
//

#import "PublishLocationViewController.h"
#import <AMapLocationKit/AMapLocationKit.h>
#import <AMapSearchKit/AMapSearchKit.h>
#import "CellLocationPublish.h"
#import "MJRefresh.h"
#import "SVProgressHUD.h"

@interface PublishLocationViewController ()<AMapLocationManagerDelegate, AMapSearchDelegate, UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) NSMutableArray *mPois;
@property (nonatomic, assign) int cursor;
@property (nonatomic, strong)UITableView *tableView;

@property (nonatomic, strong) AMapLocationManager *locationManager;
@property (nonatomic, strong) AMapSearchAPI *search;

@end

@implementation PublishLocationViewController

- (NSString *)title
{
    return @"修改位置";
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [MobClick beginLogPageView:[self title]];
}
- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [MobClick endLogPageView:[self title]];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _cursor = 1;
    
    self.tableView = [[UITableView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT) style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.backgroundColor = UIColorFromRGB(BABYCOLOR_background);
    [self.view addSubview:self.tableView];
    [self.tableView registerClass:[CellLocationPublish class] forCellReuseIdentifier:NSStringFromClass([CellLocationPublish class])];
    
    [AMapLocationServices sharedServices].apiKey = AMAPAPIKEY;
    _locationManager = [[AMapLocationManager alloc] init];
    [_locationManager setDelegate:self];
    [_locationManager setDesiredAccuracy:kCLLocationAccuracyHundredMeters];
    [_locationManager setPausesLocationUpdatesAutomatically:NO];
//    [_locationManager setAllowsBackgroundLocationUpdates:YES];
    [_locationManager setLocationTimeout:3];
}

- (void)initUserInfo
{
    [super initUserInfo];
    [self loadData];
}

- (void)loadData
{
    // 设置普通状态的动画图片
    NSMutableArray *idleImages = [NSMutableArray array];
    for (NSUInteger i = 1; i<=60; i++) {
        UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:@"dropdown_anim__000%zd", i]];
        [idleImages addObject:image];
    }
    
    // 设置即将刷新状态的动画图片（一松开就会刷新的状态）
    NSMutableArray *refreshingImages = [NSMutableArray array];
    for (NSUInteger i = 1; i<=8; i++) {
        UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:@"dropdown_loading_0%zd", i]];
        [refreshingImages addObject:image];
    }
    
    
    // 设置回调（一旦进入刷新状态，就调用target的action，也就是调用self的loadNewData方法）
    MJRefreshGifHeader *header = [MJRefreshGifHeader headerWithRefreshingTarget:self refreshingAction:@selector(loadNewData)];
    // 设置普通状态的动画图片
    [header setImages:idleImages forState:MJRefreshStateIdle];
    // 设置即将刷新状态的动画图片（一松开就会刷新的状态）
    [header setImages:refreshingImages forState:MJRefreshStatePulling];
    // 设置正在刷新状态的动画图片
    [header setImages:refreshingImages forState:MJRefreshStateRefreshing];
    // 设置header
    
    header.lastUpdatedTimeLabel.hidden = YES;
    header.stateLabel.hidden = YES;
    
    self.tableView.mj_header = header;
    [self.tableView.mj_header beginRefreshing];
    
}

- (void)loadDataMore
{
    _cursor++;
    [self loadNewData];
}

- (void)loadNewData
{
    DLogE(@"loadNewData");
    __weak PublishLocationViewController *wSelf = self;
    AMapLocatingCompletionBlock completionBlock = ^(CLLocation *location, AMapLocationReGeocode *regeocode, NSError *error)
    {
        
         DLogE(@"completionBlock-----");
        if (error)
        {
            DLogE(@"locError:{%ld - %@};", (long)error.code, error.localizedDescription);
            
            
            [SVProgressHUD showErrorWithStatus:@"无法获取您的位置信息~"];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [SVProgressHUD dismiss];
            });
            
            if (error.code == AMapLocationErrorLocateFailed)
            {
                return;
            }
        }
        
        if (location)
        {
            [wSelf searchPOI:location];
        }
    };
    
    [_locationManager requestLocationWithReGeocode:NO completionBlock:completionBlock];
    
}

- (void)searchPOI:(CLLocation *)location
{
    DLogE(@"searchPOI, %f, %f", location.coordinate.latitude, location.coordinate.longitude);
    //配置用户Key
    [AMapSearchServices sharedServices].apiKey = AMAPAPIKEY;
    
    //初始化检索对象
    _search = [[AMapSearchAPI alloc] init];
    _search.delegate = self;
    //构造AMapPOIAroundSearchRequest对象，设置周边请求参数
    AMapPOIAroundSearchRequest *request = [[AMapPOIAroundSearchRequest alloc] init];
    request.location = [AMapGeoPoint locationWithLatitude:location.coordinate.latitude longitude:location.coordinate.longitude];
    request.keywords = @"";
    // types属性表示限定搜索POI的类别，默认为：餐饮服务|商务住宅|生活服务
    // POI的类型共分为20种大类别，分别为：
    // 汽车服务|汽车销售|汽车维修|摩托车服务|餐饮服务|购物服务|生活服务|体育休闲服务|
    // 医疗保健服务|住宿服务|风景名胜|商务住宅|政府机构及社会团体|科教文化服务|
    // 交通设施服务|金融保险服务|公司企业|道路附属设施|地名地址信息|公共设施
    request.types = @"生活服务|交通设施服务|道路附属设施|地名地址信息|公共设施|风景名胜";
    request.sortrule = 0;
    request.offset = 50;
    request.page = _cursor;
    request.requireExtension = YES;
    
    //发起周边搜索
    [_search AMapPOIAroundSearch: request];
}

//实现POI搜索对应的回调函数
- (void)onPOISearchDone:(AMapPOISearchBaseRequest *)request response:(AMapPOISearchResponse *)response
{
    DLogE(@"onPOISearchDone----");
    
    if(response.pois.count == 0)
    {
        [SVProgressHUD showErrorWithStatus:@"无法获取周围信息~"];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss];
        });
        
        return;
    }
    
    //通过 AMapPOISearchResponse 对象处理搜索结果
    NSString *strCount = [NSString stringWithFormat:@"count: %ld",response.count];
    NSString *strSuggestion = [NSString stringWithFormat:@"Suggestion: %@", response.suggestion];
    NSString *strPoi = @"";
    for (AMapPOI *p in response.pois) {
        strPoi = [NSString stringWithFormat:@"%@\nPOI: %@", strPoi, p.name];
    }
    NSString *result = [NSString stringWithFormat:@"%@ \n %@ \n %@", strCount, strSuggestion, strPoi];
    DLog(@"Place: %@", result);
    
    if (self.mPois == nil) {
        self.mPois = [response.pois mutableCopy];
        MJRefreshAutoNormalFooter *footer = [MJRefreshAutoNormalFooter footerWithRefreshingTarget:self refreshingAction:@selector(loadDataMore)];
        [footer setTitle:NOMOREDATA forState:MJRefreshStateNoMoreData];
        self.tableView.mj_footer = footer;
    } else {
        if ([response.pois count] == 0) {
            [self.tableView.mj_footer endRefreshingWithNoMoreData];
        } else {
            [self.mPois addObjectsFromArray:response.pois];
            [self.tableView reloadData];
            if ([response.pois count] < 10) {
                [self.tableView.mj_footer endRefreshingWithNoMoreData];
            }
        }
    }
    
    
    
    [self.tableView reloadData];
    [self.tableView.mj_header endRefreshing];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return _mPois.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return LocationCellH;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    CellLocationPublish *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([CellLocationPublish class])];
    
    cell.mAMapPOI = _mPois[indexPath.row];
    cell.selectedBackgroundView.backgroundColor = UIColorFromRGB(BABYCOLOR_background);
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (self.locationSelected) {
        AMapPOI *mAMapPOI = _mPois[indexPath.row];
        self.locationSelected(mAMapPOI.name);
    }
    [self.navigationController popViewControllerAnimated:YES];
}

@end
