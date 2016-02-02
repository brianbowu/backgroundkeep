//
//  ViewController.m
//  BackgroundKeep
//
//  Created by WuBo on 16/1/29.
//  Copyright © 2016年 WeiChe. All rights reserved.
//

#import "ViewController.h"
#import "LogManager.h"
#import "LogViewController.h"

@interface ViewController ()

@property (nonatomic, strong) LogManager *logger;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)startButtonTouched:(id)sender {
    [[LogManager sharedInstance] onStart];
}


- (IBAction)stopButtonTouched:(id)sender {
    [[LogManager sharedInstance] onStop];
}


- (IBAction)logButtonTouched:(id)sender {
    LogViewController *vc = [[LogViewController alloc] init];
    [self presentViewController:vc animated:YES completion:nil];
}


@end
