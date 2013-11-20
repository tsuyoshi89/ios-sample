//
//  MHTileImage.h
//  Sample
//
//  Created by tsuyoshi on 2013/11/20.
//  Copyright (c) 2013年 Tsuyoshi Miyano. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MHTileImage : NSObject

+ (id)tileImage:(NSString *)imageName splitInsets:(UIEdgeInsets)splitInsets;

/*
 * load image add add it to cache
 */
+ (id)addImage:(NSString *)imageName splitInsets:(UIEdgeInsets)splitInsets;

/*
 * release added images.
 */
+ (void)releaseCache;

/*
 * create 9-slice scaling image
 */
- (UIImage *)create9SliceScallingImageWithSize:(CGSize)sz;

@property (nonatomic, readonly, assign) CGSize size;

@end

