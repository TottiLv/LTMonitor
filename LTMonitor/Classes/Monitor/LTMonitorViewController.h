//
//  LTMonitorViewController.h
//  LTMonitor
//
//  Created by lvjianxiong on 2020/11/19.
//

#import <Foundation/Foundation.h>
#import "LTMonitorWindow.h"

NS_ASSUME_NONNULL_BEGIN

@interface LTMonitorViewController : UIViewController<LTMonitorWindowDelegate>

- (void)setFPSValue:(CGFloat)fpsValue;
- (void)setCPUValue:(CGFloat)cpuValue;
- (void)setMemoryValue:(CGFloat)memoryValue;
- (void)findMenoryLeakWithViewStack:(NSArray *)viewStack retainCycle:(NSArray *)retainCycle;

@end

NS_ASSUME_NONNULL_END

