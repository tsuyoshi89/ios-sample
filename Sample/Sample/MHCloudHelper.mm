//
//  MHCloudHelper.m
//  Sample
//
//  Created by tsuyoshi on 2013/11/22.
//  Copyright (c) 2013年 Tsuyoshi Miyano. All rights reserved.
//

#import <CommonCrypto/CommonDigest.h>
#import "MHCloudHelper.h"
#import "MHFileHelper.h"

#define KEY_CLOUD_TOKEN @"com.apple.miyano-harikyu.UbiquityIdentityToken"

#ifndef UNUSED_VARIABLE
#define UNUSED_VARIABLE(v) (void)(v)
#endif

@interface MHCloudDocument : UIDocument

@property (nonatomic, retain) NSData *data;

// open exists file
+ (void)openURL:(NSURL *)url onOpen:(void (^)(MHCloudDocument *document))block completion:(MHCloudCompletionBlock)block;
// save overwrite. this method is called in block
- (void)changeData:(NSData *)newData;

@end

static NSDateFormatter *dateFormatter() {
    NSDateFormatter* fmt = [[NSDateFormatter alloc] init];
    [fmt setLocale:[NSLocale currentLocale]];
    [fmt setTimeZone:[NSTimeZone systemTimeZone]];
    return fmt;
}

#if 0
static NSString *makeKey(NSString *token) {
    // Create pointer to the string as UTF8
    const char *ptr = [token UTF8String];
    
    // Create byte array of unsigned chars
    unsigned char md5Buffer[CC_MD5_DIGEST_LENGTH];
    
    // Create 16 byte MD5 hash value, store in buffer
    CC_MD5(ptr, (CC_LONG)strlen(ptr), md5Buffer);
    
    // Convert MD5 value in the buffer to NSString of hex values
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x",md5Buffer[i]];
    
    return output;
}
#endif


static void logging(MHCloudDocument *document, NSString *prefix) {
    NSFileVersion *version = [NSFileVersion currentVersionOfItemAtURL:document.fileURL];
    NSDateFormatter *fmt = dateFormatter();
    [fmt setDateFormat:@"YY/MM/dd HH:mm"];
    NSString *dateText = [fmt stringFromDate:version.modificationDate];
    UNUSED_VARIABLE(dateText);
    NSLog(@"%@ date:%@", prefix, dateText);
}

@interface MHCloudHelper () <UIAlertViewDelegate>
@property (nonatomic, readonly) id<NSObject> currentToken;
@end

@implementation MHCloudHelper {
    NSMutableArray *_observers;
    NSMetadataQuery *_query;
}

+ (id)ubiquityIdentityToken {
    //@iOS6:
    id<NSCopying> ubiquityIdentityToken = [[NSFileManager defaultManager] ubiquityIdentityToken];
    return ubiquityIdentityToken;
}

+ (BOOL)isSignIn {
    return ([self ubiquityIdentityToken] != nil);
}

+ (MHCloudHelper *)sharedInstance {
    static MHCloudHelper *sInstance;
    if (!sInstance) {
        sInstance = [[MHCloudHelper alloc] init];
    }
    return sInstance;
}

- (id)init {
    self = [super init];
    if (self) {
        //initialize cloud container
        NSURL *containerURL = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil];
        UNUSED_VARIABLE(containerURL);
        
        _observers = [NSMutableArray arrayWithCapacity:4];
        _currentToken = [MHCloudHelper ubiquityIdentityToken];
        [self startCloudObserve];
        [self initializeCloudAccess];
#ifdef DEBUG
        [self debugObserver];
#endif
    }
    return self;
}

- (void)dealloc {
    [self stopCloudObserve];
}

- (void)addStateObserver:(id<MHCloudStateObserver>)observer {
    NSParameterAssert(observer);
    if ([_observers containsObject:observer]) {
        return;
    }
    [_observers addObject:observer];
}

- (void)removeStateObserver:(id<MHCloudStateObserver>)observer {
    NSParameterAssert(observer);
    if (observer && [_observers containsObject:observer]) {
        [_observers removeObject:observer];
    }
}

- (BOOL)cloudIsAvailable {
    return (_containerURL != nil);
}

- (BOOL)isCloudURL:(NSURL *)url {
    if (_containerURL && url) {
        NSRange range = [[url absoluteString] rangeOfString:[_containerURL absoluteString] options:NSAnchoredSearch];
        NSLog(@"isCloudURL:%@, cloud:%@ range = %lu", [url absoluteString], [_containerURL absoluteString], (unsigned long)range.location);
        return (range.location == 0);
    }
    return FALSE;
}

- (void)initializeCloudAccess {
    void (^block)(void) = ^{
        _containerURL = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil];
        BOOL available = (_containerURL != nil);
        if (_containerURL != nil) {
            NSLog(@"iCloud is available. container url:%@", [_containerURL absoluteString]);
        } else {
            NSLog(@"iCloud is not available.");
        }
        // callback is
        dispatch_async (dispatch_get_main_queue (), ^(void) {
            id<NSObject> prevToken = [self loadToken];
            BOOL tokenChanged  = FALSE;
            if (self.currentToken) {
                if (![self.currentToken isEqual:prevToken]) {
                    [self saveToken:self.currentToken];
                    //@at first time tokenChanged flag is FALSE
                    tokenChanged = (prevToken != nil);
                }
            }
            for (id<MHCloudStateObserver> observer in _observers) {
                [observer cloudAvailabilityChanged:available tokenChanged:tokenChanged];
            }
        });
    };

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), block);
}

- (id<NSObject>)loadToken {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSData *data = [ud dataForKey:KEY_CLOUD_TOKEN];
    id<NSObject > token = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    return token;
}

- (void)saveToken:(id<NSObject>)token {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:token];
    [ud setObject:data forKey:KEY_CLOUD_TOKEN];
    BOOL ok = [ud synchronize];
    UNUSED_VARIABLE(ok);
    NSAssert(ok, @"save token synchronized:%d", ok);
}

- (NSURL *)cloudURLByAppendingPathComponent:(NSString *)path {
    NSParameterAssert(_containerURL);
    if (_containerURL) {
        return [_containerURL URLByAppendingPathComponent:path];
    }
    return nil;
}

- (NSURL *)documentsURLByAppendingPathComponent:(NSString *)path {
    NSParameterAssert(_containerURL);
    if (_containerURL) {
        NSURL *url = [_containerURL URLByAppendingPathComponent:@"Documents"];
        return [url URLByAppendingPathComponent:path];
    }
    return nil;
}


- (void)startCloudObserve {
    //@iOS6 later:
    [[NSNotificationCenter defaultCenter]
     addObserver: self
     selector: @selector(accountAvailabilityChanged:)
     name: NSUbiquityIdentityDidChangeNotification
     object: nil];
        
    [[NSNotificationCenter defaultCenter]
     addObserver: self
     selector: @selector(didChangeExternallyNotification:)
     name: NSUbiquitousKeyValueStoreDidChangeExternallyNotification
     object: nil];
}

- (void)stopCloudObserve {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)accountAvailabilityChanged:(NSNotification *)notification {
    NSLog(@"accountAvailabilityChanged");
    _currentToken = [MHCloudHelper ubiquityIdentityToken];
    [self initializeCloudAccess];
}

- (void)didChangeExternallyNotification:(NSNotification *)notification {
    
    NSDictionary *userInfo = notification.userInfo;
    NSNumber *reason = [userInfo objectForKey:NSUbiquitousKeyValueStoreChangeReasonKey];
    NSArray *keys = [userInfo objectForKey:NSUbiquitousKeyValueStoreChangedKeysKey];
    //NSUbiquitousKeyValueStore *store = [NSUbiquitousKeyValueStore defaultStore];
    //NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    
    if (reason) {
        NSInteger reasonValue = [reason integerValue];
        switch (reasonValue) {
            case NSUbiquitousKeyValueStoreInitialSyncChange:
                NSLog(@"initial sync change");
                break;
            case NSUbiquitousKeyValueStoreServerChange:
                NSLog(@"store sever change");
                break;
            case NSUbiquitousKeyValueStoreQuotaViolationChange:
                NSLog(@"quota violation change");
                break;
            case NSUbiquitousKeyValueStoreAccountChange:
                NSLog(@"account change");
                break;
            default:
                NSAssert(FALSE, @"unexpected reason:%ld", (long)reasonValue);
                break;
        }
    }
#ifdef DEBUG
    for (NSString *key in keys) {
        //NSObject *value = [store objectForKey:key];
        NSLog(@"update value forKey:%@", key);
    }
#endif
}

- (void)recommendCloudAlert {
    //@TODO:
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle: @"Choose Storage Option"
                          message: @"Should documents be stored in iCloud and available on all your devices?"
                          delegate: self
                          cancelButtonTitle: @"Local Only"
                          otherButtonTitles: @"Use iCloud", nil];
    [alert show];
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    //@TODO: set flag
    //NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    //[ud setBool:YES forKey:KEY_CLOUD_NOT_FIRST_LAUNCH];
}

#pragma mark - debug method for cloud document
#ifdef DEBUG
-(void)debugObserver {
    
    NSNotificationCenter* notificationCenter = [NSNotificationCenter defaultCenter];
    
    NSMetadataQuery *query = [[NSMetadataQuery alloc] init];
    [query setSearchScopes:[NSArray arrayWithObjects:NSMetadataQueryUbiquitousDataScope, NSMetadataQueryUbiquitousDocumentsScope, nil]];
    [query setPredicate:[NSPredicate predicateWithFormat:@"%K LIKE '*'", NSMetadataItemFSNameKey]];
    [notificationCenter addObserver:self selector:@selector(cloudDocumentNotification:)
                               name:NSMetadataQueryDidFinishGatheringNotification object:query];
    [notificationCenter addObserver:self selector:@selector(cloudDocumentNotification:)
                               name:NSMetadataQueryDidUpdateNotification object:query];
    [query startQuery];
    _query = query;
}

- (void)cloudDocumentNotification:(NSNotification *)notification {
    NSLog(@"cloudDocumentNotification: %@", notification.name);
    
    NSMetadataQuery *query = notification.object;
    NSArray* queryResults = [query results];
    for (NSMetadataItem* result in queryResults) {
        NSString* fileName = [result valueForAttribute:NSMetadataItemFSNameKey];
        NSString *displayName = [result valueForAttribute:NSMetadataItemDisplayNameKey];
        NSURL *url = [result valueForAttribute:NSMetadataItemURLKey];
        NSString *pathKey = [result valueForAttribute:NSMetadataItemPathKey];// NSString
        unsigned long fsSize = [[result valueForAttribute:NSMetadataItemFSSizeKey] unsignedLongValue];// file size in bytes; unsigned long
        NSDate *createDate = [result valueForAttribute:NSMetadataItemFSCreationDateKey];
        NSDate *updateDate = [result valueForAttribute:NSMetadataItemFSContentChangeDateKey];
        BOOL isUbiquitos = [[result valueForAttribute:NSMetadataItemIsUbiquitousKey] boolValue]; // boolean NSNumber
        NSString *status = [result valueForAttribute:NSMetadataUbiquitousItemDownloadingStatusKey];// NSString ; download status of this item. The values are the three strings defined below:
        BOOL isDownloading = [[result valueForAttribute:NSMetadataUbiquitousItemIsDownloadingKey] boolValue];// boolean NSNumber
        BOOL isUploaded = [[result valueForAttribute:NSMetadataUbiquitousItemIsUploadedKey] boolValue];// boolean NSNumber
        BOOL isUploading = [[result valueForAttribute:NSMetadataUbiquitousItemIsUploadingKey] boolValue];// boolean NSNumber
        double downloadPer = [[result valueForAttribute:NSMetadataUbiquitousItemPercentDownloadedKey] doubleValue];// double NSNumber; range [0..100]
        double uploadPer = [[result valueForAttribute:NSMetadataUbiquitousItemPercentUploadedKey] doubleValue];// double NSNumber; range [0..100]
        NSError *downloadErr = [result valueForAttribute:NSMetadataUbiquitousItemDownloadingErrorKey]; // NSError; the error when downloading the item from iCloud failed, see the NSUbiquitousFile section in FoundationErrors.h
        NSError *uploadErr = [result valueForAttribute:NSMetadataUbiquitousItemUploadingErrorKey];// NSError; the error when uploading the item to iCloud failed, see the NSUbiquitousFile section in FoundationErrors.h

        NSDateFormatter *fmt = dateFormatter();
        [fmt setDateFormat:@"YYYY/MM/dd HH:mm"];

        NSString *infoText = [NSString stringWithFormat:@"NSMetadataItem\n\t"
                              "NSMetadataItemFSNameKey:%@\n\t"
                              "NSMetadataItemDisplayNameKey:%@\n\t"
                              "NSMetadataItemURLKey:%@\n\t"
                              "NSMetadataItemPathKey:%@\n\t"
                              "NSMetadataItemFSSizeKey:%lu\n\t"
                              "NSMetadataItemFSCreationDateKey:%@\n\t"
                              "NSMetadataItemFSContentChangeDateKey:%@\n\t"
                              "NSMetadataItemIsUbiquitousKey:%@\n\t"
                              "NSMetadataUbiquitousItemDownloadingStatusKey:%@\n\t"
                              "NSMetadataUbiquitousItemIsDownloadingKey:%@\n\t"
                              "NSMetadataUbiquitousItemIsUploadedKey:%@\n\t"
                              "NSMetadataUbiquitousItemIsUploadingKey:%@\n\t"
                              "NSMetadataUbiquitousItemPercentDownloadedKey:%.f\n\t"
                              "NSMetadataUbiquitousItemPercentUploadedKey:%.f\n\t"
                              "NSMetadataUbiquitousItemDownloadingErrorKey:%@\n\t"
                              "NSMetadataUbiquitousItemUploadingErrorKey:%@\n\t",
                              fileName, displayName, [url absoluteString],
                              pathKey, fsSize, [fmt stringFromDate:createDate], [fmt stringFromDate:updateDate],
                              isUbiquitos ? @"YES" : @"NO", status, isDownloading ? @"YES" : @"NO",
                              isUploaded ?@"YES" : @"NO", isUploading ? @"YES" : @"NO",
                              downloadPer, uploadPer, downloadErr, uploadErr];
                          
        NSLog(@"%@", infoText);
#if 0
                          NSMetadataUbiquitousItemDownloadingStatusNotDownloaded;// this item has not been downloaded yet. Use startDownloadingUbiquitousItemAtURL:error: to download it.
                          NSMetadataUbiquitousItemDownloadingStatusDownloaded;// there is a local version of this item available. The most current version will get downloaded as soon as possible.
                          NSMetadataUbiquitousItemDownloadingStatusCurrent;// there is a local version of this item and it is the most up-to-date version known to this device.

                          
        NSFileVersion *version = [NSFileVersion currentVersionOfItemAtURL:url];
        NSLog(@"modificationDate:%@", [fmt stringFromDate:version.modificationDate]);
        NSLog(@"data:%@", [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil]);
        [MHCloudDocument openURL:url onOpen:^(MHCloudDocument *document) {
            NSLog(@"name:%@ data:%@", [url lastPathComponent], [[NSString alloc] initWithData:document.data encoding:NSUTF8StringEncoding]);
        } completion:nil];
        
        NSArray *versions = [NSFileVersion otherVersionsOfItemAtURL:url];
        NSLog(@"versions count:%lu", (unsigned long)versions.count);
#endif
        
        if ([status isEqualToString:NSMetadataUbiquitousItemDownloadingStatusNotDownloaded]) {
            NSError *error;
            [[NSFileManager defaultManager] startDownloadingUbiquitousItemAtURL:url error:&error];
            
            if (error == nil) {
                NSLog(@"success download!!");
            } else {
                NSLog(@"error download:%@!", error);
            }
        }
    }
}
#endif

#pragma mark - public class method

+ (BOOL)fileExistsAtURL:(NSURL *)url {
    return [MHFileHelper fileExistsAtURL:url isDirectory:nil];
}

+ (NSDate *)modificationDateAtURL:(NSURL *)url {
    NSFileVersion *version = [NSFileVersion currentVersionOfItemAtURL:url];
    return version.modificationDate;
}

+ (void)removeItemAtURL:(NSURL *)url completion:(MHCloudCompletionBlock)block {
    NSParameterAssert(url);
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @try {
            NSError *writeError;
            NSFileCoordinator *coordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
            [coordinator coordinateWritingItemAtURL:url options:NSFileCoordinatorWritingForDeleting error:&writeError byAccessor:^(NSURL *newURL) {
                NSFileManager *fileManager = [[NSFileManager alloc] init];
                NSError *removeError;
                BOOL ok = [fileManager removeItemAtURL:newURL error:&removeError];
                if (ok) {
                    NSLog(@"removeItemAtURL:%@", [newURL lastPathComponent]);
                } else {
                    NSLog(FALSE, @"Failed removeItemAtURL:%@, %@", [newURL lastPathComponent], removeError.description);
                }
                NSAssert([NSThread isMainThread], @"must call in main thread");
                //!!!:main queue??
                if (block) {
                    block(ok);
                }
            }];
            NSAssert(writeError == nil, @"error coordinateWritingItemAtURL:%@, %@", [url lastPathComponent], writeError.description);
        } @catch (NSException *e) {
            NSLog(@"exception[%@]", e);
            if (block) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    block(NO);
                });
            }
        }
    });
}

+ (void)copyToCloud:(NSURL *)srcURL cloudURL:(NSURL *)cloudURL completion:(MHCloudCompletionBlock)block {
    NSParameterAssert([self fileExistsAtURL:srcURL]);
    NSParameterAssert(cloudURL && ![self fileExistsAtURL:cloudURL]);
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSURL *tempURL = [MHFileHelper makeTemporaryFileURL];
        if ([MHFileHelper copyItemAtURL:srcURL toURL:tempURL]) {
            [self moveToCloud:tempURL cloudURL:cloudURL completion:block];
        } else {
            NSLog(@"failed: copy to cloud:%@, %@", [tempURL lastPathComponent], [cloudURL lastPathComponent]);
            if (block) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    block(FALSE);
                });
            }
        }
    });
}

+ (void)copyFromCloud:(NSURL *)srcURL cloudURL:(NSURL *)cloudURL overwrite:(BOOL)overwrite completion:(MHCloudCompletionBlock)block {
    NSParameterAssert([self fileExistsAtURL:cloudURL]);
    NSParameterAssert(srcURL && (overwrite || ![self fileExistsAtURL:srcURL]));
#if 1
    __block BOOL ok = FALSE;
    NSString *tempPath = [MHFileHelper makeTemporaryFilePath];
    NSAssert(![tempPath isEqualToString:[srcURL path]], @"src path and temporary path is same!:%@", tempPath);
    [MHCloudDocument openURL:cloudURL
                      onOpen:^(MHCloudDocument *document) {
                          ok = [MHFileHelper createFileAtPath:tempPath contents:document.data attributes:nil];
                      }
                  completion:^(BOOL success) {
                      if (ok) {
                          if (overwrite && [MHFileHelper isFileAtURL:srcURL]) {
                              [MHFileHelper removeItemAtURL:srcURL];
                          }
                          ok = [MHFileHelper moveItemAtPath:tempPath toPath:[srcURL path]];
                          if ([MHFileHelper isFileAtPath:tempPath]) {
                              [MHFileHelper removeItemAtPath:tempPath];
                          }
                      }
                      NSAssert([NSThread isMainThread], @"must be called in main thread!");
                      if (block) {
                          block(ok);
                          
                      }
                  }];
#else
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        BOOL ok = [MHFileHelper copyItemAtURL:cloudURL toURL:srcURL];
        NSLog(@"copyFromCloud:%@,%@,%d", [srcURL lastPathComponet], [cloudURL lastPathComponent], ok);
        if (block) {
            block;
        }
    });
#endif
    
}

+ (void)moveToCloud:(NSURL *)srcURL cloudURL:(NSURL *)cloudURL completion:(MHCloudCompletionBlock)block {
    NSParameterAssert([self fileExistsAtURL:srcURL]);
    NSParameterAssert(cloudURL && ![self fileExistsAtURL:cloudURL]);
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        NSFileManager *fileManager = [[NSFileManager alloc] init];
        NSError *error = nil;
        BOOL success = [fileManager setUbiquitous:YES itemAtURL:srcURL
                                   destinationURL:cloudURL error:&error];
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            if (success) {
                NSAssert(![self fileExistsAtURL:srcURL], @"src file is exists after move to cloud!:%@", [srcURL lastPathComponent]);
                NSLog(@"moved file(%@) to cloud(%@)", [srcURL lastPathComponent], [cloudURL lastPathComponent]);
            } else {
                NSLog(@"failed to move file to cloud: %@, %@, %@", [srcURL lastPathComponent], [cloudURL lastPathComponent], error.description);
            }
            if (block) {
                block(success);
            }
        });
    });
}

+ (void)moveFromCloud:(NSURL *)srcURL cloudURL:(NSURL *)cloudURL completion:(MHCloudCompletionBlock)block {
    NSParameterAssert(srcURL && ![self fileExistsAtURL:srcURL]);
    NSParameterAssert([self fileExistsAtURL:cloudURL]);
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        NSFileManager *fileManager = [[NSFileManager alloc] init];
        NSError *error = nil;
        
        NSURL *tmpURL = [MHFileHelper makeTemporaryFileURL];
        BOOL success = [fileManager setUbiquitous:NO itemAtURL:tmpURL
                                   destinationURL:cloudURL error:&error];
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            BOOL ok = success;
            if (ok) {
                NSAssert(![self fileExistsAtURL:cloudURL], @"cloud file is exists after move");
                ok = [MHFileHelper moveItemAtURL:tmpURL toURL:srcURL];
                NSLog(@"moved file from cloud: %@, %@", [srcURL absoluteString], [cloudURL absoluteString]);
            } else {
                NSLog(@"failed to move file from cloud: %@, %@, %@", [srcURL absoluteString], [cloudURL absoluteString], error.description);
            }
            if (block) {
                block(ok);
            }
        });
    });
}

+ (void)createItemAtURL:(NSURL *)url data:(NSData *)data completion:(MHCloudCompletionBlock)completionHandler {
    MHCloudDocument *document = [[MHCloudDocument alloc] initWithFileURL:url];
    document.data = data;
    [document saveToURL:document.fileURL forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success) {
        if (success) {
            NSAssert([self fileExistsAtURL:url], @"file not exists!:%@", [url absoluteString]);
            logging(document, [NSString stringWithFormat:@"createURL:%@", [url lastPathComponent]]);
            [document closeWithCompletionHandler:completionHandler];
        } else {
            NSAssert(FALSE, @"failed saveToRUL:%@", [document.fileURL lastPathComponent]);
            if (completionHandler) {
                completionHandler(NO);
            }
        }
    }];
}


+ (void)writeDataAtURL:(NSURL *)url data:(NSData *)data append:(BOOL)append completion:(void (^)(BOOL success))completion {
    [MHCloudDocument openURL:url
                      onOpen:^(MHCloudDocument *document) {
                          NSData *newData;
                          if (append) {
                              NSMutableData * tempData = [NSMutableData dataWithData:document.data];
                              [tempData appendData:data];
                              newData = tempData;
                          } else {
                              newData = data;
                          }
                          [document changeData:newData];
                      }
                  completion:completion];
}

@end

#pragma mark - MHCloudDocument

@implementation MHCloudDocument {
}

+ (void)openURL:(NSURL *)url onOpen:(void (^)(MHCloudDocument *))block completion:(void (^)(BOOL))completionHandler {
    NSParameterAssert([MHCloudHelper fileExistsAtURL:url]);
    MHCloudDocument *document = [[MHCloudDocument alloc] initWithFileURL:url];
    //[MHIndicatorView openWithCancelTarget:nil selector:nil];
    [document openWithCompletionHandler:^(BOOL success) {
        //[MHIndicatorView close];
        if (success) {
            logging(document, [NSString stringWithFormat:@"openURL:%@", [url lastPathComponent]]);
            block(document);
            [document closeWithCompletionHandler:completionHandler];
        } else {
            NSLog(@"open cloud url error:%@", [url absoluteString]);
            if (completionHandler) {
                completionHandler(NO);
            }
        }
        NSAssert(!success || [MHCloudHelper fileExistsAtURL:url], @"file not exists!:%@", [url absoluteString]);
    }];
}

- (void)changeData:(NSData *)newData {
    // if version conflict
    if (self.documentState & UIDocumentStateInConflict) {
        NSError *error;
        BOOL ok = [NSFileVersion removeOtherVersionsOfItemAtURL:self.fileURL error:&error];
        if (!ok) {
            NSAssert(ok, @"removeOtherVersionsOfItemAtURL:%@, %@", [self.fileURL lastPathComponent], error.description);
        }
        for (NSFileVersion *version in [NSFileVersion unresolvedConflictVersionsOfItemAtURL:self.fileURL]) {
            version.resolved = YES;
#ifdef DEBUG
            NSDateFormatter *fmt = dateFormatter();
            [fmt setDateFormat:@"YY/MM/dd HH:MM"];
            NSString *dateText = [fmt stringFromDate:version.modificationDate];
            NSLog(@"unresolved conflict date:%@, name:%@ computer:%@", dateText, version.localizedName, version.localizedNameOfSavingComputer);
#endif
        }
    }
    
    // set change count to save automatically at closing
    self.data = newData;
    [self updateChangeCount:UIDocumentChangeDone];
}

#pragma mark - protected methods
- (BOOL)loadFromContents:(id)contents ofType:(NSString *)typeName error:(NSError **)outError {
    NSLog(@"content type:%@", typeName);
    self.data = contents;
    return YES;
}

- (id)contentsForType:(NSString *)typeName error:(NSError **)outError {
    NSLog(@"contentsForType:%@ ", typeName);
    return _data;
}

@end

