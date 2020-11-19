//
//  LTFPSMonitor.h
//  LTMonitor
//
//  Created by lvjianxiong on 2020/11/19.
//

#import <Foundation/Foundation.h>
#import "LTBaseMonitor.h"
NS_ASSUME_NONNULL_BEGIN

@interface LTFPSMonitor : LTBaseMonitor


@property (nonatomic, assign, readonly) BOOL gpuImageViewDisplaying;
@property (nonatomic, assign, readonly) NSInteger gpuImageFPSValue;

+ (instancetype)sharedInstance;

@end


NS_ASSUME_NONNULL_END
