//
//  MHCheckBox.h
//  dev@miyano-harikyu.jp
//
//  Created by Tsuyoshi MIYANO on 13/06/24.
//  Copyright (c) 2013年 Sola Co., Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MHCheckbox;

@protocol MHCheckboxDelegate  <NSObject>
@optional
- (BOOL)checkboxShouldChange:(MHCheckbox *)checkbox checked:(BOOL)checked;

@end
@interface MHCheckbox : UIButton

- (id)initWithImage:(UIImage *)normal checked:(UIImage *)checked disabled:(UIImage *)disabled;
- (void)setChecked:(BOOL)checked;
- (BOOL)isChecked;
- (void)toggleChecked;
- (void)setImage:(UIImage *)normal checked:(UIImage *)checked disabled:(UIImage *)disabled;

@property (nonatomic, weak) id<MHCheckboxDelegate> delegate;
@end
