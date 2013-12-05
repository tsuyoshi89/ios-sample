//
//  MHFoundation.h
//  MHLib
//
//  Created by tsuyoshi on 2013/11/19.
//
//

@interface NSDictionary (MHLib)
- (int)getIntForkey:(NSString *)key;
- (NSString *)getStringForKey:(NSString *)key;
- (BOOL)getBoolForKey:(NSString *)key;
- (double)getDoubleForKey:(NSString *)key;
- (void)dump:(NSString *)title;
@end

@interface NSMutableDictionary (MHLib)
- (void)setIntValue:(int)value forKey:(NSString *)key;
- (void)setBoolValue:(BOOL)value forKey:(NSString *)key;
- (void)setDoubleValue:(double)value forKey:(NSString *)key;
- (void)setStringValue:(NSString *)value forKey:(NSString *)key;
@end
