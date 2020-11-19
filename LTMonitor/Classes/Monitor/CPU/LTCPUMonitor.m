//
//  LTCPUMonitor.m
//  LTMonitor
//
//  Created by lvjianxiong on 2020/11/19.
//

#import "LTCPUMonitor.h"

#import "LTWeakProxy.h"
#import <mach/mach.h>
@interface LTCPUMonitor ()
/**
 线程CPU是调度和分配的基本单位，而应用作为进程运行时，包含了多个不同的线程
 如果我们能知道app里所有线程占用CPU的情况，也就能知道整个APP的CPU占用率。
 Mach层中thread_basic_info结构体中发现了我们想要的东西
 cpu_usage 对应线程的CPU使用率

 struct thread_basic_info {
     time_value_t    user_time;      //user run time
     time_value_t    system_time;    //system run time
     integer_t       cpu_usage;      //scaled cpu usage percentage
     policy_t        policy;         // scheduling policy in effect
     integer_t       run_state;      // run state (see below)
     integer_t       flags;          // various flags (see below)
     integer_t       suspend_count;  // suspend count for thread
     integer_t       sleep_time;     // number of seconds that thread  has been sleeping
 };
 获取任务中的所有thread
 iOS内核提供了task_threads
 
 API调用获取指定task的线程列表，然后从thread_info中获取thread_basic_info，将thread_basic_info中的cpu_usage进行叠加即可；
 通过定时器，间隔一定时间获取内存使用情况即可
 */
@property (nonatomic, strong) NSTimer *timer;

@end

@implementation LTCPUMonitor

+ (instancetype)sharedInstance {
    static LTCPUMonitor *monitor;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        monitor = [[LTCPUMonitor alloc] init];
    });
    return monitor;
}

- (void)rcStartMonitoringWithNoticeBlock:(void(^)(CGFloat value))rcMonitorNoticeBlock{
    self.rcMonitorNoticeBlock = rcMonitorNoticeBlock;
    
    _timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:[LTWeakProxy proxyWithTarget:self] selector:@selector(rcNoticeCPUValue) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
}

- (void)rcStopMonitoring {
    [_timer invalidate];
    _timer = nil;
}

- (void)rcNoticeCPUValue {
    if (self.rcMonitorNoticeBlock) {
        self.rcMonitorNoticeBlock([self rcUsedCpu]);
    }
}

- (CGFloat)rcUsedCpu {
    kern_return_t           kr;
    thread_array_t          thread_list;
    mach_msg_type_number_t  thread_count;
    thread_info_data_t      thinfo;
    mach_msg_type_number_t  thread_info_count;
    thread_basic_info_t     basic_info_th;

    
    // get threads in the task  参数：mach_task_self 表示获取当前的Mach task
    kr = task_threads(mach_task_self(), &thread_list, &thread_count);
    if (kr != KERN_SUCCESS) {
        return -1;
    }
    long tot_sec = 0;
    long tot_usec = 0;
    float tot_cpu = 0;
    for (int i = 0; i < thread_count; i++)
    {
        thread_info_count = THREAD_INFO_MAX;
        //获取thread_info时，flavor参数传递的是THREAD_BASIC_INFO使用这个类型会返回线程的基本信息，定义在 thread_basic_info_t 结构体，包含了用户和系统的运行时间，运行状态和调度优先级
        kr = thread_info(thread_list[i], THREAD_BASIC_INFO,(thread_info_t)thinfo, &thread_info_count);
        if (kr != KERN_SUCCESS) {
            return -1;
        }
        
        basic_info_th = (thread_basic_info_t)thinfo;

        if (!(basic_info_th->flags & TH_FLAGS_IDLE))
        {
            tot_sec += basic_info_th->user_time.seconds + basic_info_th->system_time.seconds;
            tot_usec += basic_info_th->system_time.microseconds + basic_info_th->system_time.microseconds;
            tot_cpu += basic_info_th->cpu_usage / (float)TH_USAGE_SCALE;
            
        }
    }
    
    tot_cpu = tot_cpu * 100.0;
    
    //注意方法最后要调用 vm_deallocate，防止出现内存泄漏
    vm_deallocate(mach_task_self(), (vm_offset_t)thread_list, thread_count * sizeof(thread_t));
    return tot_cpu;
}

@end

