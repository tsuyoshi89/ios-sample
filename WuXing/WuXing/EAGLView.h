//
//  EAGLView.h
//  WuXing
//
//  Created by tsuyoshi on 2013/11/26.
//  Copyright (c) 2013年 Tsuyoshi Miyano. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EAGLView : UIView

@property (nonatomic, strong) EAGLContext *context;

- (void)setFramebuffer;
- (BOOL)presentFramebuffer;

@end
