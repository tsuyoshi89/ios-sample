//
//  MHKiiHelper.cpp
//  MHLib
//
//  Created by tsuyoshi on 2013/10/21.
//  Copyright (c) 2013年 Kii. All rights reserved.
//

#include <FacebookSDK/FacebookSDK.h>

#include "MHKiiHelper.h"
#include "MHJob.h"
#include "KiiObject+MHKiiHelper.h"

static NSString *KiiHelperBucketName = @"mh_helper";
static NSString *KiiPrefVersion = @"mh_version";
static NSString *KiiPrefAccessToken = @"mh_token";
static NSString *KiiPrefFacebookToken = @"fb_token";
static NSString *KiiPrefFacebookExpire = @"fb_expire";
static NSString *KiiPrefKeyApiCallCount = @"mh_count";

@interface MHKiiHelper ()
+ (KiiUser *)authenticateWithTokenSynchronous:(NSString *)accessToken andError:(KiiError **)error;
@end

@implementation MHKiiHelper {
    MHKiiCompletionBlock _facebookHandler;
    int _loadingCount;
}

+ (MHKiiHelper *)sharedInstance{
    static MHKiiHelper *instance;
    if (!instance) {
        instance = [[MHKiiHelper alloc] init];
    }
    return instance;
}

// add below code to your AppDelegate.m
//- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken
//{
//    NSLog(@"Success to get token: %@", deviceToken);
//    [[MHKiiHelper sharedInstance] pushInstall:deviceToken]
//}
//
//- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError*)error
//{
//    NSLog(@"Failed to get token, error: %@", error);
//}
//

- (void)pushInstall:(NSData *)deviceToken {
    NSAssert([KiiUser loggedIn], @"user must be logined before");

    //Hold deviceToken into Kii shared instance
    [Kii setAPNSDeviceToken:deviceToken];
    
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

- (void)startLoadingFor:(MHKiiLoading)name {
    _loadingCount++;
    if ([_delegate respondsToSelector:@selector(kiiStartLoadingFor:count:)]) {
        [_delegate kiiStartLoadingFor:name count:_loadingCount];
    }
}

- (void)endLoadingFor:(MHKiiLoading)name error:(NSError *)error  {
    NSParameterAssert(_loadingCount > 0);
    if ([_delegate respondsToSelector:@selector(kiiEndLoadingFor:error:count:)]) {
        [_delegate kiiEndLoadingFor:name error:error count:_loadingCount];
    }
    _loadingCount--;
}

- (void)setupAccount:(void (^)(BOOL))block {
    [MHJob runInWorkerThread:^{
        KiiUser *user = [KiiUser currentUser];
        NSAssert(user, @"user must be loggined!");
        NSString *token = [user accessToken];
        NSAssert(token, @"unexpected null token");
        
        NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
        NSString *oldToken = [ud objectForKey:KiiPrefAccessToken];
        NSString *version;
        if ([token isEqualToString:oldToken]) {
            version = [ud objectForKey:KiiPrefVersion];
        }
        
        BOOL initialized = (version && [version intValue] > 0);
        
        if (!initialized) {
            KiiBucket *bucket = [user bucketWithName:KiiHelperBucketName];
            KiiQuery *query = [KiiQuery queryWithClause:nil];
            query.limit = 1;
            KiiError *error;
            NSArray *array = [bucket _excuteQuerySynchronous:query withError:&error];
            if (array.count > 0) {
                KiiObject *object = [array lastObject];
                version = [object getStringForKey:KiiPrefVersion];
            }
            initialized = (version && [version intValue] > 0);
            
            
            if (!initialized) {
                initialized = TRUE;
                if ([_delegate respondsToSelector:@selector(kiiInitializeAccount)]) {
                    initialized = [_delegate kiiInitializeAccount];
                }
                
                if (initialized) {
                    NSString *latestVersion = @"1";
                    KiiObject *object = [bucket createObject];
                    [object setStringValue:latestVersion forKey:KiiPrefVersion];
                    KiiError *error;
                    [object _saveSynchronous:&error];
                    initialized = (error == nil);
                    if (initialized) {
                        version = latestVersion;
                    }
                }
            }
            
            if (initialized) {
                [ud setObject:token forKey:KiiPrefAccessToken];
                [ud setObject:version forKey:KiiPrefVersion];
                
                NSDictionary *dict = [KiiSocialConnect getAccessTokenDictionaryForNetwork:kiiSCNFacebook];
                NSString *ftoken = [dict objectForKey:@"access_token"];//[KiiSocialConnect getAccessTokenForNetwork:kiiSCNFacebook];
                NSDate *fexpire = [dict objectForKey:@"access_token_expires"];//[KiiSocialConnect getAccessTokenExpiresForNetwork:kiiSCNFacebook];
                NSLog(@"facebook access token:%@", ftoken);;
                NSLog(@"facebook token expires:%@",fexpire);
                
                if (ftoken) {
                    [ud setObject:ftoken forKey:KiiPrefFacebookToken];
                    [ud setObject:fexpire forKey:KiiPrefFacebookExpire];
                }
                [ud synchronize];
            }
        }
        
        [MHJob runInMainThread:^{
            if (block) {
                block(initialized);
            }
        }];
    }];
}

static NSString *sTemporaryToken;

- (void)loginWithBlock:(void (^)(BOOL, BOOL))block {
    static MHKiiLoading sName = MHKiiLoadingLogin;
    [self startLoadingFor:sName];
    
    void (^setupBlock)(BOOL) = ^(BOOL success) {
        BOOL firstTime = FALSE;
        if (success) {
            NSString *token = [[KiiUser currentUser] accessToken];
            firstTime = ![sTemporaryToken isEqualToString:token];
            if (firstTime) {
                //first login for current user
                sTemporaryToken = token;
                [self enablePushNotification];
            }
        } else {
            sTemporaryToken = nil;
        }
        if (block) {
            block(success, firstTime);
        }
        NSError *error = success ? nil : [NSError errorWithDomain:@"mh" code:0 userInfo:@{@"description":@"failed to setup account"}];
        [self endLoadingFor:sName error:error];
    };

    // if the user is not logged in, check saved access token;
    if (![KiiUser loggedIn]) {
        sTemporaryToken = nil;
        //load token
        NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
        NSString *accessToken = [ud stringForKey:KiiPrefAccessToken];
        if (accessToken) {
            [MHJob runInWorkerThread:^{
                KiiError *error;
                [MHKiiHelper authenticateWithTokenSynchronous:accessToken andError:&error];
                BOOL success = (error == nil);
                if (success) {
                    [self setupAccount:setupBlock];
                } else {
                    [MHJob runInMainThread:^{
                        setupBlock(FALSE);
                    }];
                }
            }];
            return;
        }
    }
    
    BOOL success = [KiiUser loggedIn];
    if (success) {
        [self setupAccount:setupBlock];
    } else {
        [MHJob runInMainThread:^{
            setupBlock(FALSE);
        }];
    }
}

- (void)logout {
    [KiiUser logOut];
    [self clearAuthInfo];
}

- (void)clearAuthInfo {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [ud removeObjectForKey:KiiPrefAccessToken];
    [ud removeObjectForKey:KiiPrefVersion];
    [ud removeObjectForKey:KiiPrefFacebookToken];
    [ud removeObjectForKey:KiiPrefFacebookExpire];
    [ud synchronize];
    sTemporaryToken = nil;
}

- (void)deleteAccountWithBlock:(MHKiiCompletionBlock)block {
    [MHKiiHelper _deleteAccountWithBlock:block];
}

+ (void)_deleteAccountWithBlock:(MHKiiCompletionBlock)block {
    static MHKiiLoading sName = MHKiiLoadingDeleteAccount;
    
    [[MHKiiHelper sharedInstance] startLoadingFor:sName];

    void (^responseBlock)(NSError *) = ^(NSError *error) {
        [MHJob runInMainThread:^{
            BOOL success = (error == nil);
            if (block) {
                block(success);
            }
            [[MHKiiHelper sharedInstance] endLoadingFor:sName error:error];
        }];
    };

    KiiUser *user = [KiiUser currentUser];
    if (!user) {
        NSError *error = [NSError errorWithDomain:@"mh" code:0 userInfo:@{@"description":@"no current uesr"}];
        responseBlock(error);
        return;
    }
    
    id<MHKiiHelperDelegate> delegate = [MHKiiHelper sharedInstance].delegate;

    [MHJob runInWorkerThread:^{
        KiiError *error;
        BOOL success = FALSE;
        BOOL finalized = TRUE;
        if ([delegate respondsToSelector:@selector(kiiFinalizeAccount)]) {
            finalized = [delegate kiiFinalizeAccount];
        }
        if (finalized) {
            [MHKiiHelper addApiCallCount:1];
            [user deleteSynchronous:&error];
            success = (error == nil);
            NSAssert(success, @"user delete:%@", error);
            if (success) {
                [[MHKiiHelper sharedInstance] clearAuthInfo];
            }
        } else {
            error = [KiiError errorWithDomain:@"mh" code:0 userInfo:@{@"description":@"failed to finalize account"}];
        }
        responseBlock(error);
    }];
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

#ifdef YOUR_FACEBOOK_APP_ID
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
            if (error.code == 318 || [MHKiiHelper serverCodeIs:@"FACEBOOK_USER_ALREADY_LINKED" inError:error]) {
                ok = TRUE;
            }
        }
        _facebookHandler(ok);
        _facebookHandler = nil;
    }
}


// add [URL types]-[URL identifier]:bundle id, URL [Schemes]:fbxxx (xxx=YOUR_FACEBOOK_APP_ID) to info.plist
// add below code to your AppDelegate.m and
//
//- (BOOL)application:(UIApplication *)application
//            openURL:(NSURL *)url
//  sourceApplication:(NSString *)sourceApplication
//         annotation:(id)annotation {
//    return [KiiSocialConnect handleOpenURL:url];
//}

- (void)registerWithFacebookAccountWithBlock:(MHKiiCompletionBlock)block {
    NSParameterAssert(block);

    if (_facebookHandler != nil) {
        [MHJob runInMainThread:^{
            NSLog(@"other facebook process is running.");
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
    [MHKiiHelper addApiCallCount:1];
    [KiiSocialConnect logIn:kiiSCNFacebook
               usingOptions:nil
               withDelegate:self
                andCallback:@selector(didFacebookFinished:usingNetwork:withError:)];
    NSAssert(_facebookHandler == nil, @"unexpected handler");
    
    _facebookHandler = ^(BOOL success) {
        if (!success) {
            if (block) {
                block(success);
            }
            return;
        }
        [[MHKiiHelper sharedInstance] setupAccount:^(BOOL success) {
            if (block) {
                block(success);
            }
        }];
    };
}

- (void)linkWithFacebookAccountWithBlock:(MHKiiCompletionBlock)block {
    if (_facebookHandler != nil) {
        [MHJob runInMainThread:^{
            NSLog(@"other facebook process is running.");
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
    //NSDictionary *permissions = @{@"publish_actions" : @YES,                                  @"email" : @YES};
    //NSDictionary *params = @{@"permissions": permissions};
    [MHKiiHelper addApiCallCount:1];
    [KiiSocialConnect linkCurrentUserWithNetwork:kiiSCNFacebook
                                    usingOptions:nil
                                    withDelegate:self
                                     andCallback:@selector(didFacebookFinished:usingNetwork:withError:)];
    NSAssert(_facebookHandler == nil, @"unexpected handler");
    _facebookHandler = ^(BOOL success) {
        if (success) {//success link face book account
            NSDictionary *dict = [KiiSocialConnect getAccessTokenDictionaryForNetwork:kiiSCNFacebook];
            NSString *ftoken = [dict objectForKey:@"access_token"];//[KiiSocialConnect getAccessTokenForNetwork:kiiSCNFacebook];
            NSDate *fexpire = [dict objectForKey:@"access_token_expires"];//[KiiSocialConnect getAccessTokenExpiresForNetwork:kiiSCNFacebook];
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
            NSLog(@"other facebook process is running.");
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

- (void)registerFBAccessToken {
    
    FBSession *session = [[FBSession alloc] init];
    [FBSession setActiveSession:session];
    
    [FBSession.activeSession openWithCompletionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
        NSLog(@"open session:%@, status:%d error:%@", session, status, error);
       

        NSString *strParam = [[NSString alloc] initWithFormat:@"SELECT uid, name, birthday_date, pic_square, pic_big FROM user WHERE uid IN (SELECT uid2 FROM friend WHERE uid1 = me())"];
        // ロケールに "ja_JP" を設定
        NSDictionary *params = @{strParam: @"q",
                                 @"ja_JP": @"locale"};
        
        // FQL を投げる
        [FBRequestConnection startWithGraphPath:@"/fql"
                                     parameters:params
                                     HTTPMethod:@"GET"
                              completionHandler:^( FBRequestConnection *connection, id result, NSError *error) {
                                  if (error) {
                                      NSLog(@"Error: %@", [error localizedDescription]);
                                  } else {
                                      NSLog(@"Result: %@", result);
                                      // "data" セクションに全フレンド情報が入っている
                                      //NSDictionary *arrFriends = [result objectForKey:@"data"];
                                  }
                              }];
        
    }];
#if 0
    NSString *fbToken = @"abc";// [KiiSocialConnect getAccessTokenForNetwork:kiiSCNFacebook];
    NSDate *fbExpire = [KiiSocialConnect getAccessTokenExpiresForNetwork:kiiSCNFacebook];

    FBAccessTokenData *tokenData = [FBAccessTokenData createTokenFromString:fbToken
                                 permissions:nil//@[@"publish_actions"]
                              expirationDate:fbExpire
                                   loginType:FBSessionLoginTypeFacebookApplication
                                 refreshDate:nil];
    NSLog(@"tokenData:%@", tokenData);
    
    FBSessionTokenCachingStrategy *strategy = [[FBSessionTokenCachingStrategy alloc] initWithUserDefaultTokenInformationKeyName:KiiPrefFacebookToken];
    [strategy cacheFBAccessTokenData:tokenData];
    NSLog(@"strategy:%@", strategy);


    
    FBSession *session = [[FBSession alloc] initWithAppID:@"fb" YOUR_FACEBOOK_APP_ID
                                              permissions:@[@"publish_actions"]
                                          defaultAudience:FBSessionDefaultAudienceFriends
                                          urlSchemeSuffix:nil
                                       tokenCacheStrategy:nil];//strategy];
    NSLog(@"session:%@", session);

    [FBSession setActiveSession:session];
    [session openFromAccessTokenData:tokenData completionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
        NSLog(@"open session:%@, status:%d error:%@", session, status, error);

        [self postWithText:@"I'm loggin!"
                 ImageName:nil
                       URL:@"http://miyano-harikyu.jp/sola/devlog"
                   Caption:@"test caption"
                      Name:@"Kii Sample App"
            andDescription:@"this is test description"];
    }];
#endif
}

-(void) postWithText: (NSString*) message
              ImageName: (NSString*) image
                    URL: (NSString*) url
                Caption: (NSString*) caption
                   Name: (NSString*) name
         andDescription: (NSString*) description
{
    
    NSDictionary* params = @{//url, @"link",
                             name: @"name",
                             //caption: @"caption",
                             //description: @"description",
                             message: @"message",
                             //@"http://example.com/water.jpg": @"picture",
                             //UIImagePNGRepresentation([UIImage imageNamed: image]): @"picture",
                             };
    
    if ([FBSession.activeSession.permissions indexOfObject:@"publish_actions"] == NSNotFound) {
        NSLog(@"No permissions found in session, ask for it");
        [FBSession.activeSession requestNewPublishPermissions: @[@"publish_actions"]
                                              defaultAudience: FBSessionDefaultAudienceFriends
                                            completionHandler: ^(FBSession *session, NSError *error) {
                                                NSLog(@"request new publish permissions!:%@", error);
                                                if (!error) {
                                                    // If permissions granted and not already posting then publish the story
                                                    //if (!m_postingInProgress)
                                                    [self postToWall: params];
                                                }
                                            }];
    } else {
        // If permissions present and not already posting then publish the story
        //if (!m_postingInProgress)
        [self postToWall: params];
    }

}

- (void)postToWall:(NSDictionary*) params {
    //m_postingInProgress = YES; //for not allowing multiple hits
    
#if 1
    [FBRequestConnection startForMeWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        NSLog(@"for me:%@ error:%@", result, error);
        
    }];
#else
    [FBRequestConnection startWithGraphPath:@"me/feed"
                                 parameters:params
                                 HTTPMethod:@"POST"
                          completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                              NSLog(@"facebook graph post:%@", error);
                              if (error) {
                                  //showing an alert for failure
                                  UIAlertView *alertView = [[UIAlertView alloc]
                                                            initWithTitle:@"Post Failed"
                                                            message:error.localizedDescription
                                                            delegate:nil
                                                            cancelButtonTitle:@"OK"
                                                            otherButtonTitles:nil];
                                  [alertView show];
                              }
                              //m_postingInProgress = NO;
                          }];
#endif
}

#endif /* YOUR_FACEBOOK_ID */

#pragma mark - debug methods

+ (void)dumpBucketOfUser:(NSString *)name {
#ifdef DEBUG
    KiiUser *user = [KiiUser currentUser];
    NSLog(@"user:mail:%@, username:%@, displayName:%@, uuid:%@",user.email, user.username, user.displayName, user.uuid);
    if (name.length != 0) {
        KiiError *error;
        KiiBucket *bucket = [user bucketWithName:name];
        KiiQuery *query = [[KiiQuery alloc] init];
        NSArray *results = [bucket _excuteQuerySynchronous:query withError:&error];
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


