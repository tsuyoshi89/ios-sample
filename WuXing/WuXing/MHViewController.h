//
//  MHViewController.h
//  WuXing
//
//  Created by tsuyoshi on 2013/11/22.
//  Copyright (c) 2013年 Tsuyoshi Miyano. All rights reserved.
//

#import <UIKit/UIKit.h>
//#import <GLKit/GLKit.h>

#ifdef ENABLE_EAGLEVIEW
@interface MHViewController : UIViewController
#else
@interface MHViewController : GLKViewController
#endif

@end
