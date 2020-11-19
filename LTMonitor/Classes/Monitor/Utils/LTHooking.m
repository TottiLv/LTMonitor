//
//  LTHooking.m
//  LTMonitor
//
//  Created by lvjianxiong on 2020/11/19.
//

#import "LTHooking.h"

@implementation LTHooking


+ (SEL)swizzledSelectorForSelector:(SEL)sel {
    return NSSelectorFromString([NSString stringWithFormat:@"_lt_swizzle_%x_%@", arc4random(), NSStringFromSelector(sel)]);
}

+ (BOOL)instanceRespondsButDoesNotImplementSelector:(SEL)sel onClass:(Class)cls {
    if ([cls instancesRespondToSelector:sel]) {
        unsigned int numMethods = 0;
        Method *methods = class_copyMethodList(cls, &numMethods);

        BOOL implementsSelector = NO;
        for (int index = 0; index < numMethods; index++) {
            SEL methodSelector = method_getName(methods[index]);
            if (sel == methodSelector) {
                implementsSelector = YES;
                break;
            }
        }

        free(methods);

        if (!implementsSelector) {
            return YES;
        }
    }

    return NO;
}

+ (void)replaceImplementationOfKnownSelector:(SEL)originalSelector onClass:(Class)cls withBlock:(id)block swizzledSelector:(SEL)swizzledSelector {
    // This method is only intended for swizzling methods that are know to exist on the class.
    // Bail if that isn't the case.
    Method originalMethod = class_getInstanceMethod(cls, originalSelector);
    if (!originalMethod) {
        return;
    }

    IMP implementation = imp_implementationWithBlock(block);
    class_addMethod(cls, swizzledSelector, implementation, method_getTypeEncoding(originalMethod));
    Method newMethod = class_getInstanceMethod(cls, swizzledSelector);
    method_exchangeImplementations(originalMethod, newMethod);
}

+ (void)replaceImplementationOfSelector:(SEL)sel withSelector:(SEL)swizzledSelector forClass:(Class)cls withMethodDescription:(struct objc_method_description)methodDescription implementationBlock:(id)implementationBlock undefinedBlock:(id)undefinedBlock {
    if ([self instanceRespondsButDoesNotImplementSelector:sel onClass:cls]) {
        return;
    }

    IMP implementation = imp_implementationWithBlock((id)([cls instancesRespondToSelector:sel] ? implementationBlock : undefinedBlock));

    Method oldMethod = class_getInstanceMethod(cls, sel);
    if (oldMethod) {
        class_addMethod(cls, swizzledSelector, implementation, methodDescription.types);

        Method newMethod = class_getInstanceMethod(cls, swizzledSelector);

        method_exchangeImplementations(oldMethod, newMethod);
    } else {
        class_addMethod(cls, sel, implementation, methodDescription.types);
    }
}

@end
