//
//  LTHooking.h
//  LTMonitor
//
//  Created by lvjianxiong on 2020/11/19.
//

#import <Foundation/Foundation.h>
#import <objc/message.h>
#import <objc/runtime.h>

NS_ASSUME_NONNULL_BEGIN

@interface LTHooking : NSObject

+ (SEL)swizzledSelectorForSelector:(SEL)selector;
+ (BOOL)instanceRespondsButDoesNotImplementSelector:(SEL)selector onClass:(Class)cls;
+ (void)replaceImplementationOfKnownSelector:(SEL)originalSelector onClass:(Class) class withBlock:(id)block swizzledSelector:(SEL)swizzledSelector;
+ (void)replaceImplementationOfSelector:(SEL)selector withSelector:(SEL)swizzledSelector forClass:(Class)cls withMethodDescription:(struct objc_method_description)methodDescription implementationBlock:(id)implementationBlock undefinedBlock:(id)undefinedBlock;

@end

NS_ASSUME_NONNULL_END

