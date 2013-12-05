//
//  MHFundation.mm
//  MHLib
//
//  Created by tsuyoshi on 2013/11/19.
//
//

#import "MHJob.h"
#import "MHFoundation.h"

@implementation NSDictionary (MHLib)
- (int)getIntForkey:(NSString *)key {
    id obj = [self objectForKey:key];
    return [obj intValue];
}

- (NSString *)getStringForKey:(NSString *)key {
    id obj = [self objectForKey:key];
    return obj;
}

- (BOOL)getBoolForKey:(NSString *)key {
    id obj = [self objectForKey:key];
    return [obj boolValue];
}

- (double)getDoubleForKey:(NSString *)key {
    id obj = [self objectForKey:key];
    return [obj doubleValue];
}
- (void)dump:(NSString *)title {
#ifdef DEBUG
    NSDictionary *dict = self;
    __block NSString *text= [NSString stringWithFormat:@"%@ (NSDictionary):", title];
    __block int num = 0;
    [dict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        text = [text stringByAppendingString:[NSString stringWithFormat:@"\n\t%d:%@:%@\t(%@)",num, key, obj, NSStringFromClass([obj class])]];
        num++;
    }];
    NSLog(@"%@", text);
#endif
}

@end

@implementation NSMutableDictionary (MHLib)

- (void)setIntValue:(int)value forKey:(NSString *)key {
    [self setObject:[NSNumber numberWithInt:value] forKey:key];
}

- (void)setBoolValue:(BOOL)value forKey:(NSString *)key {
    [self setObject:[NSNumber numberWithBool:value] forKey:key];
}

- (void)setDoubleValue:(double)value forKey:(NSString *)key {
    [self setObject:[NSNumber numberWithDouble:value] forKey:key];
}

- (void)setStringValue:(NSString *)value forKey:(NSString *)key {
    [self setObject:value forKey:key];
}
@end
