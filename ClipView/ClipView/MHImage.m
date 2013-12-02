//
//  MHImage.m
//  eMon
//
//  Created by tsuyoshi on 2013/11/22.
//
//

#import "MHImage.h"

@implementation UIImage (MImage)

+ (UIImage *)createColorImage:(CGSize)sz color:(UIColor *)color {
    UIImage *result;
    UIGraphicsBeginImageContextWithOptions(sz, NO, 0);
    if (color) {
        [[UIColor redColor] setFill];
        UIRectFill(CGRectMake(0, 0, sz.width, sz.height));
    }
    result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    NSAssert(result, @"Error: failed create image");
    return result;
}

+ (UIImage *)createColorPatternImage:(CGSize)sz color1:(UIColor *)color1 color2:(UIColor *)color2 {
    UIImage *result;
    UIGraphicsBeginImageContextWithOptions(sz, NO, 0);

    [color2 setFill];
    UIRectFill(CGRectMake(0, 0, sz.width, sz.height));
    
    [color1 setFill];
    UIRectFill(CGRectMake(0, 0, sz.width / 2, sz.height / 2));
    UIRectFill(CGRectMake(sz.width / 2, sz.height / 2, sz.width / 2, sz.height / 2));

    result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return result;
}

- (UIImage *)createWithMask:(UIImage *)maskImage {
    
    CGImageRef maskImageRef = maskImage.CGImage;
    
    CGImageRef mask = CGImageMaskCreate(CGImageGetWidth(maskImageRef),
                                        CGImageGetHeight(maskImageRef),
                                        CGImageGetBitsPerComponent(maskImageRef),
                                        CGImageGetBitsPerPixel(maskImageRef),
                                        CGImageGetBytesPerRow(maskImageRef),
                                        CGImageGetDataProvider(maskImageRef), NULL, NO); //マスクを作成
    
    CGImageRef masked = CGImageCreateWithMask(self.CGImage, mask); //マスクの形に切り抜く
    
    UIImage *ret = [UIImage imageWithCGImage:masked];
    
    CGImageRelease(mask);
    CGImageRelease(masked);
    
    return ret;
}

- (UIImage *)resize:(CGSize)sz backgroundColor:(UIColor *)color {
    UIImage *result;
    UIGraphicsBeginImageContextWithOptions(sz, NO, self.scale);
    if (color) {
        [color setFill];
        UIRectFill(CGRectMake(0, 0, sz.width, sz.height));
    }
    [self drawInRect:CGRectMake(0, 0, sz.width, sz.height)];
    result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return result;
}

- (UIImage *)createImageInRect:(CGRect)rect {
    CGFloat scale = self.scale;
    CGRect copyRect = CGRectApplyAffineTransform(rect, CGAffineTransformMakeScale(scale, scale));
    CGImageRef imageRef = CGImageCreateWithImageInRect(self.CGImage, copyRect);
    UIImage *newImage = [UIImage imageWithCGImage:imageRef scale:self.scale orientation:self.imageOrientation];
    CGImageRelease(imageRef);
    return newImage;
}

@end

@implementation UIImageView (MHImage)
- (CGRect)getImageRect {
    UIImage *image = self.image;
    if (image) {
        return [UIImageView convertAspectFitRect:image.size bounds:self.bounds];
    }
    return CGRectZero;
}

+ (CGRect)convertAspectFitRect:(CGSize)contentSize bounds:(CGRect)bounds {
    CGFloat contentScale = fminf(CGRectGetWidth(bounds) / contentSize.width, CGRectGetHeight(bounds) / contentSize.height);
    CGSize scaledContentSize = CGSizeMake(contentSize.width * contentScale, contentSize.height * contentScale);
    CGRect contentFrame = CGRectMake(roundf(0.5f * (CGRectGetWidth(bounds) - scaledContentSize.width)), roundf(0.5f * (CGRectGetHeight(bounds) - scaledContentSize.height)), roundf(scaledContentSize.width), roundf(scaledContentSize.height));
    return contentFrame;
}

@end

@implementation UIView (MHImage)
- (UIImage *)getClipImageWithPath:(UIBezierPath *)path maskImage:(UIImage *)maskImage {
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, 0.0f);
    CGContextRef context = UIGraphicsGetCurrentContext();
    [path addClip];
    [self.layer renderInContext:context];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    CGRect clipBounds = [path bounds];
    image  =[image createImageInRect:clipBounds];
    if (maskImage) {
        image = [image createWithMask:maskImage];
    }
    return image;
}
@end