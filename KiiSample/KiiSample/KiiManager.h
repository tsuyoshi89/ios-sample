//
//  KiiManager.h
//  KiiSample
//
//  Created by tsuyoshi on 2013/12/05.
//  Copyright (c) 2013年 Tsuyoshi Miyano. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MHKiiHelper.h"

@class KiiManager;

@protocol KiiManagerDelegate <NSObject>
- (void)kiiManager:(KiiManager *)manager didChangeObject:(KiiObject *)object;
@end

@interface KiiManager : NSObject <MHKiiHelperDelegate>
+ (KiiManager *)sharedInstance;

- (void)newObject;
- (void)deleteObject:(NSString *)uuid;
- (void)refreshObject:(NSString *)uuid;
- (void)save:(NSDictionary *)values;
- (void)saveAll:(NSDictionary *)values widthDeleteKeys:(NSArray *)deleteKeys;
- (void)deleteBody;
- (void)uploadData:(NSData *)data;
- (void)downloadData;

@property (nonatomic ,assign)BOOL userMode;
@property (nonatomic, strong) NSString *bucketName;
@property (nonatomic, readonly) KiiBucket *bucket;

@property (nonatomic, strong) NSString *uuid;
@property (nonatomic, strong) KiiObject *object;
@property (nonatomic, weak) id<KiiManagerDelegate> delegate;
@end

