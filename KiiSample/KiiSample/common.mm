//
//  common.mm
//  KiiSample
//
//  Created by tsuyoshi on 2013/11/27.
//  Copyright (c) 2013年 Tsuyoshi Miyano. All rights reserved.
//

#import "common.h"

@implementation UIViewController (KiiSample)

- (NSArray *)createField:(CGFloat)y label:(NSString *)labelText placeFolder:(NSString *)placeFolder {
    UITextField *label = [[UITextField alloc] initWithFrame:CGRectMake(10, y, 70, 30)];
    label.text = labelText;
    label.userInteractionEnabled = FALSE;
    label.font = [UIFont boldSystemFontOfSize:13.0f];
    label.textColor = [UIColor brownColor];
    
    UITextField *field = [[UITextField alloc] initWithFrame:CGRectMake(CGRectGetMaxX(label.frame), y, 250, 30)];
    field.placeholder = placeFolder;
    field.minimumFontSize = 8.0f;
    field.font = [UIFont systemFontOfSize:12];
    
    [self.view addSubview:label];
    [self.view addSubview:field];
    return @[label, field];
}

@end
