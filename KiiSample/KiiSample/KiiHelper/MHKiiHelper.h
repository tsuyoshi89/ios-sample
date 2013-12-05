//
//  MHKiiHelper.h
//  MHLib
//
//  Created by tsuyoshi on 2013/10/21.
//  Copyright (c) 2013年 Kii. All rights reserved.
//

#import "KiiObject+MHKiiHelper.h"

typedef void (^MHKiiCompletionBlock)(BOOL success);

typedef enum {
    MHKiiLoadingLogin = 1,
    MHKiiLoadingDeleteAccount,
    MHKiiLoadingSave,
    MHKiiLoadingDelete,
    MHKiiLoadingQuery,
    MHKiiLoadingRefresh,
    MHKiiLoadingUpload,
    MHKiiLoadingDownload,
} MHKiiLoading;

@protocol MHKiiHelperDelegate <NSObject>
@optional
- (void)kiiStartLoadingFor:(MHKiiLoading)name count:(int)loadingCount;
- (void)kiiEndLoadingFor:(MHKiiLoading)name error:(NSError *)error count:(int)loadingCount;
- (BOOL)kiiInitializeAccount;//call in worker thread
- (BOOL)kiiFinalizeAccount;//call in worker thead
@end

@interface MHKiiHelper : NSObject

+ (MHKiiHelper *)sharedInstance;

- (void)startLoadingFor:(MHKiiLoading)name;
- (void)endLoadingFor:(MHKiiLoading)name error:(NSError *)error;

- (void)loginWithBlock:(void (^)(BOOL, BOOL))block;
- (void)logout;
- (void)deleteAccountWithBlock:(MHKiiCompletionBlock)block;
- (void)pushInstall:(NSData *)deviceToken;
- (void)pushUninstall;


//facebook callback
+ (BOOL)isLinkFacebook;
- (void)registerWithFacebookAccountWithBlock:(MHKiiCompletionBlock)block;
- (void)linkWithFacebookAccountWithBlock:(MHKiiCompletionBlock)block;
- (void)unLinkWithFacebookAccountWithBlock:(MHKiiCompletionBlock)block;

- (KiiBucket *)bucketOfAppWithName:(NSString *)bucketName;
- (KiiBucket *)bucketOfUserWithNamet:(NSString *)bucketName;


+ (NSString *)currentDeviceId;

+ (int)apiCallCount;
+ (void)addApiCallCount:(int)i;

+ (BOOL)serverCodeIs:(NSString *)code inError:(NSError *)error;

+ (void)dumpBucketOfUser:(NSString *)name;

@property (nonatomic, weak) id<MHKiiHelperDelegate> delegate;

@end

