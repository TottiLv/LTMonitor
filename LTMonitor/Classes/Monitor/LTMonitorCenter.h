//
//  LTMonitorCenter.h
//  LTMonitor
//
//  Created by lvjianxiong on 2020/11/19.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LTMonitorCenter : NSObject

+ (instancetype)defaultCenter;

- (void)rcMonitorEnable;
- (void)rcMonitorDisable;

@end

NS_ASSUME_NONNULL_END
