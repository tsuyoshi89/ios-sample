//
//  MHClipViewController.h
//  MHLib
//
//  Created by tsuyoshi on 2013/10/04.
//  Copyright (c) 2013年 Sola Co., Ltd. All rights reserved.
//

typedef void (^MHClipViewCompletionBlock)(UIImage *image);
@interface MHClipViewController : UIViewController

- (id)initWithMaskImage:(UIImage *)maskImage;
- (id)initWithClipSize:(CGSize)clipSize;

@property (nonatomic, strong) UIColor *backgroundColor;

@property (nonatomic, strong) MHClipViewCompletionBlock completionBlock;

@end
