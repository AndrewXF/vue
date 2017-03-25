//
//  ViewController.m
//  Vue
//
//  Created by sdfsdf on 2017/3/15.
//  Copyright © 2017年 sdfsdf. All rights reserved.
//

#import "ViewController.h"
#import "VideoRecorderViewController.h"
#import "Vue-Swift.h"
#import "ThemeHelper.h"
#import "VideoPublishViewController.h"


@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    

    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake((self.view.frame.size.width-80.0f)/2.0f,100.0f, 80.0f, 80.0f)];
    [button setTitle:@"进入" forState:UIControlStateNormal];
    [button setBackgroundColor:[UIColor purpleColor]];
    [button addTarget:self action:@selector(videoButtonTouched) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
    
    
    [[ThemeHelper helper] prepareTheme];

    
    
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)videoButtonTouched
{

    VideoRecorderViewController *camera = [[VideoRecorderViewController alloc] init];
    UINavigationController *cameraNav = [[UINavigationController alloc]initWithRootViewController:camera];
    [self presentViewController:cameraNav animated:YES completion:nil];

    
//    VideoPublishViewController *publishVC = [[VideoPublishViewController alloc]init];
////    publishVC.uploadEntity = uploadInfo;
////    publishVC.fromDraft = _fromDraft;
//    
//    publishVC.savedDraft = ^(BOOL saved) {
////        if (self.savedDraft) {
////            self.savedDraft(saved);
////        }
//    };
//    
//    publishVC.onPublish = ^() {
////        if (self.onPublish) {
////            self.onPublish();
////        }
//        [self.navigationController popViewControllerAnimated:YES];
//    };
//    
//   [self presentViewController:publishVC animated:YES completion:nil];

//    [self.navigationController pushViewController:publishVC animated:YES];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
