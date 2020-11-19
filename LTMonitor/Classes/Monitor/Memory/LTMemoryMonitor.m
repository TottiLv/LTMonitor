//
//  LTMemoryMonitor.m
//  LTMonitor
//
//  Created by lvjianxiong on 2020/11/19.
//

#import "LTMemoryMonitor.h"

#import "LTWeakProxy.h"
#import <sys/sysctl.h>
#import <mach/mach.h>

/**
 物理内存(RAM)与CPU一样都是系统中最稀少的资源，也是最有可能产生竞争的资源，应用内存与性能直接相关
 APP占用的内存
 获取app内存的API同样可以在Mach层找到，mach_task_basic_info结构体存储了Mach task的内存使用信息，

 struct task_vm_info {
     mach_vm_size_t  virtual_size;       // virtual memory size (bytes)
     integer_t       region_count;       // number of memory regions
     integer_t       page_size;
     mach_vm_size_t  resident_size;      // resident memory size (bytes)
     mach_vm_size_t  resident_size_peak; // peak resident size (bytes)

     mach_vm_size_t  device;
     mach_vm_size_t  device_peak;
     mach_vm_size_t  internal;
     mach_vm_size_t  internal_peak;
     mach_vm_size_t  external;
     mach_vm_size_t  external_peak;
     mach_vm_size_t  reusable;
     mach_vm_size_t  reusable_peak;
     mach_vm_size_t  purgeable_volatile_pmap;
     mach_vm_size_t  purgeable_volatile_resident;
     mach_vm_size_t  purgeable_volatile_virtual;
     mach_vm_size_t  compressed;
     mach_vm_size_t  compressed_peak;
     mach_vm_size_t  compressed_lifetime;

     // added for rev1
     mach_vm_size_t  phys_footprint;

     // added for rev2
     mach_vm_address_t       min_address;
     mach_vm_address_t       max_address;

     // added for rev3
     int64_t ledger_phys_footprint_peak;
     int64_t ledger_purgeable_nonvolatile;
     int64_t ledger_purgeable_novolatile_compressed;
     int64_t ledger_purgeable_volatile;
     int64_t ledger_purgeable_volatile_compressed;
     int64_t ledger_tag_network_nonvolatile;
     int64_t ledger_tag_network_nonvolatile_compressed;
     int64_t ledger_tag_network_volatile;
     int64_t ledger_tag_network_volatile_compressed;
     int64_t ledger_tag_media_footprint;
     int64_t ledger_tag_media_footprint_compressed;
     int64_t ledger_tag_media_nofootprint;
     int64_t ledger_tag_media_nofootprint_compressed;
     int64_t ledger_tag_graphics_footprint;
     int64_t ledger_tag_graphics_footprint_compressed;
     int64_t ledger_tag_graphics_nofootprint;
     int64_t ledger_tag_graphics_nofootprint_compressed;
     int64_t ledger_tag_neural_footprint;
     int64_t ledger_tag_neural_footprint_compressed;
     int64_t ledger_tag_neural_nofootprint;
     int64_t ledger_tag_neural_nofootprint_compressed;

     // added for rev4
     uint64_t limit_bytes_remaining;

     // added for rev5
     integer_t decompressions;
 };
 
 其中resident_size就是应用使用的物理内存大小，virtual_size是虚拟内存大小
 */

@interface LTMemoryMonitor ()

@property (nonatomic, strong) NSTimer *timer;

@end

@implementation LTMemoryMonitor

+ (instancetype)sharedInstance {
    static LTMemoryMonitor *monitor;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        monitor = [[LTMemoryMonitor alloc] init];
    });
    return monitor;
}

- (void)rcStartMonitoringWithNoticeBlock:(void(^)(CGFloat value))rcMonitorNoticeBlock {
    self.rcMonitorNoticeBlock = rcMonitorNoticeBlock;
    
    _timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:[LTWeakProxy proxyWithTarget:self] selector:@selector(rcNoticeMemoryValue) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
}

- (void)rcStopMonitoring {
    [_timer invalidate];
    _timer = nil;
}

- (void)rcNoticeMemoryValue {
    if (self.rcMonitorNoticeBlock) {
        self.rcMonitorNoticeBlock([self rcGetResidentMemory]);
    }
}

/*
///这里需要提到的是有些文章使用的 task_basic_info 结构体，而不是mach_task_basic_info，值得注意的是 Apple 已经不建议再使用 task_basic_info 结构体了
+ (NSUInteger)rcGetResidentMemory
{
    struct task_basic_info t_info;
    mach_msg_type_number_t t_info_count = TASK_BASIC_INFO_COUNT;
    
    int r = task_info(mach_task_self(), TASK_BASIC_INFO, (task_info_t)&t_info, &t_info_count);
    if (r == KERN_SUCCESS)
    {
        return t_info.resident_size / 1024.0 / 1024.0;
    }
    else
    {
        return -1;
    }
*/

/// 获取当前 App Memory 的使用情况
- (NSUInteger)rcGetResidentMemory
{
    struct mach_task_basic_info info;
    mach_msg_type_number_t t_info_count = MACH_TASK_BASIC_INFO_COUNT;
    //与获取 CPU 占用率类似，在调用 task_info API 时，
    //target_task 参数传入的是 mach_task_self()，表示获取当前的 Mach task
    //另外 flavor 参数传的是 MACH_TASK_BASIC_INFO，使用这个类型会返回 mach_task_basic_info 结构体，表示返回 target_task 的基本信息，比如 task 的挂起次数和驻留页面数量
    int r = task_info(mach_task_self(), MACH_TASK_BASIC_INFO, (task_info_t)& info, &t_info_count);
    if (r == KERN_SUCCESS)
    {
        return info.resident_size / 1024 / 1024;
    }
    else
    {
        return -1;
    }
}

+ (CGFloat)rcDeviceUsedMemory {
    size_t length = 0;
    int mib[6] = {0};
    
    int pagesize = 0;
    mib[0] = CTL_HW;
    mib[1] = HW_PAGESIZE;
    length = sizeof(pagesize);
    //sysctl
    if (sysctl(mib, 2, &pagesize, &length, NULL, 0) < 0) {
        return 0;
    }
    
    mach_msg_type_number_t count = HOST_VM_INFO_COUNT;
    
    vm_statistics_data_t vmstat;
    
    if (host_statistics(mach_host_self(), HOST_VM_INFO, (host_info_t)&vmstat, &count) != KERN_SUCCESS) {
        return 0;
    }
    
    int wireMem = vmstat.wire_count * pagesize;
    int activeMem = vmstat.active_count * pagesize;
    
    return (CGFloat)(wireMem + activeMem) / 1024.0 / 1024.0;
}

+ (CGFloat)rcDeviceAvailableMemory {
    vm_statistics64_data_t vmStats;
    mach_msg_type_number_t infoCount = HOST_VM_INFO_COUNT;
    kern_return_t kernReturn = host_statistics(mach_host_self(),
                                               HOST_VM_INFO,
                                               (host_info_t)&vmStats,
                                               &infoCount);
    
    if (kernReturn != KERN_SUCCESS) {
        return NSNotFound;
    }
    
    return (CGFloat)(vm_page_size * (vmStats.free_count + vmStats.inactive_count)  / 1024.0 / 1024.0);
}


@end

