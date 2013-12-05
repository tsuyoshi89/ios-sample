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

- (BOOL)kiiInitializeAccount {
    return YES;
}

- (void)newObject {
    [KTLoader showLoader:@"create object..."];
    KiiObject *object = [self.bucket createObject];
    [object _saveWithBlock:^(BOOL success) {
        if (success) {
            self.uuid =  object.uuid;
            NSLog(@"uri:%@", [object objectURI]);
            self.object = object;
            [self.delegate kiiManager:self didChangeObject:object];
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
        [self.delegate kiiManager:self didChangeObject:nil];
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
        [self.delegate kiiManager:self didChangeObject:object];
    }];
}

- (void)save:(NSDictionary *)values {

    [self.object _set:values widthDeleteKeys:nil];
    [self.object _saveWithBlock:^(BOOL success) {
        [self.delegate kiiManager:self didChangeObject:self.object];
    }];
}

- (void)saveAll:(NSDictionary *)values widthDeleteKeys:(NSArray *)deleteKeys {
    [self.object _set:values widthDeleteKeys:deleteKeys];
    [self.object _saveAllFieldsWithBlock:^(BOOL success) {
        [self.delegate kiiManager:self didChangeObject:self.object];
    }];
}

- (void)uploadData:(NSData *)data {
    [self.object _uploadBody:data withBlock:^(BOOL success) {
        [self.delegate kiiManager:self didChangeObject:self.object];
    }];
}

- (void)downloadData {
    [self.object _downloadBody:YES withBlock:^(BOOL success, NSData *data) {
        [self.delegate kiiManager:self didChangeObject:self.object];
    }];
}

- (void)deleteBody {
    [self.object _deleteBody:^(BOOL success) {
        [self.delegate kiiManager:self didChangeObject:self.object];
    }];
}
@end
