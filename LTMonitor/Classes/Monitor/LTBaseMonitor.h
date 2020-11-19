//
//  LTBaseMonitor.h
//  LTMonitor
//
//  Created by lvjianxiong on 2020/11/19.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LTBaseMonitor : NSObject

@property (nonatomic, copy) void(^rcMonitorNoticeBlock)(CGFloat value);

- (void)rcStartMonitoringWithNoticeBlock:(void(^)(CGFloat value))rcMonitorNoticeBlock;

- (void)rcStopMonitoring;

@end

NS_ASSUME_NONNULL_END
