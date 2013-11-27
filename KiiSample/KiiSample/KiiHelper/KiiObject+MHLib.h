//
//  KiiObject+MHLib.h
//  MHLib
//
//  Created by tsuyoshi on 2013/11/19.
//
//

@interface KiiUser (MHLib)
+ (NSString *)objectURIFromUUID:(NSString *)uuid;

@end

@interface KiiObject (Sola)

- (int)getIntForkey:(NSString *)key;
- (NSString *)getStringForKey:(NSString *)key;
- (BOOL)getBoolForKey:(NSString *)key;
- (double)getDoubleForKey:(NSString *)key;

- (BOOL)setIntValue:(int)value forKey:(NSString *)key;
- (BOOL)setDoubleValue:(double)value forKey:(NSString *)key;
- (BOOL)setStringValue:(NSString *)value forKey:(NSString *)key;

- (void)mySaveWithBlock:(void (^)(BOOL))block;
- (BOOL)mySaveSynchronous:(KiiError **)outError;
- (BOOL)myRefreshSynchronous:(KiiError **)outError;
- (BOOL)myDeleteSynchronous:(KiiError **)outError;

@end
