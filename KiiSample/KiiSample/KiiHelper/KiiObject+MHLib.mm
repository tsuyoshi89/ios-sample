//
//  KiiObject+MHLib.m
//  MHLib
//
//  Created by tsuyoshi on 2013/11/19.
//
//


#import "MHJob.h"
#import "KiiObject+MHLib.h"
#import "MHKiiHelper.h"

#define MHLib_OBJC_CAST(type, obj) ([(obj) isKindOfClass:[type class]] ? ((type *)(obj)) : nil)
#define MHClassName(obj) NSStringFromClass([(obj) class])

static NSString *userDomain = @"kiicloud://users/";

@implementation KiiUser (MHLib)
+ (NSString *)objectURIFromUUID:(NSString *)uuid {
    return [userDomain stringByAppendingString:uuid];
}
@end


@implementation KiiObject (Sola)
- (int)getIntForkey:(NSString *)key {
    id obj = [self getObjectForKey:key];
    NSAssert(obj && MHLib_OBJC_CAST(NSNumber, obj), @"unexpected object type:%@", MHClassName(obj));
    return [obj intValue];
}

- (NSString *)getStringForKey:(NSString *)key {
    id obj = [self getObjectForKey:key];
    NSAssert(obj && MHLib_OBJC_CAST(NSString, obj), @"unexpected object type:%@", MHClassName(obj));
    return obj;
}

- (BOOL)getBoolForKey:(NSString *)key {
    id obj = [self getObjectForKey:key];
    NSAssert(obj && MHLib_OBJC_CAST(NSNumber, obj), @"unexpected object type:%@", MHClassName(obj));
    return [obj boolValue];
}

- (double)getDoubleForKey:(NSString *)key {
    id obj = [self getObjectForKey:key];
    NSAssert(obj && MHLib_OBJC_CAST(NSNumber, obj), @"unexpected object type:%@", MHClassName(obj));
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

- (void)mySaveWithBlock:(void (^)(BOOL))block {
    [MHJob runInWorkerThread:^{
        BOOL ok = [self mySaveSynchronous:nil];
        [MHJob runInMainThread:^{
            if (block) {
                block(ok);
            }
        }];
    }];
}

- (BOOL)mySaveSynchronous:(KiiError **)outError {
    KiiError *error;
    [MHKiiHelper addApiCallCount:1];
    [self saveSynchronous:&error];
    BOOL ok = (error == nil);
    NSAssert(ok, @"Error: save:%@", error);
    if (outError) {
        *outError = error;
    }
    return ok;
}

- (BOOL)myRefreshSynchronous:(KiiError **)outError {
    KiiError *error;
    [MHKiiHelper addApiCallCount:1];
    [self refreshSynchronous:&error];
    NSAssert(error == nil, @"Error: refresh:%@", error);
    if (outError) {
        *outError = error;
    }
    return error == nil;
}

- (BOOL)myDeleteSynchronous:(KiiError **)outError {
    KiiError *error;
    [MHKiiHelper addApiCallCount:1];
    [self deleteSynchronous:&error];
    NSAssert(error == nil, @"delete error:%@", error);
    if (outError) {
        *outError = error;
    }
    return error == nil;
}

@end
