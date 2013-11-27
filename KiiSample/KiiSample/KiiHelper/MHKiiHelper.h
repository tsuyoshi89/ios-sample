//
//  MHKiiHelper.h
//  MHLib
//
//  Created by tsuyoshi on 2013/10/21.
//  Copyright (c) 2013年 Kii. All rights reserved.
//

typedef void (^MHKiiCompletionBlock)(BOOL success);
typedef void (^MHKiiQueryResultBlock)(NSArray *results, KiiQuery *nextQuery, BOOL success);

@protocol MHKiiHelperDelegate <NSObject>
@optional
- (void)startLoadingFor:(NSString *)method;
- (void)endLoadingFor:(NSString *)method error:(NSError *)error;
- (void)onRegisteredWithBlock:(MHKiiCompletionBlock)block;
- (void)onShouldUnregisterWithBlock:(MHKiiCompletionBlock)block;
@end

@interface MHKiiHelper : NSObject

+ (MHKiiHelper *)sharedInstance;
- (void)loginWithBlock:(MHKiiCompletionBlock)block;
- (void)deleteAccountWithBlock:(MHKiiCompletionBlock)block;
- (void)logout;


//facebook callback
+ (BOOL)isLinkFacebook;
- (void)registerWithFacebookAccountWithBlock:(MHKiiCompletionBlock)block;
- (void)linkWithFacebookAccountWithBlock:(MHKiiCompletionBlock)block;
- (void)unLinkWithFacebookAccountWithBlock:(MHKiiCompletionBlock)block;

- (KiiBucket *)bucketOfAppWithName:(NSString *)bucketName;
- (KiiBucket *)bucketOfUserWithNamet:(NSString *)bucketName;

- (NSArray *)excuteQuerySynchronous:(KiiBucket *)bucket query:(KiiQuery *)query withError:(KiiError **)pError;
- (void)excuteQuery:(KiiBucket *)bucket query:(KiiQuery *)query withBlock:(MHKiiQueryResultBlock)block;

+ (NSString *)currentDeviceId;

+ (int)apiCallCount;
+ (void)addApiCallCount:(int)i;

+ (BOOL)serverCodeIs:(NSString *)code inError:(NSError *)error;

+ (void)dumpBucketOfUser:(NSString *)name;

@property (nonatomic, weak) id<MHKiiHelperDelegate> delegate;

@end

