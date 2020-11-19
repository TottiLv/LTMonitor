//
//  LTMemoryMonitor.h
//  LTMonitor
//
//  Created by lvjianxiong on 2020/11/19.
//

#import <Foundation/Foundation.h>
#import "LTBaseMonitor.h"

NS_ASSUME_NONNULL_BEGIN

@interface LTMemoryMonitor : LTBaseMonitor

+ (instancetype)sharedInstance;


/// 当前设备已使用的内存（MB）
+ (CGFloat)rcDeviceUsedMemory;

/// 当前设备可用内存（MB）
+ (CGFloat)rcDeviceAvailableMemory;

@end

NS_ASSUME_NONNULL_END
