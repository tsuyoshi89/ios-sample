//
//  KiiManager.h
//  KiiSample
//
//  Created by tsuyoshi on 2013/12/05.
//  Copyright (c) 2013年 Tsuyoshi Miyano. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KiiManager : NSObject
+ (KiiManager *)sharedInstance;

- (void)newObject;
- (void)deleteObject:(NSString *)uuid;
- (void)refreshObject:(NSString *)uuid;
- (void)save:(NSDictionary *)values;
- (void)saveAll:(NSDictionary *)values widthDeleteKeys:(NSArray *)deleteKeys;
- (void)deleteBody;
- (void)uploadData:(NSData *)data;
- (void)downloadData:(void (^)(NSData *data))block;

@property (nonatomic ,assign)BOOL userMode;
@property (nonatomic, strong) NSString *bucketName;
@property (nonatomic, readonly) KiiBucket *bucket;

@property (nonatomic, strong) NSString *uuid;
@property (nonatomic, strong) KiiObject *object;
@end

