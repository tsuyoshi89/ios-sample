//
//  MHImage.h
//  eMon
//
//  Created by tsuyoshi on 2013/11/22.
//
//

#import <Foundation/Foundation.h>

@interface UIImage (MHImage)
+ (UIImage *)createColorImage:(CGSize)sz color:(UIColor *)color;
+ (UIImage *)createColorPatternImage:(CGSize)sz color1:(UIColor *)color1 color2:(UIColor *)color2;

- (UIImage *)createWithMask:(UIImage *)maskImage;

- (UIImage *)resize:(CGSize)sz backgroundColor:(UIColor *)color;

- (UIImage *)createImageInRect:(CGRect)rect;

@end


@interface UIImageView (MHImage)
- (CGRect)getImageRect;
+ (CGRect)convertAspectFitRect:(CGSize)contentSize bounds:(CGRect)bounds;
@end

@interface UIView (MHImage)
- (UIImage *)getClipImageWithPath:(UIBezierPath *)path maskImage:(UIImage *)maskImage;
@end