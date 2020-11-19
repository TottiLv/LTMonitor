//
//  LTThreadMonitor.h
//  LTMonitor
//
//  Created by lvjianxiong on 2020/11/19.
//

#import <Foundation/Foundation.h>
#import "LTBaseMonitor.h"

NS_ASSUME_NONNULL_BEGIN
/**
 使用方式：在AppDelegate中，添加
 [[LTThreadMonitor sharedInstance] startMonitor];
 */
@interface LTThreadMonitor : LTBaseMonitor

+ (instancetype)sharedInstance;

- (void)startMonitor;
- (void)stopMonitor;

@end

NS_ASSUME_NONNULL_END
