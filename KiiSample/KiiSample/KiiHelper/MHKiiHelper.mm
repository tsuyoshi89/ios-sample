//
//  MHKiiHelper.cpp
//  MHLib
//
//  Created by tsuyoshi on 2013/10/21.
//  Copyright (c) 2013年 Kii. All rights reserved.
//

#include "MHKiiHelper.h"
#include "MHJob.h"
#include "KiiObject+MHLib.h"


static NSString *KiiPrefAccessToken = @"MHAccessToken";
static NSString *KiiPrefFacebookToken = @"MHFacebookToken";
static NSString *KiiPrefFacebookExpire = @"MHFacebookExpire";
static NSString *KiiPrefKeyApiCallCount = @"MHKiiApiCount";

@interface MHKiiHelper ()
+ (KiiUser *)authenticateWithTokenSynchronous:(NSString *)accessToken andError:(KiiError **)error;
@end

@implementation MHKiiHelper {
    MHKiiCompletionBlock _facebookHandler;
}

+ (MHKiiHelper *)sharedInstance{
    static MHKiiHelper *instance;
    if (!instance) {
        instance = [[MHKiiHelper alloc] init];
    }
    return instance;
}


- (void)pushInstall:(NSString *)deviceToken {
    NSData *token = [deviceToken dataUsingEncoding:NSUTF8StringEncoding];
    NSAssert([KiiUser loggedIn], @"user must be logined before");

    //Hold deviceToken into Kii shared instance
    [Kii setAPNSDeviceToken:token];
    
    [KiiPushInstallation installWithBlock:^(KiiPushInstallation *installation, NSError *error) {
        if(error == nil) {
            NSLog(@"Push installed!");
        } else {
            NSLog(@"Error installing: %@", error);
        }
    }];
}

- (void)pushUninstall {
    [KiiPushInstallation uninstallWithBlock:^(KiiPushInstallation *installation, NSError *error) {
        if(error == nil) {
            NSLog(@"Push uninstalled!");
        } else {
            NSLog(@"Error push uninstalling: %@", error);
        }
    }];
}

- (void)enablePushNotification {
    // Enable push with DevelopmentMode

#ifdef DEBUG
    [Kii enableAPNSWithDevelopmentMode:YES
                  andNotificationTypes:(UIRemoteNotificationTypeBadge |
                                        UIRemoteNotificationTypeSound |
                                        UIRemoteNotificationTypeAlert)];
#else
    //Enable push with ProductionMode
    [Kii enableAPNSWithDevelopmentMode:NO
                  andNotificationTypes:(UIRemoteNotificationTypeBadge |
                                        UIRemoteNotificationTypeSound |
                                        UIRemoteNotificationTypeAlert)];
#endif
}

- (void)startLoadingFor:(NSString *)method {
    if ([_delegate respondsToSelector:@selector(startLoadingFor:)]) {
        [_delegate startLoadingFor:method];
    }
}

- (void)endLoadingFor:(NSString *)method error:(NSError *)error  {
    if ([_delegate respondsToSelector:@selector(endLoadingFor:error:)]) {
        [_delegate endLoadingFor:method error:error];
    }
}

- (void)loginWithBlock:(MHKiiCompletionBlock)block {
    static NSString *sTemporaryToken;
    static NSString *sMethod = @"login";
    [self startLoadingFor:sMethod];
    
    // if the user is logged in
    if (![KiiUser loggedIn]) {
        //load token
        NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
        NSString *accessToken = [ud stringForKey:KiiPrefAccessToken];
        if (accessToken) {
            [MHJob runInWorkerThread:^{
                KiiError *error;
                [MHKiiHelper authenticateWithTokenSynchronous:accessToken andError:&error];
                [MHJob runInMainThread:^{
                    if (error == nil && !sTemporaryToken) {
                        //first login
                        sTemporaryToken = accessToken;
                        [self enablePushNotification];
                    }
                    if (block) {
                        block(error == nil);
                    }
                    [self endLoadingFor:sMethod error:error];
                }];
            }];
            return;
        }
    }
    
    [MHJob runInMainThread:^{
        BOOL ok = [KiiUser loggedIn];
        if (ok) {
            NSString *accessToken = [[KiiUser currentUser] accessToken];
            if (![sTemporaryToken isEqualToString:accessToken]) {
                //first login for current user
                NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
                [ud setObject:accessToken forKey:KiiPrefAccessToken];
                [ud synchronize];
                sTemporaryToken = accessToken;
                [self enablePushNotification];
            }
        }
        if (block) {
            block(ok);
        }
        NSError *error = ok ? nil : [[NSError alloc] init];
        [self endLoadingFor:sMethod error:error];
    }];
}

- (void)deleteAccountWithBlock:(MHKiiCompletionBlock)block {
    static NSString *sMethod = @"deleteAccount";
    
    [self startLoadingFor:sMethod];

    void (^responseBlock)(KiiUser *, NSError *) =  ^(KiiUser *user, NSError *error) {
        [MHJob runInMainThread:^{
            if (block) {
                block(error == nil);
            }
            [self endLoadingFor:sMethod error:error];
        }];
    };

    KiiUser *user = [KiiUser currentUser];
    if (!user) {
        NSLog(@"no current user!");
        responseBlock(nil, [[NSError alloc] init]);
        return;
    }
    
    void (^deleteBlock)(void) = ^{
        [self unLinkWithFacebookAccountWithBlock:^(BOOL success) {
            if (success) {
                [user deleteWithBlock:responseBlock];
            } else {
                responseBlock(user, [[NSError alloc] init]);
            }
        }];
    };
    
    
    if ([_delegate respondsToSelector:@selector(onShouldUnregisterWithBlock:)]) {
        [_delegate onShouldUnregisterWithBlock:^(BOOL ok) {
            if (!ok) {
                responseBlock(user, [[NSError alloc] init]);
                return;
            }
            deleteBlock();
        }];
    } else {
        deleteBlock();
    }
}

- (void)logout {
    KiiUser *user = [KiiUser currentUser];
    if (user) {
        [KiiUser logOut];
    }
}

- (KiiBucket *)bucketOfAppWithName:(NSString *)bucketName {
    KiiBucket *bucket = [Kii bucketWithName:bucketName];
    NSAssert(bucket, @"no app bucket with named:%@", bucketName);
    return bucket;
}

- (KiiBucket *)bucketOfUserWithNamet:(NSString *)bucketName {
    KiiUser *user = [KiiUser currentUser];
    NSAssert(user, @"no user is loggin");
    KiiBucket *bucket = [user bucketWithName:bucketName];
    NSAssert(bucket, @"no user bucket with named:%@", bucketName);
    return bucket;
}

+ (KiiUser *)authenticateWithTokenSynchronous:(NSString *)accessToken andError:(KiiError **)error {
    NSParameterAssert(accessToken.length > 0);
    NSParameterAssert(error);
    [self addApiCallCount:1];
    KiiUser *user = [KiiUser authenticateWithTokenSynchronous:accessToken andError:error];
    if (*error != nil) {
        NSLog(@"Error: authenticate:%@", *error);
    }
    return user;
}

- (NSArray *)excuteQuerySynchronous:(KiiBucket *)bucket query:(KiiQuery *)query withError:(KiiError **)pError {
    NSParameterAssert(bucket);
    NSParameterAssert(query);
    int count = 0;
    KiiError *error;
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:256];
    while (query) {
        KiiQuery *nextQuery;
        count++;
        NSArray *results = [bucket executeQuerySynchronous:query withError:&error andNext:&nextQuery];
        if (error == nil) {
            [array addObjectsFromArray:results];
        } else {
            NSAssert(FALSE, @"Error: queryr:%@", error);
            [array removeAllObjects];
            break;
        }
        query = nextQuery;
    }
    if (pError) {
        *pError = error;
    }
    [MHKiiHelper addApiCallCount:count];
    return array;
}

- (void)excuteQuery:(KiiBucket *)bucket query:(KiiQuery *)query withBlock:(MHKiiQueryResultBlock)block {
    NSParameterAssert(block);
    [bucket executeQuery:query withBlock: ^(KiiQuery *query, KiiBucket *bucket, NSArray *results, KiiQuery *nextQuery, NSError *error) {
        NSAssert(error == nil, @"Error: query:%@", error);
        block(results, nextQuery, error == nil);
        [MHKiiHelper addApiCallCount:1];
    }];
}

+ (NSString *)currentDeviceId {
    return [[UIDevice currentDevice].identifierForVendor UUIDString];
}

+ (int)apiCallCount {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    int count = [ud integerForKey:KiiPrefKeyApiCallCount];
    return count;
}

+ (void)addApiCallCount:(int)i {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    int count = [ud integerForKey:KiiPrefKeyApiCallCount];
    [ud setInteger:(count + i) forKey:KiiPrefKeyApiCallCount];
    [ud synchronize];
}

- (void)didFacebookFinished:(KiiUser *)user
               usingNetwork:(KiiSocialNetworkName)network
                  withError:(NSError *)error {
    BOOL ok = (error == nil);
    if (!ok) {
        NSLog(@"facebook handler error:%@", error);
    }
    if (_facebookHandler != nil) {
        if (!ok) {//through not linked
            if (error.code == 319 || [MHKiiHelper serverCodeIs:@"USER_NOT_LINKED" inError:error]) {
                ok = TRUE;
            }
            if ([MHKiiHelper serverCodeIs:@"FACEBOOK_USER_ALREADY_LINKED" inError:error]) {
                ok = TRUE;
            }
        }
        _facebookHandler(ok);
        _facebookHandler = nil;
    }
}

- (void)registerWithFacebookAccountWithBlock:(MHKiiCompletionBlock)block {
    NSParameterAssert(block);

    if (_facebookHandler != nil) {
        [MHJob runInMainThread:^{
            NSLog(@"previous facebook process is not done");
            block(FALSE);
        }];
        return;
    }

    // Initialize the Social Network Connector.
    [KiiSocialConnect setupNetwork:kiiSCNFacebook
                           withKey:YOUR_FACEBOOK_APP_ID
                         andSecret:nil
                        andOptions:nil];
    [MHKiiHelper addApiCallCount:1];
    // Login with the Facebook Account.
    [KiiSocialConnect logIn:kiiSCNFacebook
               usingOptions:nil
               withDelegate:self
                andCallback:@selector(didFacebookFinished:usingNetwork:withError:)];
    NSAssert(_facebookHandler == nil, @"unexpected handler");
    id<MHKiiHelperDelegate> delegate = _delegate;
    _facebookHandler = ^(BOOL registered) {
        if (registered) {
            if ([delegate respondsToSelector:@selector(onRegisteredWithBlock:)]) {
                [delegate onRegisteredWithBlock:^(BOOL inited) {
                    if (inited) {
                        //success sign up  by face book account
                        NSString *ftoken = [KiiSocialConnect getAccessTokenForNetwork:kiiSCNFacebook];
                        NSDate *fexpire = [KiiSocialConnect getAccessTokenExpiresForNetwork:kiiSCNFacebook];
                        NSLog(@"facebook access token:%@", ftoken);;
                        NSLog(@"facebook token expires:%@",fexpire);
                        if (ftoken) {
                            NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
                            [ud setObject:ftoken forKey:KiiPrefFacebookToken];
                            [ud setObject:fexpire forKey:KiiPrefFacebookExpire];
                            [ud synchronize];
                        }
                    } else {
                        [KiiSocialConnect unLinkCurrentUserWithNetwork:kiiSCNFacebook
                                                          withDelegate:nil
                                                           andCallback:nil];
                        [self deleteAccountWithBlock:nil];
                    }
                    if (block) {
                        block(inited);
                    }
                }];
                return;
            }
        }
        if (block) {
            block(registered);
        }
    };
}

- (void)linkWithFacebookAccountWithBlock:(MHKiiCompletionBlock)block {
    if (_facebookHandler != nil) {
        [MHJob runInMainThread:^{
            NSLog(@"previous facebook process is not done");
            if (block) {
                block(FALSE);
            }
        }];
        return;
    }

    // Initialize the Social Network Connector.
    [KiiSocialConnect setupNetwork:kiiSCNFacebook
                           withKey:YOUR_FACEBOOK_APP_ID
                         andSecret:nil
                        andOptions:nil];
    // Link to the Facebook Account.
    [MHKiiHelper addApiCallCount:1];
    [KiiSocialConnect linkCurrentUserWithNetwork:kiiSCNFacebook
                                    usingOptions:nil
                                    withDelegate:self
                                     andCallback:@selector(didFacebookFinished:usingNetwork:withError:)];
    NSAssert(_facebookHandler == nil, @"unexpected handler");
    _facebookHandler = ^(BOOL success) {
        if (success) {//success link face book account
            NSString *ftoken = [KiiSocialConnect getAccessTokenForNetwork:kiiSCNFacebook];
            NSDate *fexpire = [KiiSocialConnect getAccessTokenExpiresForNetwork:kiiSCNFacebook];
            NSLog(@"facebook:token:%@, date:%@", ftoken, fexpire);
            if (ftoken) {
                NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
                [ud setObject:ftoken forKey:KiiPrefFacebookToken];
                [ud setObject:fexpire forKey:KiiPrefFacebookExpire];
                [ud synchronize];
            }
        }
        if (block) {
            block(success);
        }
    };
}

- (void)unLinkWithFacebookAccountWithBlock:(MHKiiCompletionBlock)block {
    
    if (_facebookHandler != nil) {
        [MHJob runInMainThread:^{
            NSLog(@"previous facebook process is not done");
            if (block) {
                block(FALSE);
            }
        }];
        return;
    }
    
    // Initialize the Social Network Connector.
    [KiiSocialConnect setupNetwork:kiiSCNFacebook
                           withKey:YOUR_FACEBOOK_APP_ID
                         andSecret:nil
                        andOptions:nil];
    // Link to the Facebook Account.
    [MHKiiHelper addApiCallCount:1];
    [KiiSocialConnect unLinkCurrentUserWithNetwork:kiiSCNFacebook
                                      withDelegate:self
                                       andCallback:@selector(didFacebookFinished:usingNetwork:withError:)];
    _facebookHandler = ^(BOOL success) {
        if (success) {//success unlink face book account
            NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
            [ud removeObjectForKey:KiiPrefFacebookToken];
            [ud removeObjectForKey:KiiPrefFacebookExpire];
            [ud synchronize];
        }
        if (block) {
            block(success);
        }
    };
}

+ (BOOL)isLinkFacebook {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSString *ftoken = [ud objectForKey:KiiPrefFacebookToken];
    NSDate *fexpire = [ud objectForKey:KiiPrefFacebookExpire];
    NSLog(@"facebook:token:%@, expire:%@", ftoken, fexpire);
    return (ftoken != nil);
}


+ (BOOL)serverCodeIs:(NSString *)code inError:(NSError *)error {
    NSDictionary *userInfo = [error userInfo];
    NSString *server_code = [userInfo objectForKey:@"server_code"];
    return [code isEqualToString:server_code];
}

#pragma mark - debug methods


+ (void)dumpBucketOfUser:(NSString *)name {
#ifdef DEBUG
    KiiUser *user = [KiiUser currentUser];
    NSLog(@"user:mail:%@, username:%@, displayName:%@, uuid:%@",user.email, user.username, user.displayName, user.uuid);
    if (name.length != 0) {
        KiiError *error;
        KiiBucket *bucket = [user bucketWithName:name];
        KiiQuery *query = [[KiiQuery alloc] init];
        NSArray *results = [[MHKiiHelper sharedInstance] excuteQuerySynchronous:bucket query:query withError:&error];
        if (error) {
            NSLog(@"error query:%@", query);
        }
        for (KiiObject *obj in results) {
            NSLog(@"%@", [obj dictionaryValue]);
        }
    }
#endif
}

@end


