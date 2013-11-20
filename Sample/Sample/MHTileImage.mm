//
//  MHTileImage.m
//  Sample
//
//  Created by tsuyoshi on 2013/11/20.
//  Copyright (c) 2013年 Tsuyoshi Miyano. All rights reserved.
//

#import <map>

#import <Foundation/Foundation.h>

#import "MHTileImage.h"

@interface MHTileImage ()
- (id)initWithImageNamed:(NSString *)imageName insets:(UIEdgeInsets)insets;
- (id)initWithImage:(UIImage *)image insets:(UIEdgeInsets)insets;
- (BOOL)setImage:(UIImage *)image insets:(UIEdgeInsets)insets;
- (void)drawRect:(CGRect)rect bounds:(CGRect)bounds;
- (void)drawRect:(CGRect)rect bounds:(CGRect)bounds context:(CGContextRef)context;
@end


typedef std::map<NSString *, __weak MHTileImage *, MHCompareNSString> CacheMap;

static CacheMap sCache;

@implementation MHTileImage {
    UIImage *_splitImages[9];
    UIEdgeInsets _splitInsets;
}

+ (UIImage *)createWithImage:(UIImage *)image inRect:(CGRect)rect {
    CGFloat scale = image.scale;
    CGRect copyRect = CGRectApplyAffineTransform(rect, CGAffineTransformMakeScale(scale, scale));
    CGImageRef imageRef = CGImageCreateWithImageInRect(image.CGImage, copyRect);
    UIImage *newImage = [UIImage imageWithCGImage:imageRef scale:image.scale orientation:image.imageOrientation];
    CGImageRelease(imageRef);
    return newImage;
}

+ (void)drawPatternImage:(CGContextRef)context destRect:(CGRect)destRect image:(UIImage *)image {
    NSParameterAssert(image);
    NSParameterAssert(context);
    NSParameterAssert(!CGRectIsEmpty(destRect));
    CGContextSaveGState(context);
    CGContextClipToRect(context, destRect);

    CGAffineTransform transform = CGAffineTransformMake(1.0, 0.0, 0.0, -1.0, 0.0, 0.0);
    transform.ty = CGRectGetHeight(destRect) + (destRect.origin.y * 2.0);
    CGContextConcatCTM(context, transform);
    CGContextDrawTiledImage(context, CGRectMake(destRect.origin.x, destRect.origin.y, image.size.width, image.size.height), [image CGImage]);

    CGContextRestoreGState(context);
}

+ (id)addImage:(NSString *)imageName splitInsets:(UIEdgeInsets)splitInsets {
    MHTileImage *obj = [self tileImage:imageName splitInsets:splitInsets];
    return obj;
}


+ (id)tileImage:(NSString *)imageName splitInsets:(UIEdgeInsets)splitInsets {
    MHTileImage *obj;
    
    CacheMap::iterator s = sCache.find(imageName);
    if (s != sCache.end()) {
        NSLog(@"hit cache for %@", imageName);
        obj = s->second;
    }
    
    //create new object
    if (!obj) {
        obj = [[MHTileImage alloc] initWithImageNamed:imageName insets:splitInsets];
    }

    //add to cache
    if (obj) {
        if (s == sCache.end()) {
            sCache.insert(CacheMap::value_type(imageName, obj));
        } else {
            s->second = obj;
        }
    }

    return obj;
}

+ (void)releaseCache {
    sCache.clear();
}

- (id)initWithImageNamed:(NSString *)imageName insets:(UIEdgeInsets)insets {
    self = [super init];
    if (self) {
        UIImage *image = [UIImage imageNamed:imageName];
        if (!image || ![self setImage:image insets:insets]) {
            self = nil;
        }
    }
    return self;
};

- (id)initWithImage:(UIImage *)image insets:(UIEdgeInsets)insets {
    self = [super init];
    if (self) {
        if (![self setImage:image insets:insets]) {
            self = nil;
        }
    }
    return self;
}

- (BOOL)setImage:(UIImage *)image insets:(UIEdgeInsets)insets {
    NSParameterAssert(image);
    _splitInsets = insets;
    CGFloat top = 0;
    CGFloat height = insets.top;
    BOOL ok = TRUE;
    for (int i = 0; i < 3; i++) {
        CGRect rects[3];
        rects[0] = CGRectMake(0, top, insets.left, height);
        rects[1] = CGRectMake(insets.left, top, image.size.width - (insets.left + insets.right), height);
        rects[2] = CGRectMake(image.size.width - insets.right, top,insets.right, height);
        for (int j = 0; j < 3; j++) {
            if (CGRectIsEmpty(rects[j])) {
                _splitImages[i * 3 + j] = nil;
                continue;
            }
            _splitImages[i * 3 + j] = [MHTileImage createWithImage:image inRect:rects[j]];
            if (!CGSizeEqualToSize(_splitImages[i * 3 + j].size, rects[j].size)) {
                NSLog(@"image-size:%f,%f", image.size.width, image.size.height);
                NSAssert(CGSizeEqualToSize(_splitImages[i * 3 + j].size, rects[j].size), @"check image size:image-size:%f,%f, rect-size:%f,%f", _splitImages[i * 3 + j].size.width, _splitImages[i * 3 + j].size.height, rects[j].size.width, rects[j].size.height);
                ok = FALSE;
            }
        }
        top = top + height;
        height = (i == 0) ? (image.size.height - (insets.top + insets.bottom)) : insets.bottom;
    }
    _size = image.size;
    return TRUE;
}

- (void)drawRect:(CGRect)rect bounds:(CGRect)bounds {
    CGContextRef context = UIGraphicsGetCurrentContext();
    [self drawRect:rect bounds:bounds context:context];
}

- (void)drawRect:(CGRect)rect bounds:(CGRect)bounds context:(CGContextRef)context {
    const UIEdgeInsets &insets = _splitInsets;
    
    CGContextSaveGState(context);
    CGContextClipToRect(context, rect);
    
    CGFloat height = insets.top;
    CGFloat top = 0;
    for (int i = 0; i < 3; i++) {
        CGRect rects[3];
        rects[0] = CGRectMake(0, top, insets.left, height);
        rects[1] = CGRectMake(insets.left, top, bounds.size.width - (insets.left + insets.right), height);
        rects[2] = CGRectMake(bounds.size.width - insets.right, top,insets.right, height);
        
        for (int j = 0; j < 3; j++) {
            if (MHRectIntersectsRect(rect, rects[j])) {
                [MHTileImage drawPatternImage:context destRect:rects[j] image:_splitImages[i * 3 + j]];
            }
        }
        top = top + height;
        height = (i == 0) ? (bounds.size.height - (insets.top + insets.bottom)) : insets.bottom;
    }
    
    CGContextRestoreGState(context);
}

- (UIImage *)create9SliceScallingImageWithSize:(CGSize)sz {
    UIImage *ret;
    if (sz.width == 0) {
        sz.width = self.size.width;
    }
    if (sz.height == 0) {
        sz.height = self.size.height;
    }
    
    UIGraphicsBeginImageContextWithOptions(sz, FALSE, 0.0f);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGRect bounds = CGRectMake(0, 0, sz.width, sz.height);
    [self drawRect:bounds bounds:bounds context:context];
    ret = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return ret;
};


@end
