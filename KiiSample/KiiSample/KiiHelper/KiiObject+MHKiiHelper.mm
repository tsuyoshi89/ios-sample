//
//  KiiObject+MHLib.m
//  MHLib
//
//  Created by tsuyoshi on 2013/11/19.
//
//


#import "MHJob.h"
#import "MHKiiHelper.h"
#import "MHFileHelper.h"
#import "MHFoundation.h"
#import "KiiObject+MHKiiHelper.h"

#ifdef MHAssert
#undef NSAssert
#define NSAssert MHAssert
#endif

#define MHLib_OBJC_CAST(type, obj) ([(obj) isKindOfClass:[type class]] ? ((type *)(obj)) : nil)
#define MHClassName(obj) NSStringFromClass([(obj) class])

static NSString *userDomain = @"kiicloud://users/";
static NSString *KeyBody = @"mh_body";

@implementation KiiUser (MHKiiHelper)
+ (NSString *)getObjectURI:(NSString *)uuid {
    return [userDomain stringByAppendingString:uuid];
}
@end

@implementation KiiObject (MHKiiHelper)
+ (KiiObject *)objectWithUUID:(NSString *)uuid withBucketName:(NSString *)bucketName {
    NSString *uri = [NSString stringWithFormat:@"kiicloud://buckets/%@/objects/%@", bucketName, uuid];
    KiiObject *ret = [KiiObject objectWithURI:uri];
    NSAssert(ret, @"invalid uri?:%@", uri);
    return ret;
}

+ (KiiObject *)userObjectWithUUID:(NSString *)uuid withBucketName:(NSString *)bucketName {
    KiiObject *ret;
    KiiUser *user = [KiiUser currentUser];
    if (user) {
        NSString *uri = [NSString stringWithFormat:@"%@/buckets/%@/objects/%@", user.objectURI, bucketName, uuid];
        ret = [KiiObject objectWithURI:uri];
        NSAssert(ret, @"invalid uri?:%@", uri);
    } else {
        NSLog(@"must be login!");
    }
    return ret;
}

- (int)getIntForkey:(NSString *)key {
    id obj = [self getObjectForKey:key];
    if (obj) {
        NSAssert(MHLib_OBJC_CAST(NSNumber, obj), @"unexpected object type:%@", MHClassName(obj));
    } else {
        //NSLog(@"no object for:%@", key);
    }
    return [obj intValue];
}

- (NSString *)getStringForKey:(NSString *)key {
    id obj = [self getObjectForKey:key];
    if (obj) {
        NSAssert(MHLib_OBJC_CAST(NSString, obj), @"unexpected object type:%@", MHClassName(obj));
    } else {
        //NSLog(@"no object for:%@", key);
    }
    return obj;
}

- (BOOL)getBoolForKey:(NSString *)key {
    id obj = [self getObjectForKey:key];
    if (obj) {
        NSAssert(MHLib_OBJC_CAST(NSNumber, obj), @"unexpected object type:%@", MHClassName(obj));
    } else {
        //NSLog(@"no object for:%@", key);
    }
    return [obj boolValue];
}

- (double)getDoubleForKey:(NSString *)key {
    id obj = [self getObjectForKey:key];
    if (obj) {
        NSAssert(MHLib_OBJC_CAST(NSNumber, obj), @"unexpected object type:%@", MHClassName(obj));
    } else {
        //NSLog(@"no object for:%@", key);
    }
    return [obj doubleValue];
}

- (BOOL)setIntValue:(int)value forKey:(NSString *)key {
    BOOL ok = [self setObject:[NSNumber numberWithInt:value] forKey:key];
    NSAssert(ok, @"Failed to set object:key:%@", key);
    return ok;
}

- (BOOL)setDoubleValue:(double)value forKey:(NSString *)key {
    BOOL ok = [self setObject:[NSNumber numberWithDouble:value] forKey:key];
    NSAssert(ok, @"Failed to set object:key:%@", key);
    return ok;
}

- (BOOL)setStringValue:(NSString *)value forKey:(NSString *)key {
    NSAssert(value != nil, @"%@ must not be null!", key);
    BOOL ok = [self setObject:value forKey:key];
    NSAssert(ok, @"Failed to set object:key:%@", key);
    return ok;
}

- (BOOL)setBoolValue:(BOOL)value forKey:(NSString *)key {
    BOOL ok = [self setObject:[NSNumber numberWithBool:value] forKey:key];
    NSAssert(ok, @"Failed to set object:key:%@", key);
    return ok;
}

- (void)_saveWithBlock:(void (^)(BOOL))block {
    [MHKiiHelper addApiCallCount:1];
    [[MHKiiHelper sharedInstance] startLoadingFor:MHKiiLoadingSave];
    [self saveWithBlock:^(KiiObject *object, NSError *error) {
        BOOL success = (error == nil);
        if (!success) {
            NSLog(@"Error:save:%@", error);
        }
        [[MHKiiHelper sharedInstance] endLoadingFor:MHKiiLoadingSave error:error];
        if (block) {
            block(success);
        }
    }];
}

- (void)_saveAllFieldsWithBlock:(void (^)(BOOL))block {
    [MHKiiHelper addApiCallCount:1];
    [[MHKiiHelper sharedInstance] startLoadingFor:MHKiiLoadingSave];
    [self saveAllFields:YES withBlock:^(KiiObject *object, NSError *error) {
        BOOL success = (error == nil);
        if (!success) {
            NSLog(@"Error:save all fields:%@", error);
        }
        [[MHKiiHelper sharedInstance] endLoadingFor:MHKiiLoadingSave error:error];
        if (block) {
            block(success);
        }
    }];
}

- (void)_deleteWithBlock:(void (^)(BOOL))block {
    [MHKiiHelper addApiCallCount:1];
    [[MHKiiHelper sharedInstance] startLoadingFor:MHKiiLoadingDelete];
    [self deleteWithBlock:^(KiiObject *object, NSError *error) {
        BOOL success = (error == nil);
        if (!success) {
            NSLog(@"Error:delete:%@", error);
        }
        [[MHKiiHelper sharedInstance] endLoadingFor:MHKiiLoadingDelete error:error];
        if (block) {
            block(success);
        }
    }];
}

- (void)_refreshWithBlock:(void (^)(BOOL))block {
    [MHKiiHelper addApiCallCount:1];
    [[MHKiiHelper sharedInstance] startLoadingFor:MHKiiLoadingRefresh];
    [self refreshWithBlock:^(KiiObject *object, NSError *error) {
        BOOL success = (error == nil);
        if (!success) {
            NSLog(@"Error:refresh:%@", error);
        }
        [[MHKiiHelper sharedInstance] endLoadingFor:MHKiiLoadingRefresh error:error];
        if (block) {
            block(success);
        }
    }];
}


- (BOOL)_saveSynchronous:(KiiError **)outError {
    KiiError *error;
    [MHKiiHelper addApiCallCount:1];
    [self saveSynchronous:&error];
    BOOL success = (error == nil);
    if (!success) {
        NSLog(@"Error:save:%@", error);
    }
    if (outError) {
        *outError = error;
    }
    return success;
}

- (BOOL)_refreshSynchronous:(KiiError **)outError {
    KiiError *error;
    [MHKiiHelper addApiCallCount:1];
    [self refreshSynchronous:&error];
    BOOL success = (error == nil);
    if (!success) {
        NSLog(@"Error:refresh:%@", error);
    }
    if (outError) {
        *outError = error;
    }
    return success;
}

- (BOOL)_deleteSynchronous:(KiiError **)outError {
    KiiError *error;
    [MHKiiHelper addApiCallCount:1];
    [self deleteSynchronous:&error];
    BOOL success = (error == nil);
    if (!success) {
        NSLog(@"Error:delete:%@", error);
    }
    if (outError) {
        *outError = error;
    }
    return success;
}

- (void)_set:(NSDictionary *)values widthDeleteKeys:(NSArray *)deleteKeys {
    for (NSString *key in [values keyEnumerator]) {
        [self setObject:[values objectForKey:key] forKey:key];
    }
    for (NSString *key in deleteKeys) {
        [self removeObjectForKey:key];
    }
}

- (NSString *)filePath {
    NSString *uuid = self.uuid;
    NSString *path = [MHFileHelper makeCachePath:[NSString stringWithFormat:@"%@.dat", uuid]];
    return path;
}

- (void)_uploadBody:(NSData *)data withBlock:(void (^)(BOOL))block {
    KiiObject *object = [KiiObject objectWithURI:self.objectURI];
    NSString *path = [self filePath];
    if ([MHFileHelper isFileAtPath:path]) {
        [MHFileHelper removeItemAtPath:path];
    }
    if (![MHFileHelper createFileAtPath:path contents:data attributes:nil]) {
        [MHJob runInMainThread:^{
            if (block) {
                block(FALSE);
            }
        }];
        return;
    }
    
    [MHKiiHelper addApiCallCount:1];
    [[MHKiiHelper sharedInstance] startLoadingFor:MHKiiLoadingUpload];
    KiiUploader *uploader = [object uploader:path];
    [uploader transferWithProgressBlock:^(id<KiiRTransfer> transferObject, NSError *error) {
        KiiRTransferInfo *info = [transferObject info];
        NSLog(@"progress:%d, %d, %d", info.completedSizeInBytes, info.totalSizeInBytes, info.status);
        //0: NOENTRY,
        //1: ONGOING,
        //2: SUSPENDED,
    } andCompletionBlock:^(id<KiiRTransfer> transferObject, NSError *error) {
        KiiRTransferInfo *info = [transferObject info];
        NSLog(@"upload completion:%d, %d, %d, %@", info.completedSizeInBytes, info.totalSizeInBytes, info.status, error);

        if (error == nil) {
            [self _set:@{KeyBody: @YES} widthDeleteKeys:nil];
            [MHJob runInWorkerThread:^{
                KiiError *error;
                [self _saveSynchronous:&error];
            }];
        }
        
        [MHJob runInMainThread:^{
            [[MHKiiHelper sharedInstance] endLoadingFor:MHKiiLoadingUpload error:error];
            if (block) {
                block(error == nil);
            }
        }];
    }];
}

- (NSData *)_bodyCache {
    NSData *ret;
    NSString *path = [self filePath];
    if ([MHFileHelper isFileAtPath:path]) {
        ret = [NSData dataWithContentsOfFile:path];
    }
    return ret;
}

- (void)_downloadBody:(BOOL)force withBlock:(void(^)(BOOL success, NSData *data))block {
    NSString *path = [self filePath];

    if (![self getBoolForKey:KeyBody]) {
        [MHJob runInMainThread:^{
            if (block) {
                block(YES, nil);
            }
        }];
        return;
    }

    if (!force) {
        NSData *data = [self _bodyCache];
        if (data) {
            [MHJob runInMainThread:^{
                if (block) {
                    block(YES, data);
                }
            }];
            return;
        }
    }

    [MHKiiHelper addApiCallCount:1];
    [[MHKiiHelper sharedInstance] startLoadingFor:MHKiiLoadingDownload];
    KiiObject *object = [KiiObject objectWithURI:self.objectURI];
    KiiDownloader *downloader = [object downloader:path];
    [downloader transferWithProgressBlock:^(id<KiiRTransfer> transferObject, NSError *error) {
        KiiRTransferInfo *info = [transferObject info];
        NSLog(@"progress:%d, %d, %d", info.completedSizeInBytes, info.totalSizeInBytes, info.status);
    } andCompletionBlock:^(id<KiiRTransfer> transferObject, NSError *error) {
        KiiRTransferInfo *info = [transferObject info];
        NSLog(@"download completion:%d, %d, %d, %@", info.completedSizeInBytes, info.totalSizeInBytes, info.status, error);
        [[MHKiiHelper sharedInstance] endLoadingFor:MHKiiLoadingDownload error:error];
        if (block) {
            NSData *data;
            BOOL success = (error == nil);
            if (success) {
                data = [object _bodyCache];
                NSAssert(data, @"unexpected null data!");
            }
            block(success, data);
        }
    }];
}

- (void)_deleteBody:(void (^)(BOOL success))block {
    
    if (![self getBoolForKey:KeyBody]) {
        [MHJob runInMainThread:^{
            NSString *path = [self filePath];
            if ([MHFileHelper isFileAtPath:path]) {
                [MHFileHelper removeItemAtPath:path];
            }
            if (block) {
                block(YES);
            }
        }];
    }
    
    [MHKiiHelper addApiCallCount:1];
    [[MHKiiHelper sharedInstance] startLoadingFor:MHKiiLoadingDelete];
    [self deleteBodyWithBlock:^(KiiObject *object, NSError *error) {
        BOOL success = (error == nil) || (error.code == 510); // not exist
        if (success) {
            NSString *path = [self filePath];
            if ([MHFileHelper isFileAtPath:path]) {
                [MHFileHelper removeItemAtPath:path];
            }
            [self _set:@{KeyBody:@NO} widthDeleteKeys:nil];
            [MHJob runInWorkerThread:^{
                KiiError *error;
                [self _saveSynchronous:&error];
            }];
        }
        [[MHKiiHelper sharedInstance] endLoadingFor:MHKiiLoadingDelete error:error];
        if (block) {
            block(success);
        }
    }];
}

+ (NSArray *)valueTypeNames {
    static NSArray *ValueTypeNames = @[@"String", @"Boolean", @"Int", @"Long", @"Double", @"Body"];
    return ValueTypeNames;
}

- (NSString *)typeNameForKey:(NSString *)key {
    NSString *ret;
    id value = [self getObjectForKey:key];
    if (value) {
        ret = [KiiObject valueTypeName:value];
    } else {
        NSLog(@"no object for key:%@", key);
    }
    return ret;
}

+ (NSString *)valueTypeName:(id)value {
    if ([value isKindOfClass:[NSNumber class]]) {
        NSNumber *num = value;
        const char *type = [num objCType];
        if (strcmp(type, @encode(BOOL)) == 0) {
            return @"Boolean";
        } else if (strcmp(type, @encode(int)) == 0) {
            return @"Int";
        } else if (strcmp(type, @encode(long)) == 0) {
            return @"Long";
        } else if (strcmp(type, @encode(long long)) == 0) {
            return @"LongLong";
        } else if (strcmp(type, @encode(double)) == 0) {
            return @"Double";
        } else {
            return [NSString stringWithUTF8String:type];
        }
    }
    NSArray *ValueTypes = @[@"", @NO, @0, @0L, @0.f, [NSData data]];
    for (id obj in ValueTypes) {
        if ([obj isKindOfClass:[value class]]) {
            return [[self valueTypeNames] objectAtIndex:[ValueTypes indexOfObject:obj]];
        }
    }
    return NSStringFromClass([value class]);
}

- (void)dump:(NSString *)name {
    [[self dictionaryValue] dump:name];
}


@end

#pragma mark - KiiBucket
@implementation KiiBucket (MHKiiHelper)

- (NSArray *)_excuteQuerySynchronous:(KiiQuery *)query withError:(KiiError **)pError {
    NSParameterAssert(query);
    int count = 0;
    KiiError *error;
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:256];
    while (query) {
        KiiQuery *nextQuery;
        count++;
        NSArray *results = [self executeQuerySynchronous:query withError:&error andNext:&nextQuery];
        if (error == nil) {
            [array addObjectsFromArray:results];
        } else {
            NSAssert(FALSE, @"Error: queryr:%@", error);
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

- (void)_excuteQuery:(KiiQuery *)query withBlock:(KiiQueryResultBlock)block {
    NSParameterAssert(block);
    [self executeQuery:query withBlock: ^(KiiQuery *query, KiiBucket *bucket, NSArray *results, KiiQuery *nextQuery, NSError *error) {
        NSAssert(error == nil, @"Error: query:%@", error);
        block(query, bucket, results, nextQuery, error);
        [MHKiiHelper addApiCallCount:1];
    }];
}

@end