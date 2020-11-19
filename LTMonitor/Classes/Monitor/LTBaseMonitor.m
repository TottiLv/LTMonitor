//
//  LTBaseMonitor.m
//  LTMonitor
//
//  Created by lvjianxiong on 2020/11/19.
//

#import "LTBaseMonitor.h"

@implementation LTBaseMonitor

- (void)rcStartMonitoringWithNoticeBlock:(void(^)(CGFloat value))rcMonitorNoticeBlock {
    // do something in subclass
}

- (void)rcStopMonitoring {
    // do something in subclass
}

@end
