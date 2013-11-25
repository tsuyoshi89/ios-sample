//
//  MHCheckBox.m
//  dev@miyano-harikyu.jp
//
//  Created by Tsuyoshi MIYANO on 13/06/24.
//  Copyright (c) 2013年 Sola Co., Ltd. All rights reserved.
//

#import "MHCheckbox.h"

@implementation MHCheckbox


- (id)initWithImage:(UIImage *)normal checked:(UIImage *)checked disabled:(UIImage *)disabled {
    self = [self initWithFrame:CGRectMake(0, 0, normal.size.width, normal.size.height)];
    if (self) {
        [self setImage:normal checked:checked disabled:disabled];
    }
    return self;
};

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.userInteractionEnabled = TRUE;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.userInteractionEnabled = TRUE;
    }
    return self;
}

- (void)setUserInteractionEnabled:(BOOL)userInteractionEnabled {
    [super setUserInteractionEnabled:userInteractionEnabled];
    if (userInteractionEnabled) {
        [self addTarget:self action:@selector(checkboxTapped:) forControlEvents:UIControlEventTouchUpInside];
    } else {
        [self removeTarget:self action:@selector(checkboxTapped:) forControlEvents:UIControlEventTouchUpInside];
    }
}

- (void)setChecked:(BOOL)checked {
    self.selected = checked;
}

- (BOOL)isChecked {
    return self.selected;
}

- (void)toggleChecked {
    self.selected = !self.selected;
}

- (void)setImage:(UIImage *)normal checked:(UIImage *)checked disabled:(UIImage *)disabled {
    [self setBackgroundImage:normal forState:UIControlStateNormal];
    [self setBackgroundImage:checked forState:UIControlStateSelected];
    [self setBackgroundImage:normal forState:UIControlStateHighlighted];
    [self setBackgroundImage:disabled forState:UIControlStateDisabled];
}

#pragma mark - private method
- (void)checkboxTapped:(MHCheckbox *)button {
    if ([_delegate respondsToSelector:@selector(checkboxShouldChange:checked:)]) {
        if (![_delegate checkboxShouldChange:self checked:!button.selected]) {
            return;
        }
    }

    button.selected = !button.selected;
    [button sendActionsForControlEvents:UIControlEventValueChanged];
}

@end
