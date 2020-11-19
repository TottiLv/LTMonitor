//
//  LTMonitorWindow.h
//  LTMonitor
//
//  Created by lvjianxiong on 2020/11/19.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol LTMonitorWindowDelegate <NSObject>

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event;

@end

@interface LTMonitorWindow : UIWindow

@property (nonatomic, weak) id<LTMonitorWindowDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
