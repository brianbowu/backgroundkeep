//
//  LogManager.m
//  BackgroundKeep
//
//  Created by WuBo on 16/1/29.
//  Copyright © 2016年 WeiChe. All rights reserved.
//

#import "LogManager.h"
#import <CoreLocation/CoreLocation.h>
#import <UIKit/UIKit.h>


NSString * const kAppStatusLogPath = @"/Documents/applog.txt";

@interface LogManager () <CLLocationManagerDelegate>

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, assign) BOOL isRunning;
@property (nonatomic, assign) BOOL inBackground;
@property (nonatomic, assign) BOOL deferringUpdates;

@property (nonatomic, strong) NSString *appStatusLog;


@end

@implementation LogManager

static LogManager *logManager;
+ (instancetype)sharedInstance {
    static dispatch_once_t _onceToken;
    dispatch_once(&_onceToken, ^{
        logManager = [[self alloc] init];
    });
    return logManager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        
        self.isRunning = NO;
        self.inBackground = NO;
        self.deferringUpdates = NO;
        
        [self configNotification];
        [self configLocationManager];
        
        [self createAppLogFile];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)configNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAppWillTerminate:) name:UIApplicationWillTerminateNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAppDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAppDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
}

- (void)configLocationManager {
    if ([CLLocationManager locationServicesEnabled]) {
        
        // For iOS8, should request authorization
        if ([self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
            [self.locationManager requestAlwaysAuthorization];
        }
        
        // For iOS9, should allow background location update
        if ([self.locationManager respondsToSelector:@selector(allowsBackgroundLocationUpdates)]) {
            self.locationManager.allowsBackgroundLocationUpdates = YES;
        }
        
        self.locationManager.delegate = self;
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        self.locationManager.distanceFilter = 1;
        self.locationManager.pausesLocationUpdatesAutomatically = NO;

    }
}

- (void)onStart {
    if (self.isRunning == YES) {
        return;
    }
    
    if ([CLLocationManager locationServicesEnabled]) {
        [self.locationManager startUpdatingLocation];
        
        if ([CLLocationManager significantLocationChangeMonitoringAvailable]) {
            [self.locationManager stopMonitoringSignificantLocationChanges];
        }
        
        self.isRunning = YES;
        
        [self loggingAppStatus:@"Start Logging"];
    }
}

- (void)onStop {
    if ([CLLocationManager locationServicesEnabled]) {
        [self.locationManager stopUpdatingLocation];
        
        if ([CLLocationManager significantLocationChangeMonitoringAvailable]) {
            [self.locationManager stopMonitoringSignificantLocationChanges];
        }
    }
    
    self.isRunning = NO;
    
    [self loggingAppStatus:@"Stop Logging"];
    
}

- (void)onKilled {
    [self loggingAppStatus:@"Kill App"];
}

#pragma mark - Log

- (void)createAppLogFile {
    NSData *logData = [NSData dataWithContentsOfFile:[NSHomeDirectory() stringByAppendingString:kAppStatusLogPath]];
    _appStatusLog = [[NSString alloc] initWithData:logData encoding:NSUTF8StringEncoding];
}

- (void)loggingAppStatus:(NSString *)status {
    NSDateFormatter *f = [[NSDateFormatter alloc] init];
    [f setLocale:[NSLocale systemLocale]];
    [f setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *dateStr = [f stringFromDate:[NSDate date]];
    
    NSString *textToAppend = [NSString stringWithFormat:@"time: %@, app status: %@ \n\r", dateStr, status];
    self.appStatusLog = [self.appStatusLog stringByAppendingString:textToAppend];
    NSData *dataToWrite = [self.appStatusLog dataUsingEncoding:NSUTF8StringEncoding];
    [dataToWrite writeToFile:[NSHomeDirectory() stringByAppendingString:kAppStatusLogPath] atomically:YES];
}


#pragma mark - CLLocationManager delegate methods

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(nonnull NSArray<CLLocation *> *)locations {
    
    // Deferred GPS update for saving power
    if ([CLLocationManager locationServicesEnabled] && [CLLocationManager deferredLocationUpdatesAvailable]) {
        if (self.inBackground == YES) {
            if (self.deferringUpdates == NO) {
                [self.locationManager allowDeferredLocationUpdatesUntilTraveled:1000 timeout:1800];
                self.deferringUpdates = YES;
                [self loggingAppStatus:@"开始GPS延时：1000米 1800秒"];
            }
        } else {
            if (self.deferringUpdates == YES) {
                [self.locationManager disallowDeferredLocationUpdates];
                self.deferringUpdates = NO;
                [self loggingAppStatus:@"结束GPS延时"];
            }
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSString *logStatus = nil;

    switch ([error code]) {
        case kCLErrorDenied:
            logStatus = @"获取定位被拒绝";
            break;
        case kCLErrorNetwork:
            logStatus = @"网络错误";
            break;
        case kCLErrorLocationUnknown:
            logStatus = @"未知位置";
            break;
        default:
            break;
    }
    
    [self loggingAppStatus:logStatus];
}

- (void)locationManager:(CLLocationManager *)manager didFinishDeferredUpdatesWithError:(NSError *)error {
    NSString *logStatus = nil;
    // > iOS 6.0
    switch ([error code]) {
        case kCLErrorDenied:
            logStatus = @"GPS权限失败";
            break;
        case kCLErrorNetwork:
            logStatus = @"网络错误";
            break;
        case kCLErrorDeferredFailed:
            logStatus = @"GPS延时错误，请确定GPS权限";
            break;
        case kCLErrorDeferredAccuracyTooLow:
            logStatus = @"GPS延时错误，精度太低";
            break;
        case kCLErrorDeferredCanceled:
            logStatus = @"GPS延时错误，延时取消";
            break;
        case kCLErrorDeferredNotUpdatingLocation:
            logStatus = @"GPS延时错误，无更新位置";
            break;
        case kCLErrorDeferredDistanceFiltered:
            logStatus = @"GPS延时错误，距离过滤";
            break;
        default:
            logStatus = @"GPS延时成功";
            break;
    }
    
    self.deferringUpdates = NO;
    
    [self loggingAppStatus:logStatus];

}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    NSString *logStatus = nil;
    switch (status) {
        case kCLAuthorizationStatusNotDetermined:
            logStatus = @"定位权限为选择";
            break;
        case kCLAuthorizationStatusRestricted:
            logStatus = @"定位权限被限制";
            break;
        case kCLAuthorizationStatusDenied:
            logStatus = @"定位权限被拒绝";
            break;
        case kCLAuthorizationStatusAuthorizedAlways:
            logStatus = @"定位权限始终被允许";
            break;
        case kCLAuthorizationStatusAuthorizedWhenInUse:
            logStatus = @"定位权限使用时允许";
            break;
            
        default:
            break;
    }
    [self loggingAppStatus:[NSString stringWithFormat:@"定位权限改变:%@",logStatus]];
}

#pragma mark - Notification Handlers

- (void)handleAppWillTerminate:(NSNotification *)notification {
    [self onKilled];
}

- (void)handleAppDidBecomeActive:(NSNotification *)notification {
    self.inBackground = NO;
    [self onStart];
}

- (void)handleAppDidEnterBackground:(NSNotification *)notification {
    self.inBackground = YES;
}


#pragma mark - Getter and Setter

- (CLLocationManager *)locationManager {
    if (_locationManager == nil) {
        _locationManager = [[CLLocationManager alloc] init];
    }
    return _locationManager;
}

@end
