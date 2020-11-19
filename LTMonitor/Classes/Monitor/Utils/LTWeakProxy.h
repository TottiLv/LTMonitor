//
//  LTWeakProxy.h
//  LTMonitor
//
//  Created by lvjianxiong on 2020/11/19.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LTWeakProxy : NSObject

/**
 A proxy used to hold a weak object.
 It can be used to avoid retain cycles, such as the target in NSTimer or CADisplayLink.
 
 sample code:
 
 @implementation MyView {
 NSTimer *_timer;
 }
 
 - (void)initTimer {
 RCWeakProxy *proxy = [RCWeakProxy proxyWithTarget:self];
 _timer = [NSTimer timerWithTimeInterval:0.1 target:proxy selector:@selector(tick:) userInfo:nil repeats:YES];
 }
 
 */


/**
 The proxy target.
 */
@property (nullable, nonatomic, weak, readonly) id target;

/**
 Creates a new weak proxy for target.
 
 @param target Target object.
 
 @return A new proxy object.
 */
- (instancetype)initWithTarget:(id)target;

/**
 Creates a new weak proxy for target.
 
 @param target Target object.
 
 @return A new proxy object.
 */
+ (instancetype)proxyWithTarget:(id)target;

@end

NS_ASSUME_NONNULL_END
