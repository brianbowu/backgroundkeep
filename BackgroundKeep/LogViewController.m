//
//  LogViewController.m
//  BackgroundKeep
//
//  Created by WuBo on 16/2/1.
//  Copyright © 2016年 WeiChe. All rights reserved.
//

#import "LogViewController.h"
#import "LogManager.h"

@interface LogViewController ()

@property (weak, nonatomic) IBOutlet UITextView *logDetailView;

@end

@implementation LogViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self readLogFile];
}


- (void)readLogFile {
    NSString *filePath = [NSHomeDirectory() stringByAppendingString:kAppStatusLogPath];
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:filePath]) {
        self.logDetailView.text = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
    }
}


@end
