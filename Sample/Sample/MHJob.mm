//
//  sola_job.cpp
//
//  Created by Tsuyoshi MIYANO on 13/05/25.
//  Copyright (c) 2013年 Sola Co., Ltd. All rights reserved.
//

#include <list>

#import "MHJob.h"


#pragma mark - NSCondition
@interface NSCondition (Sola)
-(void)signalAndWait:(double)waitSecond;
@end

class MHConditionScopeLock {
public:
    MHConditionScopeLock(NSCondition *cond) : _cond(cond)
    {[_cond lock];}
    ~MHConditionScopeLock()
    {[_cond signal];[_cond unlock];}
private:
    NSCondition *_cond;
};
#define CONDITION_SCOPE_LOCK(cond) MHConditionScopeLock _scope_lock_(cond);

#pragma mark - MHJob


@interface MHJobManager : NSObject {
    
}

@property (nonatomic, readonly, assign) BOOL inBackground;
@end

@implementation MHJobManager {
    NSMutableArray *_backgroundJobs;
    UIBackgroundTaskIdentifier _backgroundTaskIdentifier;
    NSCondition *_cond;
}

- (id)init {
    self = [super init];
    if (self) {
        _backgroundJobs = [NSMutableArray array];
        _backgroundTaskIdentifier = UIBackgroundTaskInvalid;
        _inBackground = FALSE;
        _cond = [[NSCondition alloc] init];
    }
    return self;
}

- (void)dealloc {
    if (_backgroundTaskIdentifier != UIBackgroundTaskInvalid) {
        [[UIApplication sharedApplication] endBackgroundTask:_backgroundTaskIdentifier];
        _backgroundTaskIdentifier = UIBackgroundTaskInvalid;
    }
}

- (void (^)(void))expirationBlock {
    return ^{
        NSLog(@"expiration handler was called. background jobs count:%d", _backgroundJobs.count);
        NSArray *jobs = [_backgroundJobs mutableCopy];
        for (MHJob *job in jobs) {
            if (job.expirationBlock) {
                job.expirationBlock(job);
            }
        }
    };
}

- (void)addBackgroundJob:(MHJob *)job {
    CONDITION_SCOPE_LOCK(_cond);
    [_backgroundJobs addObject:job];
    if (_backgroundTaskIdentifier == UIBackgroundTaskInvalid) {
        _backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:[self expirationBlock]];
        NSLog(@"beginBackgroundTask(%d)", _backgroundTaskIdentifier);
    }
}

- (void)removeBackgroundJob:(MHJob *)job {
    CONDITION_SCOPE_LOCK(_cond);
    NSParameterAssert([_backgroundJobs containsObject:job]);
    [_backgroundJobs removeObject:job];
    if (_backgroundJobs.count == 0) {
        if (_backgroundTaskIdentifier != UIBackgroundTaskInvalid) {
            [[UIApplication sharedApplication] endBackgroundTask:_backgroundTaskIdentifier];
            NSLog(@"endBackgroundTask(1):%d", _backgroundTaskIdentifier);
            _backgroundTaskIdentifier = UIBackgroundTaskInvalid;
        }
    }
}

@end

static MHJobManager *sJobManager;

@implementation MHJob {
    NSCondition *_cond;
}

+ (void)enableBackgroundTask:(BOOL)enable {
    if (enable) {
        if (!sJobManager) {
            sJobManager = [[MHJobManager alloc] init];
        }
    } else {
        if (sJobManager) {
            sJobManager = nil;
        }
    }
}

- (id)init {
    self = [super init];
    if (self) {
        _threadPriority = DISPATCH_QUEUE_PRIORITY_DEFAULT;
        _state = MHJobState_Idle;
        _cond = [[NSCondition alloc] init];
    }
    return self;
};

- (void)dealloc {
    NSLog(@"dealloc job");
}
            
- (void)run:(MHJobRunBlock)runBlock {
    CONDITION_SCOPE_LOCK(_cond);

    if (_state != MHJobState_Idle) {
        if (self.completionBlock) {
            dispatch_async(dispatch_get_main_queue(),^{
                self.completionBlock(FALSE);
            });
        }
        return;
    }
    
    _state = MHJobState_Running;
    
    BOOL isBackgroundTask = self.isBackgroundTask;
    if (isBackgroundTask) {
        NSAssert(!self.inMainThread, @"BackgroundTask must run in worker thread!");
        [sJobManager addBackgroundJob:self];
    }
    
    void (^block)(void) = ^{
        NSLog(@"enter job block");
        runBlock(self);
        BOOL success = (_state == MHJobState_Running);
        {
            CONDITION_SCOPE_LOCK(_cond);
            _state = MHJobState_Idle;
        }
        
        dispatch_async(dispatch_get_main_queue(),^{
            if (self.completionBlock) {
                self.completionBlock(success);
            }
        });
        
        if (isBackgroundTask) {
            //End the task so the system knows that you are done with what you need to perform
            [sJobManager removeBackgroundJob:self];
        }
    };
    
    if (self.inMainThread) {
        //main thread for ui.... synchronously...
        dispatch_async(dispatch_get_main_queue(), block);
    } else {
        dispatch_async(dispatch_get_global_queue(_threadPriority, 0), block);
    }
}

- (void)cancel {
    CONDITION_SCOPE_LOCK(_cond);
    if (_state == MHJobState_Running) {
        _state = MHJobState_Canceling;
        while (_state != MHJobState_Idle) {
            [_cond signalAndWait:0.1];
        }
    }
}

- (void)wait:(double)seconds {
    CONDITION_SCOPE_LOCK(_cond);
    //if (_state == MHJobState_Running) {
        [_cond signalAndWait:seconds];
//}
}

+ (void)doRunLoop:(double)time {
    NSAssert([NSThread isMainThread], @"doRunLoop must be called in main thread");
    [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:time]];
}

+ (void)runInMainThread:(void (^)(void))block {
    if (sJobManager.inBackground) {
        NSLog(@"job will run in main thread when application is background , intended code?");
    }
    dispatch_async(dispatch_get_main_queue(),block);
}

+ (void)runInWorkerThread:(void (^)(void))block {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),block);
}

@end

/////////////////////////////
@implementation NSCondition (Sola)

-(void)signalAndWait:(double)waitSecond {
    [self signal];
    [self waitUntilDate:[NSDate dateWithTimeIntervalSinceNow:waitSecond]];
}

@end

