//
//  KiiManager.m
//  KiiSample
//
//  Created by tsuyoshi on 2013/12/05.
//  Copyright (c) 2013年 Tsuyoshi Miyano. All rights reserved.
//

#import "MHKiiHelper.h"

#import "KiiManager.h"


@interface KiiManager () <MHKiiHelperDelegate>

@end


@implementation KiiManager {
    NSString *_bucketName;
}

+ (KiiManager *)sharedInstance {
    static KiiManager *instance;
    if (instance == nil) {
        instance = [[KiiManager alloc] init];
        [MHKiiHelper sharedInstance].delegate = instance;
    }
    return instance;
}

- (void)setBucketName:(NSString *)bucketName {
    _bucketName = bucketName;
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [ud setObject:bucketName forKey:@"bucketName"];
    [ud synchronize];
    
}
- (NSString *)bucketName {
    if (_bucketName.length == 0) {
        NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
        NSString *bucketName = [ud objectForKey:@"bucketName"];
        _bucketName = bucketName;
        if (_bucketName.length == 0) {
            _bucketName = @"sample";
        }
    }
    return _bucketName;
}

- (KiiBucket *)bucket {
    KiiBucket *ret;
    if (self.userMode) {
        ret = [[KiiUser currentUser] bucketWithName:self.bucketName];
    } else {
        ret = [Kii bucketWithName:self.bucketName];
    }
    return ret;
}

- (void)kiiStartLoadingFor:(MHKiiLoading)name count:(int)loadingCount {
    NSString *message;
    switch (name) {
        case MHKiiLoadingLogin:
            message = @"ログイン中...";
            break;
        case MHKiiLoadingDeleteAccount:
            message = @"アカウント削除中...";
            break;
        case MHKiiLoadingSave:
            message = @"保存中...";
            break;
        case MHKiiLoadingDelete:
            message = @"削除中...";
            break;
        case MHKiiLoadingRefresh:
            message = @"ロード中...";
            break;
        case MHKiiLoadingDownload:
            message = @"ダウンロード中...";
            break;
        case MHKiiLoadingQuery:
            message = @"検索中...";
            break;
        case MHKiiLoadingUpload:
            message = @"アップロード中...";
            break;
        default:
            break;
    }
    if (message) {
        [KTLoader showLoader:message];
    }
};

- (void)kiiEndLoadingFor:(MHKiiLoading)name error:(NSError *)error count:(int)loadingCount {
    if (error) {
        [KTLoader showLoader:[NSString stringWithFormat:@"Error: %@", error]
                    animated:YES withIndicator:KTLoaderIndicatorError
             andHideInterval:(loadingCount <= 1) ? KTLoaderDurationAuto : KTLoaderDurationIndefinite];
        NSLog(@"error:%@", error);
    } else if (loadingCount <= 1){
        [KTLoader hideLoader];
    }
}

- (void)hideLoaderWithError:(NSError *)error {
    [KTLoader showLoader:[NSString stringWithFormat:@"Error: %@", error]
                animated:YES withIndicator:KTLoaderIndicatorError andHideInterval:KTLoaderDurationAuto];
    NSLog(@"error:%@", error);
}

- (void)newObject {
    [KTLoader showLoader:@"create object..."];
    KiiObject *object = [self.bucket createObject];
    [object _saveWithBlock:^(BOOL success) {
        if (success) {
            self.uuid =  object.uuid;
            NSLog(@"uri:%@", [object objectURI]);
            self.object = object;
        }
    }];
}

- (void)deleteObject:(NSString *)uuid {
    if (uuid.length != 36) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Save error" message:@"まずオブジェクトを作成してください"
                                                       delegate:nil cancelButtonTitle:@"閉じる" otherButtonTitles:nil, nil];
        [alert show];
        return;
    }
    KiiObject *object;
    
    if (self.userMode) {
        object = [KiiObject userObjectWithUUID:uuid withBucketName:self.bucketName];
    } else {
        object = [KiiObject objectWithUUID:uuid withBucketName:self.bucketName];
    }
    
    [object _deleteWithBlock:^(BOOL success) {
        self.object = nil;
    }];
}

- (void)refreshObject:(NSString *)uuid {
    if (uuid.length != 36) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Save error" message:@"まずオブジェクトを作成してください"
                                                       delegate:nil cancelButtonTitle:@"閉じる" otherButtonTitles:nil, nil];
        [alert show];
        return;
    }
    KiiObject *object;
    if (self.userMode) {
        object = [KiiObject userObjectWithUUID:uuid withBucketName:self.bucketName];
    } else {
        object = [KiiObject objectWithUUID:uuid withBucketName:self.bucketName];
    }
    
    [object _refreshWithBlock:^(BOOL success) {
        self.object = object;
    }];
}

- (void)save:(NSDictionary *)values {

    KiiObject *object = [KiiObject objectWithURI:self.object.objectURI];
    for (NSString *key in [values keyEnumerator]) {
        if ([[values objectForKey:key] isEqual:[self.object getObjectForKey:key]]) {
            continue;
        } else {
            [object setObject:[values objectForKey:key] forKey:key];
        }
    }
    [object _saveWithBlock:^(BOOL success) {
        [self refreshObject:object.uuid];
    }];
}

- (void)saveAll:(NSDictionary *)values widthDeleteKeys:(NSArray *)deleteKeys {
    KiiObject *object = [KiiObject objectWithURI:self.object.objectURI];
    
    [object _refreshWithBlock:^(BOOL success) {
        if (success) {
            for (NSString *key in [values keyEnumerator]) {
                [object setObject:[values objectForKey:key] forKey:key];
            }
            for (NSString *key in deleteKeys) {
                [object removeObjectForKey:key];
            }
            
            [object _saveAllFieldsWithBlock:^(BOOL success) {
                [self refreshObject:object.uuid];
            }];
        } else {
            self.object = object;
        }
    }];
}

- (void)uploadData:(NSData *)data {
    KiiObject *object = [KiiObject objectWithURI:self.object.objectURI];
    [object _uploadBody:data withBlock:^(BOOL success) {
        if (success) {
            [self refreshObject:object.uuid];
        }
    }];
}

- (void)downloadData:(void (^)(NSData *))block {
    KiiObject *object = [KiiObject objectWithURI:self.object.objectURI];
    [object _downloadBody:YES withBlock:^(BOOL success, NSData *data) {
        if (block) {
            block(data);
        }
    }];
}
@end
