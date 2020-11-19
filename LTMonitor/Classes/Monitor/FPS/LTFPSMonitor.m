//
//  LTFPSMonitor.m
//  LTMonitor
//
//  Created by lvjianxiong on 2020/11/19.
//

#import "LTFPSMonitor.h"
#import "LTWeakProxy.h"
#import "LTHooking.h"
#import <sys/time.h>

/**
  参考：
 https://github.com/yehot/YYFPSLabel

 CADisplayLink 默认每秒 60次；
 将 CADisplayLink add 到 mainRunLoop 中；
 使用 CADisplayLink 的 timestamp 属性，在 CADisplayLink 每次 tick 时，记录上一次的 timestamp；
 用 _count 记录 CADisplayLink tick 的执行次数;
 计算此次 tick 时， CADisplayLink 的当前 timestamp 和 _lastTimeStamp 的差值；
 如果差值大于1，fps = _count / delta，计算得出 FPS 数；
 */

@interface LTFPSMonitor ()

@property (nonatomic, strong) CADisplayLink *displayLink;
//@property (nonatomic, strong) NSMutableArray *timestampArray;
/**
 GPUImageView 渲染 FPS 值，在有 GPUImageView 的页面时有值
 */
@property (nonatomic, assign) BOOL gpuImageViewDisplaying;
@property (nonatomic, assign) NSInteger gpuImageFPSValue;



@end

@implementation LTFPSMonitor{
    NSUInteger      _count;        //记录一定时间内总共刷新了多少帧
    NSTimeInterval  _lastTime; //起始记录的时间戳
}

+ (instancetype)sharedInstance {
    static LTFPSMonitor *monitor;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        monitor = [[LTFPSMonitor alloc] init];
    });
    return monitor;
}

- (void)rcStartMonitoringWithNoticeBlock:(void(^)(CGFloat value))rcMonitorNoticeBlock {
    self.rcMonitorNoticeBlock = rcMonitorNoticeBlock;

    _displayLink = [CADisplayLink displayLinkWithTarget:[LTWeakProxy proxyWithTarget:self] selector:@selector(rcEnvokeDisplayLink:)];
    _displayLink.paused = NO;
    [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    
    
    self.gpuImageViewDisplaying = NO;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class cls = NSClassFromString(@"GPUImageView");

        SEL sel1 = NSSelectorFromString(@"createDisplayFramebuffer");
        if (cls && sel1) {
            SEL swizzledSel = [LTHooking swizzledSelectorForSelector:sel1];
            void (^swizzleBlock)(id) = ^void(id obj) {
                ((void (*)(id, SEL))objc_msgSend)(obj, swizzledSel);
                [self gpuImageViewStartDisplay];
            };
            [LTHooking replaceImplementationOfKnownSelector:sel1 onClass:cls withBlock:swizzleBlock swizzledSelector:swizzledSel];
        }

        SEL sel2 = NSSelectorFromString(@"destroyDisplayFramebuffer");
        if (cls && sel2) {
            SEL swizzledSel = [LTHooking swizzledSelectorForSelector:sel2];
            void (^swizzleBlock)(id) = ^void(id obj) {
                ((void (*)(id, SEL))objc_msgSend)(obj, swizzledSel);
                [self gpuImageViewEndDisplay];
            };
            [LTHooking replaceImplementationOfKnownSelector:sel2 onClass:cls withBlock:swizzleBlock swizzledSelector:swizzledSel];
        }

        SEL sel3 = NSSelectorFromString(@"presentFramebuffer");
        if (cls && sel3) {
            SEL swizzledSel = [LTHooking swizzledSelectorForSelector:sel3];
            void (^swizzleBlock)(id) = ^void(id obj) {
                ((void (*)(id, SEL))objc_msgSend)(obj, swizzledSel);
                [self tickGPUImagePresent];
            };
            [LTHooking replaceImplementationOfKnownSelector:sel3 onClass:cls withBlock:swizzleBlock swizzledSelector:swizzledSel];
        }
    });
}

- (void)rcStopMonitoring {
    _displayLink.paused = YES;
    [_displayLink invalidate];
    _displayLink = nil;
}

- (void)rcEnvokeDisplayLink:(CADisplayLink *)displayLink {
    if (_lastTime == 0) {
        _lastTime = displayLink.timestamp;
        return;
    }

    _count++;
    NSTimeInterval delta = displayLink.timestamp - _lastTime; //刷新间隔
    if (delta < 1) return;                             //计算一秒刷新多少帧，小于1s直接返回
    _lastTime = displayLink.timestamp;
    float fps = _count / delta;
    _count = 0;
    if (self.rcMonitorNoticeBlock) {
        self.rcMonitorNoticeBlock((CGFloat)fps);
    }
}
/*
- (void)rcEnvokeDisplayLink:(CADisplayLink *)displayLink {
    if (!_timestampArray) {
        _timestampArray = [NSMutableArray arrayWithCapacity:60];
    }

    if (_timestampArray.count == 60) {
        [_timestampArray removeObject:_timestampArray.firstObject];
    }

    [_timestampArray addObject:@(displayLink.timestamp)];

    __block NSInteger fps = 0;
    //倒叙遍历
    [_timestampArray enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (displayLink.timestamp - [obj doubleValue] < 1) {
            fps++;
        } else {
            *stop = YES;
        }
    }];

    if (self.rcMonitorNoticeBlock) {
        self.rcMonitorNoticeBlock((CGFloat)fps);
    }
}
*/


- (void)gpuImageViewStartDisplay {
    self.gpuImageViewDisplaying = YES;
    self.gpuImageFPSValue = 0.f;
}

- (void)gpuImageViewEndDisplay {
    self.gpuImageViewDisplaying = NO;
    self.gpuImageFPSValue = 0.f;
}

- (void)tickGPUImagePresent {
    static struct timeval t0;
    if (t0.tv_usec == 0) {
        gettimeofday(&t0, NULL);
    }

    struct timeval t1;
    gettimeofday(&t1, NULL);
    double ms = (double)(t1.tv_sec - t0.tv_sec) * 1e3 + (double)(t1.tv_usec - t0.tv_usec) * 1e-3;

    if (ms > 0) {
        self.gpuImageFPSValue = (NSInteger)round(1000 / ms);
    }
    //此处回调
    t0 = t1;
}

@end

