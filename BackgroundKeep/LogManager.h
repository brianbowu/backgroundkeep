//
//  LogManager.h
//  BackgroundKeep
//
//  Created by WuBo on 16/1/29.
//  Copyright © 2016年 WeiChe. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const kAppStatusLogPath;

@interface LogManager : NSObject

+ (instancetype)sharedInstance;
- (void)onStart;
- (void)onStop;
- (void)onKilled;

@end
