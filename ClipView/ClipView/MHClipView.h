//
//  MHClipView.h
//  MHLib
//
//  Created by tsuyoshi on 2013/10/04.
//  Copyright (c) 2013年 Sola Co., Ltd. All rights reserved.
//

typedef enum {
    MHClipViewShapeCircle = 0,
    MHClipViewShapeMaskImage
} MHCLipViewShap;

@interface MHClipView : UIView

- (id)initWithFrame:(CGRect)rect margin:(CGFloat)margin;
- (UIBezierPath *)getClipPath;
@property (nonatomic ,assign) MHCLipViewShap shape;
@property (nonatomic, strong) UIImage *maskImage;

@end
