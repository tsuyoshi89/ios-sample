//
//  common.mm
//  KiiSample
//
//  Created by tsuyoshi on 2013/11/27.
//  Copyright (c) 2013年 Tsuyoshi Miyano. All rights reserved.
//

#import "common.h"


@implementation UIViewController (KiiSample)

- (NSArray *)createField:(CGFloat)y label:(NSString *)labelText placeFolder:(NSString *)placeFolder {
    UITextField *label = [[UITextField alloc] initWithFrame:CGRectMake(10, y, 70, 30)];
    label.text = labelText;
    label.userInteractionEnabled = FALSE;
    label.font = [UIFont boldSystemFontOfSize:13.0f];
    label.textColor = [UIColor brownColor];
    
    UITextField *field = [[UITextField alloc] initWithFrame:CGRectMake(CGRectGetMaxX(label.frame), y, 250, 30)];
    field.placeholder = placeFolder;
    field.minimumFontSize = 8.0f;
    field.font = [UIFont systemFontOfSize:12];
    
    [self.view addSubview:label];
    [self.view addSubview:field];
    return @[label, field];
}

@end



@implementation KiiManager {
    NSString *_bucketName;
}

+ (KiiManager *)sharedInstance {
    static KiiManager *instance;
    if (instance == nil) {
        instance = [[KiiManager alloc] init];
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


- (NSArray *)valueTypeNames {
    static NSArray *ValueTypeNames = @[@"String", @"Boolean", @"Int", @"Long", @"Double"];
    return ValueTypeNames;
}

- (NSArray *)valueTypes {
    static NSArray *ValueTypes = @[@"", @NO, @0, @0L, @1.];
    return ValueTypes;
}

- (NSString *)typeName:(id)value {
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
    for (id obj in self.valueTypes) {
        if ([obj isKindOfClass:[value class]]) {
            return [self.valueTypeNames objectAtIndex:[self.valueTypes indexOfObject:obj]];
        }
    }
    return NSStringFromClass([value class]);
}


- (void)hideLoaderWithError:(NSError *)error {
    [KTLoader showLoader:[NSString stringWithFormat:@"Error: %@", error]
                animated:YES withIndicator:KTLoaderIndicatorError andHideInterval:KTLoaderDurationAuto];
    NSLog(@"error:%@", error);
}

- (NSString *)getURI:(NSString *)uuid {
    if (self.userMode) {
        return [NSString stringWithFormat:@"kiicloud://users/%@/buckets/%@/objects/%@", [KiiUser currentUser].uuid, self.bucketName, uuid];
    } else {
        return [NSString stringWithFormat:@"kiicloud://buckets/%@/objects/%@", self.bucketName, uuid];
    }
}

- (void)newObject {
    [KTLoader showLoader:@"create object..."];
    KiiObject *object = [self.bucket createObject];
    [object save:YES withBlock:^(KiiObject *object, NSError *error) {
        if (error == nil) {
            self.uuid =  object.uuid;
            NSLog(@"uri:%@", [object objectURI]);
            [KTLoader hideLoader];
            self.object = object;
        } else {
            NSLog(@"create:%@", error);
            [self hideLoaderWithError:error];
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
    KiiObject *object = [KiiObject objectWithURI:[self getURI:uuid]];
    [KTLoader showLoader:@"delete object..."];
    [object deleteWithBlock:^(KiiObject *object, NSError *error) {
        if (error == nil) {
            [KTLoader hideLoader];
        } else {
            [self hideLoaderWithError:error];
        }
        self.object = nil;
    }];
}

- (void)refreshObject:(NSString *)uuid {
    if (uuid.length != 36) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Save error" message:@"まずオブジェクトを作成してください"
                                                       delegate:nil cancelButtonTitle:@"閉じる" otherButtonTitles:nil, nil];
        [alert show];
        return;
    }
    KiiObject *object = [KiiObject objectWithURI:[self getURI:uuid]];
    [KTLoader showLoader:@"refresh object..."];
    [object refreshWithBlock:^(KiiObject *object, NSError *error) {
        if (error == nil) {
            [KTLoader hideLoader];
        } else {
            [self hideLoaderWithError:error];
        }
        self.object = object;
    }];
}

- (void)save:(NSDictionary *)values {
    [KTLoader showLoader:@"save object..."];
    KiiObject *object = [KiiObject objectWithURI:self.object.objectURI];
    for (NSString *key in [values keyEnumerator]) {
        if ([[values objectForKey:key] isEqual:[self.object getObjectForKey:key]]) {
            continue;
        } else {
            [object setObject:[values objectForKey:key] forKey:key];
        }
    }
    [object save:YES withBlock:^(KiiObject *object, NSError *error) {
        if (error == nil) {
            [KTLoader hideLoader];
        } else {
            [self hideLoaderWithError:error];
        }
        [self refreshObject:object.uuid];
    }];
}

- (void)saveAll:(NSDictionary *)values widthDeleteKeys:(NSArray *)deleteKeys {
    [KTLoader showLoader:@"save object..."];
    
    KiiObject *object = [KiiObject objectWithURI:self.object.objectURI];
    
    [object refreshWithBlock:^(KiiObject *object, NSError *error) {
        if (error == nil) {
            for (NSString *key in [values keyEnumerator]) {
                [object setObject:[values objectForKey:key] forKey:key];
            }
            for (NSString *key in deleteKeys) {
                [object removeObjectForKey:key];
            }
            
            [object saveAllFields:YES withBlock:^(KiiObject *object, NSError *error) {
                if (error == nil) {
                    [KTLoader hideLoader];
                } else {
                    [self hideLoaderWithError:error];
                }
                [self refreshObject:object.uuid];
            }];
        } else {
            [self hideLoaderWithError:error];
            self.object = object;
        }
    }];
}


@end
