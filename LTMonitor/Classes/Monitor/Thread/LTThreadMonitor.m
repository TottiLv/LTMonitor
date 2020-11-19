//
//  LTThreadMonitor.m
//  LTMonitor
//
//  Created by lvjianxiong on 2020/11/19.
//

#import "LTThreadMonitor.h"


#import <CrashReporter/CrashReporter.h>
/**
 主线程的runloop默认注册了五个mode：
 kCFRunLoopDefaultMode  Apple的默认Mode，通常主线程是在这个Mode下运行的
 UITrackingRunLoopMode  界面跟踪的Mode，用于ScrollView追踪触摸滑动，保证界面滑动时不受其他的Mode影响
 kCFRunLoopCommonMode   这是一个占位Mode，其实就是Default模式和UI模式之间切换使用
 UIInitializationRunLoopMode    刚启动App时进入的第一个Mode，启动完成后不再适用
 GSEventReceiveRunLoopMode  接受系统事件的内部Mode，通常用不到
 
 其中Apple公开提供的Mode有两个：NSDefaultRunloopMode（kCFRunLoopDefaultMode）,NSRunLoopCommonModes（kCFRunLoopCommonMode）
  主线程监控就是使用NSRunLoopCommonModes
 然后runloop观察者： Runloop Observer有7种状态 (CF-1151.16版本)
 //Run Loop Observer Activities
 typedef CF_OPTIONS(CFOptionFlags, CFRunLoopActivity) {
     kCFRunLoopEntry = (1UL << 0),  //  入口
     kCFRunLoopBeforeTimers = (1UL << 1),   //在处理任何Timer计时器之前
     kCFRunLoopBeforeSources = (1UL << 2),  //在处理任何Source之前
     kCFRunLoopBeforeWaiting = (1UL << 5),  //在等待计时器Timer和源Source之前
     kCFRunLoopAfterWaiting = (1UL << 6),   //在等待源Source和计时器Timer后，同时在被唤醒之前
     kCFRunLoopExit = (1UL << 7),   //runloop的出口
     kCFRunLoopAllActivities = 0x0FFFFFFFU  //runloop的所有状态
 };

 监控线程卡顿整体思路：
 1、 创建一个观察者runloopObserver,用于观察主线程的runloop状态
    同时还要创建一个信号量dispatchSemaphore,用于保证同步操作
 2、 将观察者runloopObserver添加到主线程runloop中观察
 3、 开启一个子线程，并且在子线程中开启一个持续的loop来监控主线程runloop的状态
 4、 如果发现主线程runloop的状态卡在BeforeSources或者AfterWaiting超过88ms时，即表明主线程当前卡顿
*/
@interface LTThreadMonitor(){
    int timeoutCount;
    CFRunLoopObserverRef runLoopObserver;
    dispatch_semaphore_t dispatchSemaphore;
    CFRunLoopActivity runLoopActivity;
}
@property (nonatomic) BOOL isMonitoring;
@end

@implementation LTThreadMonitor

+ (instancetype)sharedInstance {
    static LTThreadMonitor *monitor;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        monitor = [[LTThreadMonitor alloc] init];
    });
    return monitor;
}


/// 注册RunLoop状态观察，并计算是否卡顿
- (void)startMonitor {
    [NSRunLoop currentRunLoop];
    self.isMonitoring = YES;
    if (runLoopObserver) {
        return;
    }
    //注册RunLoop状态观察
    CFRunLoopObserverContext context = {0,(__bridge void*)self, NULL, NULL};
    runLoopObserver = CFRunLoopObserverCreate(kCFAllocatorDefault,
                                              kCFRunLoopAllActivities,
                                              YES,
                                              0,
                                              &runLoopObserverCallBack,
                                              &context);

    CFRunLoopAddObserver(CFRunLoopGetMain(), runLoopObserver, kCFRunLoopCommonModes);
    
    //使用信号量dispatch_semaphore来控制对RunLoop状态判断的节奏，这个可以保证，每个RunLoop状态的判断都会进行。对RunLoop状态的判断，专门在另外一个线程做判断（保障同步）
    dispatchSemaphore = dispatch_semaphore_create(0);
    /*
    需要注意的是，对卡顿的判断是通过kCFRunLoopBeforeSources或者kCFRunLoopBeforeWaiting这两个状态开始后，信号量+1，这时候信号量>0,dispatch_semaphore_wait不会阻塞，返回0，进行下一个while循环，如果此时还没有进入下一个RunLoop状态，此时信号量=0，dispatch_semaphore_wait就会在这里阻塞，到了设定的超时时间，dispatch_semaphore_wait的返回值>0，这时候就会进行耗时的判断。
    可以自己设定超时时间和超过多少次算卡顿，这里设置超过250ms
    */
    //在子线程监控时长，开启一个持续的loop用来进行监控
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        while (YES) {
            //假定连续5次超时50ms认为卡顿(当然也包括了单词超时250ms)
            long semaphoreWait = dispatch_semaphore_wait(self->dispatchSemaphore, dispatch_time(DISPATCH_TIME_NOW, 50 * NSEC_PER_MSEC));
            if (semaphoreWait != 0) {
                if (!self->runLoopObserver) {
                    self->timeoutCount = 0;
                    self->dispatchSemaphore = 0;
                    self->runLoopActivity = 0;
                    return;
                }
                //两个runloop的状态，kCFRunLoopBeforeSources和kCFRunLoopAfterWaiting这两个状态区间时间能够检测到是否卡顿
                if (self->runLoopActivity == kCFRunLoopBeforeSources || self->runLoopActivity == kCFRunLoopAfterWaiting) {
                    if (++self->timeoutCount < 5) {
                        continue;
                    }
                    //发现卡顿
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                        //这里获取卡顿的调用栈
                        PLCrashReporterConfig *config = [[PLCrashReporterConfig alloc] initWithSignalHandlerType:PLCrashReporterSignalHandlerTypeBSD
                                                                                           symbolicationStrategy:PLCrashReporterSymbolicationStrategyAll];
                        PLCrashReporter *crashReporter = [[PLCrashReporter alloc] initWithConfiguration:config];

                        NSData *data = [crashReporter generateLiveReport];
                        PLCrashReport *reporter = [[PLCrashReport alloc] initWithData:data error:NULL];
                        NSString *report = [PLCrashReportTextFormatter stringValueForCrashReport:reporter
                                                                                  withTextFormat:PLCrashReportTextFormatiOS];
                        NSLog(@"------------\n%@\n------------", report);
                    });
                }
            }
            self->timeoutCount = 0;
        }
    });
}


- (void)stopMonitor {
    self.isMonitoring = NO;
    if (!runLoopObserver) {
        return;
    }
    CFRunLoopRemoveObserver(CFRunLoopGetMain(), runLoopObserver, kCFRunLoopCommonModes);
    CFRelease(runLoopObserver);
    runLoopObserver = NULL;
}


/// Runloop状态观察回调
/// @param observer observerRef
/// @param activity 状态值
/// @param info 信息
static void runLoopObserverCallBack(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info){
    LTThreadMonitor *threadMonitor = (__bridge LTThreadMonitor*)info;
    threadMonitor->runLoopActivity = activity;
    dispatch_semaphore_t semaphore = threadMonitor->dispatchSemaphore;
    dispatch_semaphore_signal(semaphore);
}

@end
