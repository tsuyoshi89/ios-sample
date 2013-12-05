//
//  MHFileHelper.h
//  Sample
//
//  Created by tsuyoshi on 2013/11/22.
//  Copyright (c) 2013年 Tsuyoshi Miyano. All rights reserved.
//

@interface MHFileHelper : NSObject

/**
 * get temporary directory
 */
+ (NSString *)temporaryDirectoryPath;

/**
 * get document directory
 */
+ (NSString *)documentDirectoryPath;

/**
 * make path from direcotyr and filename
 */
+ (NSString *)makePath:(NSString *)dirPath withFileName:(NSString *)fileName;


/**
 * path exists or not
 */
+ (BOOL)fileExistsAtPath:(NSString *)path isDirectory:(BOOL *)isDirectory;
+ (BOOL)fileExistsAtURL:(NSURL *)path isDirectory:(BOOL *)isDirectory;

/**
 * path is file or not
 */
+ (BOOL)isFileAtPath:(NSString *)path;
+ (BOOL)isFileAtURL:(NSURL *)url;

/**
 * path is directory or not
 */
+ (BOOL)isDirectoryAtPath:(NSString *)path;
+ (BOOL)isDirectoryAtURL:(NSURL *)url;

+ (NSDate *)modificationDateAtPath:(NSString *)path;
+ (NSDate *)modificationDateAtURL:(NSURL *)url;

+ (NSDate *)creationDateAtPath:(NSString *)path;
+ (NSDate *)creationDateAtURL:(NSURL *)url;

+ (unsigned long long)fileSizeAtPath:(NSString *)path;
+ (unsigned long long)fileSizeAtURL:(NSURL *)url;

+ (BOOL)setModificationDateAtPath:(NSString *)path date:(NSDate *)date;
+ (BOOL)setModificationDateAtURL:(NSURL *)url date:(NSDate *)date;

/* pathのファイルがelapsedTimeを超えているか */
+ (NSTimeInterval)getElapsedFileModificationDateWithPath:(NSString *)path;

/**
 * get filename list for files in directory with extension
 */
+ (NSArray *)getFileNameListAtPath:(NSString *)directoryPath extension:(NSString *)extension;

/**
 * remove file or directory
 */
+ (BOOL)removeItemAtPath:(NSString *)path;
+ (BOOL)removeItemAtURL:(NSURL *)url;

/**
 * copy file or directory
 */
+ (BOOL)copyItemAtPath:(NSString *)path toPath:(NSString *)toPath;
+ (BOOL)copyItemAtURL:(NSURL *)url toURL:(NSURL *)toURL;

/**
 * move file or directory
 */
+ (BOOL)moveItemAtPath:(NSString *)path toPath:(NSString *)toPath;
+ (BOOL)moveItemAtURL:(NSURL *)url toURL:(NSURL *)toURL;

/**
 *documetn directory
 */
+ (NSString *)applicationDocumentsDirectoryPath;
+ (NSURL *)applicationDocumentsDirectoryURL;

/**
 *make file path in document directory
 */
+ (NSString *)makeDocumentPath:(NSString *)fileName;
+ (NSURL *)makeDocumentURL:(NSString *)fileName;

+ (NSString *)makeTemporaryPath:(NSString *)fileName;
+ (NSURL *)makeTemporaryURL:(NSString *)fileName;

+ (NSString *)makeTemporaryFilePath;
+ (NSURL *)makeTemporaryFileURL;

+ (NSString *)makeCachePath:(NSString *)fileName;
+ (NSURL *)makeCacheURL:(NSString *)fileName;

+ (BOOL)createFileAtPath:(NSString *)path contents:(NSData *)data attributes:(NSDictionary *)attributes;
+ (BOOL)createFileAtURL:(NSURL *)url contents:(NSData *)data attributes:(NSDictionary *)attributes;

+ (BOOL)writeDataAtPath:(NSString *)path contents:(NSData *)data append:(BOOL)append;
+ (BOOL)writeDataAtURL:(NSURL *)url contents:(NSData *)data append:(BOOL)append;

@end
