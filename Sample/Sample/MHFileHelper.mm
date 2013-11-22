//
//  MHFileHelper.m
//  Sample
//
//  Created by tsuyoshi on 2013/11/22.
//  Copyright (c) 2013年 Tsuyoshi Miyano. All rights reserved.
//

#import "MHFileHelper.h"

@implementation MHFileHelper


+ (NSString *)temporaryDirectoryPath {
    return NSTemporaryDirectory();
}

+ (NSString *)documentDirectoryPath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(
                                                         NSDocumentDirectory,
                                                         NSUserDomainMask,
                                                         YES);
    NSAssert([paths objectAtIndex:0] != nil, @"document Directory error");
    return [paths objectAtIndex:0];
}

+ (NSString *)makePath:(NSString *)dirPath withFileName:(NSString *)fileName {
    NSAssert(dirPath != nil, @"dirPath must be not null");
    NSAssert(fileName != nil, @"fileName must be not null");
    return [dirPath stringByAppendingPathComponent:fileName];
}

+ (BOOL)fileExistsAtPath:(NSString *)path isDirectory:(BOOL *)isDirectory {
    NSFileManager* fileManager = [[NSFileManager alloc] init];
    BOOL ret = [fileManager fileExistsAtPath:path isDirectory:isDirectory];
    return ret;
}

+ (BOOL)fileExistsAtURL:(NSURL *)url isDirectory:(BOOL *)isDirectory {
    return [self fileExistsAtPath:[url path] isDirectory:isDirectory];
}

+ (BOOL)isFileAtPath:(NSString *)path {
    BOOL ret = NO;
    BOOL isDirectory = NO;
    if ([self fileExistsAtPath:path isDirectory:&isDirectory]) {
        ret = !isDirectory;
    };
    return ret;
}

+ (BOOL)isFileAtURL:(NSURL *)url {
    return [self isFileAtPath:[url path]];
}


+ (BOOL)isDirectoryAtPath:(NSString *)path {
    BOOL isDirectory = NO;
    [self fileExistsAtPath:path isDirectory:&isDirectory];
    return isDirectory;
}

+ (BOOL)isDirectoryAtURL:(NSURL *)url {
    return [self isDirectoryAtPath:[url path]];
}

+ (NSDate *)modificationDateAtPath:(NSString *)path {
    NSDate *ret;
    NSError *error = nil;
    NSDictionary* dicFileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:&error];
    if (error) {
        NSAssert(FALSE, @"get attributes of item:%@, %@", path, error.description);
    } else {
        ret = dicFileAttributes.fileModificationDate;
    }
    return ret;
}

+ (NSDate *)modificationDateAtURL:(NSURL *)url {
    return [self modificationDateAtPath:[url path]];
}

+ (NSDate *)creationDateAtPath:(NSString *)path {
    NSDate *ret;
    NSError *error = nil;
    NSDictionary* dicFileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:&error];
    if (error) {
        NSAssert(FALSE, @"get attributes of item:%@, %@", path, error.description);
    } else {
        ret = dicFileAttributes.fileCreationDate;
    }
    return ret;
}

+ (NSDate *)creationDateAtURL:(NSURL *)url {
    return [self creationDateAtPath:[url path]];
}

+ (unsigned long long)fileSizeAtPath:(NSString *)path {
    unsigned long long ret = 0;
    NSError *error = nil;
    NSDictionary* dicFileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:&error];
    if (error) {
        NSAssert(FALSE, @"get attributes of item:%@, %@", path, error.description);
    } else {
        ret = dicFileAttributes.fileSize;
    }
    return ret;
}

+ (unsigned long long)fileSizeAtURL:(NSURL *)url {
    return [self fileSizeAtPath:[url path]];
}


+ (BOOL)setModificationDateAtPath:(NSString *)path date:(NSDate *)date {
    NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:date ,NSFileModificationDate, nil];
    NSError *error;
    BOOL ok = [[NSFileManager defaultManager] setAttributes:attrs ofItemAtPath:path error: &error];
    NSAssert(ok, @"failed set attributes:%@", error.description);
    return ok;
}

+ (BOOL)setModificationDateAtURL:(NSURL *)url date:(NSDate *)date {
    return [self setModificationDateAtPath:[url path] date:date];
}

+ (NSTimeInterval)getElapsedFileModificationDateWithPath:(NSString *)path {
    NSTimeInterval ret = (NSTimeInterval)0;
    if ([self fileExistsAtPath:path isDirectory:nil]) {
        NSError *error = nil;
        NSDictionary* dicFileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:&error];
        if (error) {
            NSAssert(FALSE, @"get attributes of item:%@, %@", path, error.description);
        } else {
            /* diff between current time and last update time */
            ret   = [[NSDate dateWithTimeIntervalSinceNow:0.0] timeIntervalSinceDate:dicFileAttributes.fileModificationDate];
        }
    } else {
        NSAssert(FALSE, @"path:%@ is not exit", path);
    }
    
    return ret;
}

+ (NSArray *)getFileNameListAtPath:(NSString *)directoryPath extension:(NSString *)extension {
    NSMutableArray *fileNames = [[NSMutableArray alloc] init];
    
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSError *error = nil;
    
    NSArray *allFileName = [fileManager contentsOfDirectoryAtPath:directoryPath error:&error];
    if (error) {
        NSAssert(FALSE, @"error contentsOfDirectoryAtPath:%@ %@",directoryPath, error.description);
    } else {
        for (NSString *fileName in allFileName) {
            if (!extension || [[fileName pathExtension] isEqualToString:extension]) {
                [fileNames addObject:fileName];
            }
        }
    }
    return fileNames;
}

+ (BOOL)removeItemAtPath:(NSString *)path {
    NSAssert([self fileExistsAtPath:path isDirectory:nil], @"path:%@ not exists", path);
    
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSError *error;
    BOOL ret = [fileManager removeItemAtPath:path error:&error];
    NSAssert(ret, @"error removeItemAtPath:%@, %@", path, error.description);
    return ret;
}

+ (BOOL)removeItemAtURL:(NSURL *)url {
    NSAssert([self fileExistsAtURL:url isDirectory:nil], @"path:%@ not exists", [url absoluteString]);
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSError *error;
    BOOL ret = [fileManager removeItemAtURL:url error:&error];
    NSAssert(ret, @"error removeItemAtURL:%@, %@", [url absoluteString], error.description);
    return ret;
}

+ (BOOL)copyItemAtPath:(NSString *)path toPath:(NSString *)toPath {
    NSAssert([self fileExistsAtPath:path isDirectory:nil], @"path:%@ not exists", path);
    NSAssert(![self fileExistsAtPath:toPath isDirectory:nil], @"toPath:%@ exists", toPath);
    
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSError *error;
    BOOL ret = [fileManager copyItemAtPath:path toPath:toPath error:&error];
    NSAssert(ret, @"error copyItemAtPath:%@, %@, %@", path, toPath, error.description);
    return ret;
}

+ (BOOL)copyItemAtURL:(NSURL *)url toURL:(NSURL *)toUrl {
    NSAssert([self fileExistsAtURL:url isDirectory:nil], @"path:%@ not exists", [url absoluteString]);
    NSAssert(![self fileExistsAtURL:toUrl isDirectory:nil], @"toPath:%@ exists", [toUrl absoluteString]);
    
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSError *error;
    BOOL ret = [fileManager copyItemAtURL:url toURL:toUrl error:&error];
    NSAssert(ret, @"error copyItemAtPath:%@, %@, %@", [url absoluteString], [toUrl absoluteString], error.description);
    return ret;
}

+ (BOOL)moveItemAtPath:(NSString *)path toPath:(NSString *)toPath {
    NSAssert([self fileExistsAtPath:path isDirectory:nil], @"path: %@ should exists", path);
    NSAssert(![self fileExistsAtPath:toPath isDirectory:nil], @"toPath: %@ should not exists", toPath);
    
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSError *error;
    BOOL ret = [fileManager moveItemAtPath:path toPath:toPath error:&error];
    NSAssert(ret, @"error moveItemAtPath:%@, %@, %@", path, toPath, error.description);
    return ret;
}

+ (BOOL)moveItemAtURL:(NSURL *)url toURL:(NSURL *)toUrl {
    NSAssert([self fileExistsAtURL:url isDirectory:nil], @"path:%@ not exists", [url absoluteString]);
    NSAssert(![self fileExistsAtURL:toUrl isDirectory:nil], @"toPath:%@ exists", [toUrl absoluteString]);
    
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSError *error;
    BOOL ret = [fileManager moveItemAtURL:url toURL:toUrl error:&error];
    NSAssert(ret, @"error moveItemAtPath:%@, %@, %@", [url absoluteString], [toUrl absoluteString], error.description);
    return ret;
}

+ (NSString *)applicationDocumentsDirectoryPath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *dir = [paths objectAtIndex:0];
    return dir;
}

+ (NSURL *)applicationDocumentsDirectoryURL {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

+ (NSString *)makeDocumentPath:(NSString *)fileName {
    NSString *path = [[self applicationDocumentsDirectoryPath] stringByAppendingPathComponent:fileName];
    return path;
}

+ (NSURL *)makeDocumentURL:(NSString *)fileName {
    NSURL *url = [[self applicationDocumentsDirectoryURL] URLByAppendingPathComponent:fileName];
    return url;
}

+ (NSString *)makeTemporaryPath:(NSString *)fileName {
    NSString *dir = NSTemporaryDirectory();
    NSString *path = [dir stringByAppendingPathComponent:fileName];
    return path;
}

+ (NSURL *)makeTemporaryURL:(NSString *)fileName {
    return [NSURL fileURLWithPath:[self makeTemporaryPath:fileName]];
}


+ (NSString *)makeTemporaryFilePath {
    static int sequentialNo = 0;
    sequentialNo += 1;
    return [NSTemporaryDirectory() stringByAppendingPathComponent: [NSString stringWithFormat: @"%.0f_%d.%@", [NSDate timeIntervalSinceReferenceDate] * 1000.0, sequentialNo, @"tmp"]];
}

+ (NSURL *)makeTemporaryFileURL {
    return  [NSURL fileURLWithPath:[self makeTemporaryFilePath]];
}

+ (NSString *)makeCachePath:(NSString *)fileName {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *path = [paths objectAtIndex:0];
    return [path stringByAppendingPathComponent:fileName];
}

+ (NSURL *)makeCacheURL:(NSString *)fileName {
    return [NSURL fileURLWithPath:[self makeCachePath:fileName]];
}

+ (BOOL)createFileAtPath:(NSString *)path contents:(NSData *)data attributes:(NSDictionary *)attributes {
    NSFileManager *manager = [[NSFileManager alloc] init];
    BOOL ok = [manager createFileAtPath:path contents:data attributes:attributes];
    NSAssert(ok, @"failed to create file:%@", path);
    return ok;
}

+ (BOOL)createFileAtURL:(NSURL *)url contents:(NSData *)data attributes:(NSDictionary *)attributes {
    return [self createFileAtPath:[url path] contents:data attributes:attributes];
}

+ (BOOL)writeDataAtPath:(NSString *)path contents:(NSData *)data append:(BOOL)append {
    NSParameterAssert([self fileExistsAtPath:path isDirectory:nil]);
    NSFileHandle *fh = [NSFileHandle fileHandleForWritingAtPath:path];
    BOOL ok = TRUE;
    @try {
        if (append) {
            [fh seekToEndOfFile];
        }
        [fh writeData:data];
    } @catch (NSException *e) {
        NSLog(@"write data error:%@", e.description);
        ok = FALSE;
    } @finally {
        [fh closeFile];
    }
    return ok;
}

+ (BOOL)writeDataAtURL:(NSURL *)url contents:(NSData *)data append:(BOOL)append {
    return [self writeDataAtPath:[url path] contents:data append:append];
}

@end
