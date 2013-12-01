//
//  common.h
//  KiiSample
//
//  Created by tsuyoshi on 2013/11/27.
//  Copyright (c) 2013年 Tsuyoshi Miyano. All rights reserved.
//

#ifndef KiiSample_common_h
#define KiiSample_common_h


//#define YOUR_KII_APP_ID
//#define YOUR_KII_APP_KEY



@interface UIViewController (KiiSample)
- (NSArray *)createField:(CGFloat)y label:(NSString *)labelText placeFolder:(NSString *)placeFolder;
@end



@interface KiiManager : NSObject
+ (KiiManager *)sharedInstance;

- (void)newObject;
- (void)deleteObject:(NSString *)uuid;
- (void)refreshObject:(NSString *)uuid;
- (void)save:(NSDictionary *)values;
- (void)saveAll:(NSDictionary *)values widthDeleteKeys:(NSArray *)deleteKeys;

- (NSString *)typeName:(id)value;

@property (nonatomic ,assign)BOOL userMode;
@property (nonatomic, strong) NSString *bucketName;
@property (nonatomic, readonly) KiiBucket *bucket;
@property (nonatomic, readonly) NSArray *valueTypes;
@property (nonatomic, readonly) NSArray *valueTypeNames;

@property (nonatomic, strong) NSString *uuid;
@property (nonatomic, strong) KiiObject *object;
@end

#endif
