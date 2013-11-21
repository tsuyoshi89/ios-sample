//
//  MHJob.h
//
//  Created by Tsuyoshi MIYANO on 13/07/18.
//  Copyright (c) 2013年 Sola Co., Ltd. All rights reserved.
//
#import <UIKit/UIKit.h>

@class MHJob;

typedef void(^MHJobRunBlock)(MHJob *job);
typedef void(^MHJobCompletionBlock)(BOOL success);
typedef void(^MHJobExpirationBlock)(MHJob *job);

typedef enum {
    MHJobState_Idle,
    MHJobState_Running,
    MHJobState_Canceling
} MHJobState;

@interface MHJob : NSObject {
    
}

- (void)run:(MHJobRunBlock)block;
- (void)cancel;
- (void)wait:(double)seconds;

+ (void)enableBackgroundTask:(BOOL)enable;

+ (void)runInMainThread:(void (^)(void))block;
+ (void)runInWorkerThread:(void (^)(void))block;
+ (void)doRunLoop:(double)time;

@property (nonatomic, strong) NSString *name;
@property (nonatomic, assign) BOOL inMainThread;
@property (nonatomic, assign) int threadPriority;
@property (nonatomic, assign) BOOL isBackgroundTask;
@property (nonatomic, strong) MHJobExpirationBlock expirationBlock;
@property (nonatomic, strong) MHJobCompletionBlock completionBlock;

@property (nonatomic, readonly) volatile MHJobState state;

@end



