//
//  KiiObject+MHLib.h
//  MHLib
//
//  Created by tsuyoshi on 2013/11/19.
//
//

@interface KiiUser (MHKiiHelper)
+ (NSString *)getObjectURI:(NSString *)uuid;

@end

@interface KiiObject (MHKiiHelper)

+ (KiiObject *)objectWithUUID:(NSString *)uuid withBucketName:(NSString *)bucketName;
+ (KiiObject *)userObjectWithUUID:(NSString *)uuid withBucketName:(NSString *)bucketName;

- (int)getIntForkey:(NSString *)key;
- (NSString *)getStringForKey:(NSString *)key;
- (BOOL)getBoolForKey:(NSString *)key;
- (double)getDoubleForKey:(NSString *)key;

- (BOOL)setIntValue:(int)value forKey:(NSString *)key;
- (BOOL)setDoubleValue:(double)value forKey:(NSString *)key;
- (BOOL)setStringValue:(NSString *)value forKey:(NSString *)key;

- (void)_saveAllFieldsWithBlock:(void (^)(BOOL success))block;
- (void)_saveWithBlock:(void (^)(BOOL success))block;
- (void)_refreshWithBlock:(void (^)(BOOL success))block;
- (void)_deleteWithBlock:(void (^)(BOOL success))block;

- (BOOL)_saveSynchronous:(KiiError **)outError;
- (BOOL)_refreshSynchronous:(KiiError **)outError;
- (BOOL)_deleteSynchronous:(KiiError **)outError;

- (void)_uploadBody:(NSData *)data withBlock:(void (^)(BOOL))block;
- (void)_downloadBody:(BOOL)force withBlock:(void(^)(BOOL success, NSData *data))block;
- (NSData *)_bodyCache;

+ (NSArray *)valueTypeNames;
- (NSString *)typeNameForKey:(NSString *)key;

@end



@interface KiiBucket (MHKiiHelper)

- (NSArray *)_excuteQuerySynchronous:(KiiQuery *)query withError:(KiiError **)pError;
- (void)_excuteQuery:(KiiQuery *)query withBlock:(KiiQueryResultBlock)block;

@end