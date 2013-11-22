//
//  MHCloudHelper.h
//  Sample
//
//  Created by tsuyoshi on 2013/11/22.
//  Copyright (c) 2013年 Tsuyoshi Miyano. All rights reserved.
//


typedef void (^MHCloudCompletionBlock)(BOOL success);

@class MHCloudHelper;

@protocol MHCloudStateObserver
@required
- (void)cloudAvailabilityChanged:(BOOL)available tokenChanged:(BOOL)tokenChanged;
@end

@interface MHCloudHelper : NSObject

+ (MHCloudHelper *)sharedInstance;
+ (BOOL)isSignIn;

- (BOOL)cloudIsAvailable;
- (BOOL)isCloudURL:(NSURL *)url;

- (NSURL *)cloudURLByAppendingPathComponent:(NSString *)path;
- (NSURL *)documentsURLByAppendingPathComponent:(NSString *)path;

- (void)addStateObserver:(id<MHCloudStateObserver>)observer;
- (void)removeStateObserver:(id<MHCloudStateObserver>)observer;

+ (BOOL)fileExistsAtURL:(NSURL *)url;

+ (NSDate *)modificationDateAtURL:(NSURL *)url;

+ (void)removeItemAtURL:(NSURL *)url completion:(void (^)(BOOL success))completion;

+ (void)copyToCloud:(NSURL *)srcURL cloudURL:(NSURL *)cloudURL completion:(MHCloudCompletionBlock)block;
+ (void)copyFromCloud:(NSURL *)srcURL cloudURL:(NSURL *)cloudURL overwrite:(BOOL)overwrite completion:(MHCloudCompletionBlock)block;

+ (void)moveToCloud:(NSURL *)srcURL cloudURL:(NSURL *)cloudURL completion:(MHCloudCompletionBlock)block;
+ (void)moveFromCloud:(NSURL *)srcURL cloudURL:(NSURL *)cloudURL completion:(MHCloudCompletionBlock)block;

// create new file
+ (void)createItemAtURL:(NSURL *)url data:(NSData *)data completion:(MHCloudCompletionBlock)block;

+ (void)writeDataAtURL:(NSURL *)url data:(NSData *)data append:(BOOL)append completion:(MHCloudCompletionBlock)block;


@property (nonatomic, readonly) NSURL *containerURL;

@end

