//
//  common.h
//  KiiSample
//
//  Created by tsuyoshi on 2013/11/27.
//  Copyright (c) 2013年 Tsuyoshi Miyano. All rights reserved.
//

#ifndef KiiSample_common_h
#define KiiSample_common_h

//#define YOUR_KII_APP_ID
//#define YOUR_KII_APP_KEY

@interface UIViewController (KiiSample)
- (NSArray *)createField:(CGFloat)y label:(NSString *)labelText placeFolder:(NSString *)placeFolder;
@end


#endif
