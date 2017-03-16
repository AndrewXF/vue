//
//  VideoPublishViewController.m
//  Babypai
//
//  Created by ning on 16/5/10.
//  Copyright © 2016年 Babypai. All rights reserved.
//

#import "VideoPublishViewController.h"
#import "BabyUploadEntity.h"
#import "UIButton+UIButtonImageWithLabel.h"
#import "UIView+SDAutoLayout.h"
#import "BabyFileManager.h"
#import "ALDBlurImageProcessor.h"
#import "HPGrowingTextView.h"
#import "Users.h"
#import "StringUtils.h"
#import "SVProgressHUD.h"
#import "PostMessage.h"
#import "Boards.h"
#import "PublishUserViewController.h"
#import "BabyNavigationController.h"
#import "BoardsViewController.h"
#import "BabyPinUpload.h"
//#import "MainTabViewController.h"
#import <AMapLocationKit/AMapLocationKit.h>
#import <AMapSearchKit/AMapSearchKit.h>
#import "PublishLocationViewController.h"
#import "PublishTitlePageViewController.h"

#define LocationTimeout 3  //   定位超时时间，可修改，最小2s
#define MAX_LIMIT_NUMS 140

@interface VideoPublishViewController () <HPGrowingTextViewDelegate, AMapLocationManagerDelegate, UIActionSheetDelegate>

@property (nonatomic, strong) UIScrollView *scrollView;

@property (nonatomic, assign) BOOL isDraft;
@property (nonatomic, strong) UIButton *rightButton;

@property (nonatomic, strong) UIImageView *topImage;
@property (nonatomic, strong) UIImageView *smallImageInScroll;
@property (nonatomic, strong) NSString *mCoverPath;

@property(nonatomic, strong) HPGrowingTextView *textView;
@property(nonatomic, strong) UILabel *textViewNum;

@property (nonatomic, strong) UIButton *tagButton, *atButton, *locationButton, *privateButton, *addBoardButton;

@property (nonatomic, strong) UILabel *addBoardTip;

@property (nonatomic, strong) NSString *locationText;

@property (nonatomic, assign) long publish_board_id;
@property (nonatomic, strong) NSString *publish_board_text;
@property (nonatomic, strong) NSString *publish_raw_text;

@property (nonatomic, assign) BOOL bool_private;
@property (nonatomic, assign) BOOL bool_location;

@property (nonatomic, strong) NSMutableArray *friends;
@property (nonatomic, strong) NSMutableArray *atUsersArray;
@property (nonatomic, strong) NSString *atUsers;

@property (nonatomic, assign) double mLatitude;
@property (nonatomic, assign) double mLongitude;
@property (nonatomic, assign) int mProvinceCode;
@property (nonatomic, strong) NSString *mProvince;
@property (nonatomic, assign) int mCityCode;
@property (nonatomic, strong) NSString *mCity;
@property (nonatomic, assign) int mDistrictCode;
@property (nonatomic, strong) NSString *mDistrict;
@property (nonatomic, strong) NSString *mStreet;
@property (nonatomic, strong) NSString *mAddrStr;
@property (nonatomic, strong) NSString *mLocationDescribe;
@property (nonatomic, strong) NSMutableArray *mPoi;
@property (nonatomic, strong) NSString *poi;

@property (nonatomic, strong) UIActionSheet *locationSheet;

@property (nonatomic, strong) AMapLocationManager *locationManager;

@end

@implementation VideoPublishViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    
    UIButton *publishButton = [[UIButton alloc]initWithFrame:CGRectMake(0, (SCREEN_HEIGHT - NavigationBar_HEIGHT), SCREEN_WIDTH, NavigationBar_HEIGHT)];
    
    publishButton.titleLabel.font = kFontSize(18);
    [publishButton addTarget:self action:@selector(pressPublishButton) forControlEvents:UIControlEventTouchUpInside];
    [publishButton setImageRight:[UIImage imageNamed:@"ic_share_arrow"] withTitle:@"分 享 " titleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [publishButton setImageRight:[UIImage imageNamed:@"ic_share_arrow"] withTitle:@"分 享 " titleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    [publishButton setBackgroundImage:ImageNamed(@"baby_color_red_height") forState:UIControlStateNormal];
    [publishButton setBackgroundImage:ImageNamed(@"baby_color_red_base") forState:UIControlStateHighlighted];
    [self.view addSubview:publishButton];
    
    _topImage = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_WIDTH)];
    [self.view addSubview:_topImage];
    
    _scrollView = [[UIScrollView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, (SCREEN_HEIGHT - NavigationBar_HEIGHT))];
    _scrollView.bounces = YES;
    _scrollView.alwaysBounceVertical = YES;
    _scrollView.layer.zPosition = 10;
    [self.view addSubview:_scrollView];
    
    CGSize leftTexttSize = [@"返回" sizeWithAttributes:@{NSFontAttributeName: kFontSize(18)}];
    UIButton *backButton = [[UIButton alloc]initWithFrame:CGRectMake(4, (NavigationBar_HEIGHT - leftTexttSize.height) / 2, leftTexttSize.width + 32, leftTexttSize.height + 4)];
    backButton.titleLabel.font = kFontSize(18);
    [backButton addTarget:self action:@selector(pressBackButton) forControlEvents:UIControlEventTouchUpInside];
    [backButton setImage:[UIImage imageNamed:@"baby_icn_back"] withTitle:@"返回" titleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    backButton.layer.zPosition = 1000;
    [self.view addSubview:backButton];
    
    UILabel *title = [[UILabel alloc]initWithFrame:CGRectMake(SCREEN_WIDTH / 2 - 30, NavigationBar_HEIGHT / 2 - 15, 60, 30)];
    title.textColor = [UIColor whiteColor];
    title.font = kFontSize(20);
    title.textAlignment = NSTextAlignmentCenter;
    title.text = @"发 布";
    title.layer.zPosition = 1000;
    [self.view addSubview:title];
    
    CGFloat imageW = 160;
    CGFloat marginTop = TopBar_height;
    _smallImageInScroll = [[UIImageView alloc]initWithFrame:CGRectMake((SCREEN_WIDTH - imageW) / 2, marginTop, imageW, imageW)];
    [_scrollView addSubview:_smallImageInScroll];
    
    UIImageView *bottomImage = [[UIImageView alloc]initWithImage:ImageNamed(@"shadow_asset")];
    bottomImage.frame = CGRectMake((SCREEN_WIDTH - imageW) / 2, marginTop + imageW - 65, imageW, 65);
    [_scrollView addSubview:bottomImage];
    
    CGSize coverTexttSize = [@" 设置封面" sizeWithAttributes:@{NSFontAttributeName: kFontSizeSmall}];
    UIButton *coverButton = [[UIButton alloc]initWithFrame:CGRectMake((SCREEN_WIDTH - coverTexttSize.width - 32) / 2, marginTop + imageW - coverTexttSize.height - 14, coverTexttSize.width + 32, coverTexttSize.height + 10)];
    coverButton.titleLabel.font = kFontSizeSmall;
    [coverButton addTarget:self action:@selector(pressCoverButton) forControlEvents:UIControlEventTouchUpInside];
    [coverButton setImage:[UIImage imageNamed:@"ic_cover"] withTitle:@" 设置封面" titleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    coverButton.layer.zPosition = 1000;
    [_scrollView addSubview:coverButton];
    
    UIView *bottomView = [[UIView alloc]initWithFrame:CGRectMake(0, marginTop + imageW + 10, SCREEN_WIDTH, SCREEN_HEIGHT - marginTop- imageW - 10)];
    bottomView.backgroundColor = BACKGROUND_COLOR;
    [_scrollView addSubview:bottomView];
    
    UIView *bottomWhiteView = [[UIView alloc]initWithFrame:CGRectMake(0, marginTop + imageW + 10, SCREEN_WIDTH, 168)];
    bottomWhiteView.backgroundColor = [UIColor whiteColor];
    [_scrollView addSubview:bottomWhiteView];
    
    
    self.textView = [[HPGrowingTextView alloc]initWithFrame:CGRectMake(10, marginTop + imageW + 16, SCREEN_WIDTH - 20, 80)];
    self.textView.isScrollable = NO;
    self.textView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
    self.textView.backgroundColor = [UIColor clearColor];
    self.textView.minNumberOfLines = 3;
//    self.textView.maxNumberOfLines = 3;
    // you can also set the maximum height in points with maxHeight
    self.textView.maxHeight = 80.0f;
    self.textView.returnKeyType = UIReturnKeyDone;
    self.textView.font = kFontSizeNormal;
    self.textView.tintColor = UIColorFromRGB(BABYCOLOR_base_color);
    self.textView.textColor = UIColorFromRGB(BABYCOLOR_main_text);
    self.textView.dataDetectorTypes = UIDataDetectorTypeAll; // 显示数据类型的连接模式（如电话号码、网址、地址等）
    self.textView.keyboardType = UIKeyboardTypeDefault; // 设置弹出键盘的类型
    self.textView.delegate = self;
    self.textView.internalTextView.font = kFontSizeNormal;
    self.textView.internalTextView.scrollIndicatorInsets = UIEdgeInsetsMake(5, 0, 5, 0);
    self.textView.placeholder = @"描述一下";
    self.textView.placeholderColor = UIColorFromRGB(BABYCOLOR_comment_text);
    self.textView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    [_scrollView addSubview:self.textView];
    
    CGFloat bottomWhiteViewH = CGRectGetMaxY(bottomWhiteView.frame) - 48;
    
    _textViewNum = [[UILabel alloc]initWithFrame:CGRectMake(SCREEN_WIDTH - 110, bottomWhiteViewH - 40, 60, 30)];
    _textViewNum.font = kFontSizeSmall;
    _textViewNum.textAlignment = NSTextAlignmentRight;
    _textViewNum.textColor = UIColorFromRGB(BABYCOLOR_comment_text);
    [_scrollView addSubview:self.textViewNum];
    
    
    // 添加话题Button
    _tagButton = [[UIButton alloc]initWithFrame:CGRectMake(10, bottomWhiteViewH - 40, 60, 30)];
    [_tagButton addTarget:self action:@selector(pressTagButton) forControlEvents:UIControlEventTouchUpInside];
    [_tagButton setTitle:@"#话题#" forState:UIControlStateNormal];
    _tagButton.titleLabel.font = kFontSizeNormal;
    [_tagButton setTitleColor:UIColorFromRGB(BABYCOLOR_main_text) forState:UIControlStateNormal];
    [_tagButton setTitleColor:UIColorFromRGB(BABYCOLOR_main_text) forState:UIControlStateHighlighted];
    [_tagButton setBackgroundImage:ImageNamed(@"bg_circle_gray") forState:UIControlStateNormal];
    [_tagButton setBackgroundImage:ImageNamed(@"bg_circle_gray_pressed") forState:UIControlStateHighlighted];
    [_scrollView addSubview:_tagButton];
    
    // 添加AT button
    _atButton = [[UIButton alloc]initWithFrame:CGRectMake(80, bottomWhiteViewH - 40, 30, 30)];
    [_atButton addTarget:self action:@selector(pressAtButton) forControlEvents:UIControlEventTouchUpInside];
    [_atButton setImageEdgeInsets:UIEdgeInsetsMake(6, 6, 6, 6)];
    [_atButton setImage:ImageNamed(@"baby_edit_at") forState:UIControlStateNormal];
    [_atButton setImage:ImageNamed(@"baby_edit_at") forState:UIControlStateHighlighted];
    [_atButton setBackgroundImage:ImageNamed(@"bg_circle_gray") forState:UIControlStateNormal];
    [_atButton setBackgroundImage:ImageNamed(@"bg_circle_gray_pressed") forState:UIControlStateHighlighted];
    [_scrollView addSubview:_atButton];
    
    // 添加位置 button
    _locationButton = [[UIButton alloc]initWithFrame:CGRectMake(120, bottomWhiteViewH - 40, 30, 30)];
    [_locationButton addTarget:self action:@selector(pressLocationButton) forControlEvents:UIControlEventTouchUpInside];
    [_locationButton setImageEdgeInsets:UIEdgeInsetsMake(6, 6, 6, 6)];
    [_locationButton setImage:ImageNamed(@"ic_location_nor") forState:UIControlStateNormal];
    [_locationButton setImage:ImageNamed(@"ic_location_nor") forState:UIControlStateHighlighted];
    _locationButton.titleLabel.font = kFontSizeNormal;
    [_locationButton setTitleColor:UIColorFromRGB(BABYCOLOR_main_text) forState:UIControlStateNormal];
    [_locationButton setTitleColor:UIColorFromRGB(BABYCOLOR_main_text) forState:UIControlStateHighlighted];
    [_locationButton setBackgroundImage:ImageNamed(@"bg_circle_gray") forState:UIControlStateNormal];
    [_locationButton setBackgroundImage:ImageNamed(@"bg_circle_gray_pressed") forState:UIControlStateHighlighted];
    [_scrollView addSubview:_locationButton];
    
    // 添加锁定 button
    _privateButton = [[UIButton alloc]initWithFrame:CGRectMake(SCREEN_WIDTH - 40, bottomWhiteViewH - 40, 30, 30)];
    [_privateButton addTarget:self action:@selector(pressPrivateButton) forControlEvents:UIControlEventTouchUpInside];
    [_privateButton setBackgroundImage:ImageNamed(@"ic_set_media_public_nor") forState:UIControlStateNormal];
    [_privateButton setBackgroundImage:ImageNamed(@"ic_set_media_public_psd") forState:UIControlStateSelected];
    [_scrollView addSubview:_privateButton];
    
    UIView *bottomLine1 = [[UIView alloc]initWithFrame:CGRectMake(0, bottomWhiteViewH, SCREEN_WIDTH, 1)];
    bottomLine1.backgroundColor = UIColorFromRGB(BABYCOLOR_background);
    [_scrollView addSubview:bottomLine1];
    
    UILabel *addBoardTip = [[UILabel alloc]initWithFrame:CGRectMake(10, bottomWhiteViewH, 100, 48)];
    addBoardTip.text = @"添加到影集";
    addBoardTip.font = kFontSizeNormal;
    addBoardTip.textColor = UIColorFromRGB(BABYCOLOR_main_text);
    _addBoardTip = addBoardTip;
    [_scrollView addSubview:_addBoardTip];
    
    [AMapLocationServices sharedServices].apiKey = AMAPAPIKEY;
    
    
    [self initData];
    
}

- (void)initUserInfo
{
    [super initUserInfo];
    if (_publish_board_id == 0) {
        [self getUserLastBoard];
    }
    
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
    self.navigationController.navigationBar.hidden = YES;
    self.navigationController.interactivePopGestureRecognizer.enabled = NO;
//    [UIView animateWithDuration:1.4 animations:^{
//        self.navigationController.navigationBar.hidden = YES;
//    } completion:^(BOOL finished) {
//        
//        self.navigationController.navigationBar.hidden = YES;
//        
//    }];
    
    _privateButton.selected = _bool_private;
    
    [self updateLocationButton];
    [self updateRightButton];
    [self updateAddBoardButton];
    [self updateTitlePage];
//    [MobClick beginLogPageView:@"视频发布页面"];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    _locationManager = [[AMapLocationManager alloc] init];
    [_locationManager setDelegate:self];
    [_locationManager setDesiredAccuracy:kCLLocationAccuracyHundredMeters];
    [_locationManager setPausesLocationUpdatesAutomatically:NO];
//    [_locationManager setAllowsBackgroundLocationUpdates:YES];
    [_locationManager setLocationTimeout:LocationTimeout];
}

- (void)viewWillDisappear:(BOOL)animated
{
//    if (_fromDraft) {
//        [self saveDraft:1];
//    }
    
    [super viewWillDisappear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
    self.navigationController.navigationBar.hidden = NO;
//    [MobClick endLogPageView:@"视频发布页面"];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [self.locationManager stopUpdatingLocation];
    [self.locationManager setDelegate:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)initData
{
    _friends = [[NSMutableArray alloc]init];
    _atUsersArray = [[NSMutableArray alloc]init];
    _locationText = @"";
    
    _mCoverPath = _uploadEntity.file_image_path;
    if ([StringUtils isEmpty:_mCoverPath]) {
        _mCoverPath = _uploadEntity.file_image_original;
    }
    
    _bool_private = [_uploadEntity.is_private intValue] > 0 ? YES : NO;
    _publish_board_id = [_uploadEntity.board_id longValue];
    _publish_board_text = _uploadEntity.board_name;
    
    _publish_raw_text = _uploadEntity.raw_text;
    
}

- (void)getUserLastBoard
{
    DataCompletionBlock completionBlock = ^(NSDictionary *data, NSString *errorString){
        
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        
        if (data != nil) {
            Boards *boards = [Boards mj_objectWithKeyValues:data];
            if (boards.info != nil && boards.info.count > 0) {
                Board *board = [boards.info objectAtIndex:0];
                _publish_board_id = board.board_id;
                _publish_board_text = board.title;
                [self updateAddBoardButton];
            }
        }
    };
    
    
    BabyDataSource *souce = [BabyDataSource dataSource];
    
    NSString *fields = [NSString stringWithFormat:@"{\"boardId\":\"%ld\",\"uid\":\"%ld\"}", _publish_board_id, [self loginUserId]];
    [souce getData:USER_BOARD_LAST_PUBLISH parameters:fields completion:completionBlock];
}

- (void)updateTitlePage
{
    NSString *file_image_path = [[[BabyFileManager manager]getCurrentDocumentPath] stringByAppendingPathComponent:_uploadEntity.file_image_path];
    
    NSString *file_image_original = [[[BabyFileManager manager]getCurrentDocumentPath] stringByAppendingPathComponent:_uploadEntity.file_image_original];
    
    
    if (_uploadEntity.file_image_path != nil && [[Utils utils] isFileExists:file_image_path]) {
        _topImage.image = [UIImage imageWithContentsOfFile:file_image_path];
        _smallImageInScroll.image = [UIImage imageWithContentsOfFile:file_image_path];
    } else if (_uploadEntity.file_image_original != nil && [[Utils utils] isFileExists:file_image_original]) {
        _topImage.image = [UIImage imageWithContentsOfFile:file_image_original];
        _smallImageInScroll.image = [UIImage imageWithContentsOfFile:file_image_original];
    }
    
    [UIView animateWithDuration:0.3f animations:^{
        ALDBlurImageProcessor *_blurImageProcessor = [[ALDBlurImageProcessor alloc] initWithImage: _topImage.image];
        [_blurImageProcessor asyncBlurWithRadius: 5
                                      iterations: 11
                                    successBlock: ^( UIImage *blurredImage) {
                                        _topImage.image = blurredImage;
                                    }
                                      errorBlock: ^( NSNumber *errorCode ) {
                                          DLog( @"Error code: %d", [errorCode intValue] );
                                      }];
    }];
    
    
}

- (void)updateRightButton
{
    _isDraft = [_uploadEntity.is_draft intValue] == 1 ? YES : NO;
    NSString *rightText;
    if (_isDraft) {
        if (self.savedDraft) {
            self.savedDraft(YES);
        }
        rightText = @"已保存";
    } else {
        rightText = @"草稿箱";
        if (self.savedDraft) {
            self.savedDraft(NO);
        }
    }
    if (_rightButton) {
        [_rightButton removeFromSuperview];
    }
    CGSize rightTexttSize = [rightText sizeWithAttributes:@{NSFontAttributeName: kFontSize(18)}];
    _rightButton = [[UIButton alloc]initWithFrame:CGRectMake(SCREEN_WIDTH - rightTexttSize.width - 32, (NavigationBar_HEIGHT - rightTexttSize.height) / 2, rightTexttSize.width + 32, rightTexttSize.height + 4)];
    _rightButton.titleLabel.font = kFontSize(18);
    [_rightButton addTarget:self action:@selector(pressDraftButton) forControlEvents:UIControlEventTouchUpInside];
    
    if (_isDraft) {
        [_rightButton setImage:[UIImage imageNamed:@""] withTitle:rightText titleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_rightButton setImage:[UIImage imageNamed:@""] withTitle:rightText titleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
        _rightButton.enabled = NO;
    } else {
        [_rightButton setImage:[UIImage imageNamed:@"btn_save_draft_a"] withTitle:rightText titleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_rightButton setImage:[UIImage imageNamed:@"btn_save_draft_b"] withTitle:rightText titleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
        _rightButton.enabled = YES;
    }
    _rightButton.layer.zPosition = 1000;
    [self.view addSubview:_rightButton];
    
    
    
}

- (void)updateLocationButton
{
    CGRect locationFrame = _locationButton.frame;
    
    if ([StringUtils isEmpty:_locationText]) {
        locationFrame.size.width = 30;
        _locationButton.titleLabel.text = nil;
        [_locationButton setImage:ImageNamed(@"ic_location_nor") forState:UIControlStateNormal];
        [_locationButton setImage:ImageNamed(@"ic_location_nor") forState:UIControlStateHighlighted];
        [_locationButton setTitleColor:[UIColor clearColor] forState:UIControlStateNormal];
        [_locationButton setTitleColor:[UIColor clearColor] forState:UIControlStateHighlighted];
        [_locationButton.imageView setContentMode:UIViewContentModeScaleToFill];
        [_locationButton setImageEdgeInsets:UIEdgeInsetsMake(6, 6, 6, 6)];
        
    } else {
        NSString *mLocationText = [NSString stringWithFormat:@" %@",_locationText];
        CGSize locationTexttSize = [mLocationText sizeWithAttributes:@{NSFontAttributeName: kFontSizeNormal}];
        
        locationFrame.size.width = MIN((SCREEN_WIDTH - 100 - 120), locationTexttSize.width + 32);
        
        [_locationButton setImage:[UIImage imageNamed:@"ic_location"] withTitle:mLocationText titleColor:UIColorFromRGB(BABYCOLOR_main_text) forState:UIControlStateNormal];
        [_locationButton setImage:[UIImage imageNamed:@"ic_location"] withTitle:mLocationText titleColor:UIColorFromRGB(BABYCOLOR_main_text) forState:UIControlStateHighlighted];
        [_locationButton setTitleColor:UIColorFromRGB(BABYCOLOR_main_text) forState:UIControlStateNormal];
        [_locationButton setTitleColor:UIColorFromRGB(BABYCOLOR_main_text) forState:UIControlStateHighlighted];
    }
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    
    _locationButton.frame = locationFrame;
    
    // commit animations
    [UIView commitAnimations];
    
    
}

- (void)updateAddBoardButton
{
    if (_addBoardButton) {
        [_addBoardButton removeFromSuperview];
    }
    
    CGFloat addBoardTipTop = CGRectGetMinY(_addBoardTip.frame);
    
    NSString *boardText = @"选择影集";
    if (_publish_board_id > 0) {
        boardText = _publish_board_text;
    }
    
    
    CGSize boardTexttSize = [boardText sizeWithAttributes:@{NSFontAttributeName: kFontSizeNormal}];
    _addBoardButton = [[UIButton alloc]initWithFrame:CGRectMake(SCREEN_WIDTH - boardTexttSize.width - 42, addBoardTipTop, boardTexttSize.width + 32, 48)];
    _addBoardButton.titleLabel.font = kFontSizeNormal;
    [_addBoardButton addTarget:self action:@selector(pressAddBoardButton) forControlEvents:UIControlEventTouchUpInside];
    
    [_addBoardButton setImageRight:[UIImage imageNamed:@"baby_icn_next_gray"] withTitle:boardText titleColor:UIColorFromRGB(BABYCOLOR_main_text) forState:UIControlStateNormal];
    [_addBoardButton setImageRight:[UIImage imageNamed:@"baby_icn_next_gray"] withTitle:boardText titleColor:UIColorFromRGB(BABYCOLOR_main_text) forState:UIControlStateHighlighted];
    _addBoardButton.layer.zPosition = 1000;
    [_scrollView addSubview:_addBoardButton];
}

- (void)pressBackButton
{
    DLog(@"pressBackButton");
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)pressTagButton
{
    DLog(@"pressTagButton");
    [StringUtils updateTextViewTextInsertedString:self.textView withText:@"# #" isTag:YES];
}

- (void)pressAtButton
{
    DLog(@"pressAtButton");
    
    PublishUserViewController *publishUser = [[PublishUserViewController alloc]init];
    publishUser.userSelected = ^(NSMutableArray *users) {
        DLog(@"users %@", users);
        [_friends addObjectsFromArray:users];
        DLog(@"_friends %@", _friends);
        [self updateAtUsers:users];
    };
    
    
    BabyNavigationController *publishNav = [[BabyNavigationController alloc]initWithRootViewController:publishUser];
    
    [self presentViewController:publishNav animated:YES completion:nil];
}

- (void)pressLocationButton
{
    DLog(@"pressLocationButton");
    
    if (self.bool_location) {
        _locationSheet = [[UIActionSheet alloc]initWithTitle:@"位置信息" delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@"修改位置", @"删除位置", nil];
        [_locationSheet showInView:self.view];
    } else {
        [SVProgressHUD showWithStatus:@"正在获取位置"];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss];
        });
        [self startLocation];
    }
}

- (void)startLocation
{
    __weak VideoPublishViewController *wSelf = self;
    AMapLocatingCompletionBlock completionBlock = ^(CLLocation *location, AMapLocationReGeocode *regeocode, NSError *error)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss];
        });
        if (error)
        {
            NSLog(@"locError:{%ld - %@};", (long)error.code, error.localizedDescription);
            
            
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
            _mProvinceCode = 0;
            _mCityCode = [regeocode.citycode intValue];
            _mDistrictCode = [regeocode.adcode intValue];
            _mProvince = regeocode.province;
            _mCity = regeocode.city;
            _mDistrict = regeocode.district;
            _poi = regeocode.POIName;
            
            _locationText = regeocode.POIName;
            _bool_location = YES;
            [wSelf updateLocationButton];
        }
    };
    
    [_locationManager requestLocationWithReGeocode:YES completionBlock:completionBlock];
}


- (void)pressDraftButton
{
    DLog(@"pressDraftButton");
    __block VideoPublishViewController *blockSelf = self;
    _uploadEntity.is_draft = [NSNumber numberWithInt:1];
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL contextDidSave, NSError * _Nullable error) {
        [blockSelf updateRightButton];
    }];
    
}

- (void)pressPrivateButton
{
    DLog(@"pressPrivateButton");
    _bool_private = !_bool_private;
    _privateButton.selected = _bool_private;
    if (_bool_private) {
        [SVProgressHUD showErrorWithStatus:@"设置为隐私后，上传成功后不会分享给其他人啦~"];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss];
        });
    }
}

- (void)pressAddBoardButton
{
    DLog(@"pressAddBoardButton");
    
    BoardsViewController *boardsVC = [[BoardsViewController alloc]init];
    boardsVC.user_id = [self loginUserId];
    boardsVC.boardType = BOARDS_TYPE_SELECT;
    boardsVC.onBoardSelect = ^(Board *board) {
        DLog(@"board %@", board.title);
        _publish_board_id = board.board_id;
        _publish_board_text = board.title;
        [self updateAddBoardButton];
    };
    [self.navigationController pushViewController:boardsVC animated:YES];
}

- (void)pressCoverButton
{
    DLog(@"pressCoverButton");
    PublishTitlePageViewController *titleVC = [[PublishTitlePageViewController alloc]init];
    titleVC.videoPath = [[[BabyFileManager manager]getCurrentDocumentPath] stringByAppendingPathComponent:_uploadEntity.file_video_path];
    titleVC.imagePath = [[[BabyFileManager manager]getCurrentDocumentPath] stringByAppendingPathComponent:_uploadEntity.file_image_path];
    titleVC.titlePageSelected = ^(UIImage *image) {
        [[BabyFileManager manager]saveUIImageToPath:[[[BabyFileManager manager]getCurrentDocumentPath] stringByAppendingPathComponent:_uploadEntity.file_image_path] withImage:image];
    };
    
    BabyNavigationController *titleNav = [[BabyNavigationController alloc]initWithRootViewController:titleVC];
    
    [self presentViewController:titleNav animated:YES completion:nil];
}

- (void)pressPublishButton
{
    DLog(@"pressPublishButton");
    
    if (_publish_board_id == 0) {
        [SVProgressHUD showErrorWithStatus:@"请选择一个影集~"];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss];
        });
        return;
    }
    [self saveDraft:0];
    
}

- (void)saveDraft:(int)is_draft
{
    [self updateAtAllUsers];
    _publish_raw_text = self.textView.text;
    
    _uploadEntity.file_image_path = _mCoverPath;
    _uploadEntity.file_time = [NSNumber numberWithLong:[[NSDate date] timeIntervalSince1970]];
    _uploadEntity.board_id = [NSNumber numberWithLong:_publish_board_id];
    _uploadEntity.board_name = _publish_board_text;
    _uploadEntity.raw_text = _publish_raw_text;
    _uploadEntity.at_uid = _atUsers;
    _uploadEntity.is_private = _bool_private ? [NSNumber numberWithInt:1] : [NSNumber numberWithInt:0];
    _uploadEntity.share_qq = [NSNumber numberWithInt:0];
    _uploadEntity.share_wb = [NSNumber numberWithInt:0];
    _uploadEntity.share_wx = [NSNumber numberWithInt:0];
    _uploadEntity.is_draft = [NSNumber numberWithInt:is_draft];
    
    if (_bool_location) {
        _uploadEntity.province_id = [NSNumber numberWithInt:_mProvinceCode];
        _uploadEntity.city_id = [NSNumber numberWithInt:_mCityCode];
        _uploadEntity.area_id = [NSNumber numberWithInt:_mDistrictCode];
        _uploadEntity.province = _mProvince;
        _uploadEntity.city = _mCity;
        _uploadEntity.area = _mDistrict;
        _uploadEntity.addr = _poi;
        _uploadEntity.longitude = [NSNumber numberWithInt:_mLongitude];
        _uploadEntity.latitude = [NSNumber numberWithInt:_mLatitude];
    } else {
        _uploadEntity.province_id = [NSNumber numberWithInt:0];
        _uploadEntity.city_id = [NSNumber numberWithInt:0];
        _uploadEntity.area_id = [NSNumber numberWithInt:0];
        _uploadEntity.province = @"";
        _uploadEntity.city = @"";
        _uploadEntity.area = @"";
        _uploadEntity.addr = @"";
        _uploadEntity.longitude = [NSNumber numberWithInt:0];
        _uploadEntity.latitude = [NSNumber numberWithInt:0];
    }
    
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL contextDidSave, NSError * _Nullable error) {
        if (contextDidSave) {
            DLog(@"保存完成了");
        } else {
            DLog(@"保存失败了");
        }
        
        if (is_draft == 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                //回调或者说是通知主线程刷新，
                [self uploadPin];
            });
        }
        
        if (self.onPublish && !_fromDraft) {
            self.onPublish();
            [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_TAB_CHANGE object:self userInfo:@{@"selectedIndex":[NSNumber numberWithInteger:1]}];
        }
        self.navigationController.navigationBar.hidden = NO;
        [self.navigationController popViewControllerAnimated:YES];
        
        
        
    }];
    
    
    
}

- (void)updateAtUsers:(NSMutableArray *)users
{
    DLog(@"updateAtUsers");
    dispatch_async(dispatch_get_main_queue(), ^{
        for (int i = 0, j = (int)users.count; i < j; i++) {
            UserInfo *user = [users objectAtIndex:i];
            [StringUtils updateTextViewTextInsertedString:self.textView withText:[NSString stringWithFormat:@"@%@ ",user.username] isTag:NO];
            DLogE(@"self.textView : %@", self.textView.text);
        }
    });
    
}

- (void)updateAtAllUsers
{
    DLog(@"updateAtAllUsers");
    _atUsers = @"";
    
    for (UserInfo *user in _friends) {
        NSString *userId = [NSString stringWithFormat:@"%ld",user.user_id];
        if (![_atUsersArray containsObject:userId]) {
            [_atUsersArray addObject:userId];
        }
    }
    
    for (int i = 0, j = (int)_atUsersArray.count; i < j; i++) {
        _atUsers = [_atUsers stringByAppendingString:[_atUsersArray objectAtIndex:i]];
        if (i < (j-1)) {
            _atUsers = [_atUsers stringByAppendingString:@","];
        }
    }
    
    DLog(@"_atUsers : %@", _atUsers);
    
}

-(void)resignTextView
{
    [self.textView resignFirstResponder];
}

//Code from Brett Schumann
-(void) keyboardWillShow:(NSNotification *)note{
    // get keyboard size and loctaion
}

-(void) keyboardWillHide:(NSNotification *)note{
}

- (BOOL)growingTextView:(HPGrowingTextView *)growingTextView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if ([text isEqualToString:@"\n"]) {
        [growingTextView.internalTextView resignFirstResponder];
        return NO;
    }
    UITextRange *selectedRange = [growingTextView.internalTextView markedTextRange];
    //获取高亮部分
    UITextPosition *pos = [growingTextView.internalTextView positionFromPosition:selectedRange.start offset:0];
    //获取高亮部分内容
    //NSString * selectedtext = [textView textInRange:selectedRange];
    
    //如果有高亮且当前字数开始位置小于最大限制时允许输入
    if (selectedRange && pos) {
        NSInteger startOffset = [growingTextView.internalTextView offsetFromPosition:growingTextView.internalTextView.beginningOfDocument toPosition:selectedRange.start];
        NSInteger endOffset = [growingTextView.internalTextView offsetFromPosition:growingTextView.internalTextView.beginningOfDocument toPosition:selectedRange.end];
        NSRange offsetRange = NSMakeRange(startOffset, endOffset - startOffset);
        
        if (offsetRange.location < MAX_LIMIT_NUMS) {
            return YES;
        }
        else
        {
            return NO;
        }
    }
    
    
    NSString *comcatstr = [growingTextView.internalTextView.text stringByReplacingCharactersInRange:range withString:text];
    
    NSInteger caninputlen = MAX_LIMIT_NUMS - comcatstr.length;
    
    if (caninputlen >= 0)
    {
        return YES;
    }
    else
    {
        NSInteger len = text.length + caninputlen;
        //防止当text.length + caninputlen < 0时，使得rg.length为一个非法最大正数出错
        NSRange rg = {0,MAX(len,0)};
        
        if (rg.length > 0)
        {
            NSString *s = @"";
            //判断是否只普通的字符或asc码(对于中文和表情返回NO)
            BOOL asc = [text canBeConvertedToEncoding:NSASCIIStringEncoding];
            if (asc) {
                s = [text substringWithRange:rg];//因为是ascii码直接取就可以了不会错
            }
            else
            {
                __block NSInteger idx = 0;
                __block NSString  *trimString = @"";//截取出的字串
                //使用字符串遍历，这个方法能准确知道每个emoji是占一个unicode还是两个
                [text enumerateSubstringsInRange:NSMakeRange(0, [text length])
                                         options:NSStringEnumerationByComposedCharacterSequences
                                      usingBlock: ^(NSString* substring, NSRange substringRange, NSRange enclosingRange, BOOL* stop) {
                                          
                                          if (idx >= rg.length) {
                                              *stop = YES; //取出所需要就break，提高效率
                                              return ;
                                          }
                                          
                                          trimString = [trimString stringByAppendingString:substring];
                                          
                                          idx++;
                                      }];
                
                s = trimString;
            }
            //rang是指从当前光标处进行替换处理(注意如果执行此句后面返回的是YES会触发didchange事件)
            [growingTextView.internalTextView setText:[growingTextView.internalTextView.text stringByReplacingCharactersInRange:range withString:s]];
            //既然是超出部分截取了，哪一定是最大限制了。
            self.textViewNum.text = [NSString stringWithFormat:@"%d/%ld",0,(long)MAX_LIMIT_NUMS];
        }
        return NO;
    }
}

- (void)growingTextViewDidChange:(HPGrowingTextView *)growingTextView
{
    UITextRange *selectedRange = [growingTextView.internalTextView markedTextRange];
    //获取高亮部分
    UITextPosition *pos = [growingTextView.internalTextView positionFromPosition:selectedRange.start offset:0];
    
    //如果在变化中是高亮部分在变，就不要计算字符了
    if (selectedRange && pos) {
        return;
    }
    
    NSString  *nsTextContent = growingTextView.internalTextView.text;
    NSInteger existTextNum = nsTextContent.length;
    
    if (existTextNum > MAX_LIMIT_NUMS)
    {
        //截取到最大位置的字符(由于超出截部分在should时被处理了所在这里这了提高效率不再判断)
        NSString *s = [nsTextContent substringToIndex:MAX_LIMIT_NUMS];
        
        [growingTextView.internalTextView setText:s];
    }
    
    //不让显示负数
    if (existTextNum == 0) {
        self.textViewNum.hidden = YES;
    } else {
        self.textViewNum.hidden = NO;
        self.textViewNum.text = [NSString stringWithFormat:@"%d/%d",MAX(0,MAX_LIMIT_NUMS - existTextNum),MAX_LIMIT_NUMS];
    }
    
}

- (void)reLocation
{
    PublishLocationViewController *locationVC = [[PublishLocationViewController alloc]init];
    locationVC.locationSelected = ^(NSString *poi) {
        _bool_location = YES;
        _locationText = poi;
        _poi = poi;
        [self updateLocationButton];
    };
    [self.navigationController pushViewController:locationVC animated:YES];
}

#pragma actionSheet delegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    
    if (actionSheet == _locationSheet) {
        
        switch (buttonIndex) {
            case 0:
//                [self commentAt];
                
                [self reLocation];
                break;
            case 1:
                _bool_location = NO;
                _locationText = @"";
                [self updateLocationButton];
                break;
                
            default:
                break;
        }
        
    }
    
}


@end
