//
//  LTMonitorWindow.m
//  LTMonitor
//
//  Created by lvjianxiong on 2020/11/19.
//

#import "LTMonitorWindow.h"

@implementation LTMonitorWindow

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    BOOL able = [super pointInside:point withEvent:event];
    if ([_delegate respondsToSelector:@selector(pointInside:withEvent:)]) {
        able = [_delegate pointInside:point withEvent:event];
    }
    
    return able;
}

@end
