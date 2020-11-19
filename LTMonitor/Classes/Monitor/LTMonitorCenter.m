//
//  LTMonitorCenter.m
//  LTMonitor
//
//  Created by lvjianxiong on 2020/11/19.
//

#import "LTMonitorCenter.h"
#import <LTMonitor/LTCPUMonitor.h>
#import <LTMonitor/LTMemoryMonitor.h>
#import <LTMonitor/LTFPSMonitor.h>
#import "LTMonitorWindow.h"
#import "LTMonitorViewController.h"

@interface LTMonitorCenter ()

@property (nonatomic, strong) LTMonitorWindow *window;
@property (nonatomic, strong) LTMonitorViewController *viewController;

@end

@implementation LTMonitorCenter


+ (instancetype)defaultCenter {
    static LTMonitorCenter *center;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        center = [[LTMonitorCenter alloc] init];
    });
    return center;
}

- (instancetype)init{
    self = [super init];
    if (self) {
        _viewController = [[LTMonitorViewController alloc] init];
        _window = [[LTMonitorWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        _window.rootViewController = _viewController;
        _window.windowLevel = UIWindowLevelAlert + 1000;
        _window.delegate = _viewController;
        _window.hidden = YES;
    }
    return self;
}


- (void)rcMonitorEnable{
#ifdef DEBUG
    if (_window.hidden == NO) {
        return;
    }
    
    _window.hidden = NO;
#endif
//只有在DEBUG情况下，才显示，非DEBUG情况下可能需要获取内容，然后上传服务器
    __weak typeof(self) weakSelf = self;
    //FPS
    [[LTFPSMonitor sharedInstance] rcStartMonitoringWithNoticeBlock:^(CGFloat value) {
#ifdef DEBUG
        [weakSelf.viewController setFPSValue:value];
#endif
    }];
    //CPU
    [[LTCPUMonitor sharedInstance] rcStartMonitoringWithNoticeBlock:^(CGFloat value) {
#ifdef DEBUG
        [weakSelf.viewController setCPUValue:value];
#endif
    }];
    //内存监控
    [[LTMemoryMonitor sharedInstance] rcStartMonitoringWithNoticeBlock:^(CGFloat value) {
#ifdef DEBUG
        [weakSelf.viewController setMemoryValue:value];
#endif
    }];

}

- (void)rcMonitorDisable{
#ifdef DEBUG
    if (_window.hidden == YES) {
        return;
    }
    _window.hidden = YES;
#endif
    
    [[LTFPSMonitor sharedInstance] rcStopMonitoring];
    [[LTCPUMonitor sharedInstance] rcStopMonitoring];
    [[LTMemoryMonitor sharedInstance] rcStopMonitoring];
}

@end
