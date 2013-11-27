//
//  MHViewController.m
//  KiiSample
//
//  Created by tsuyoshi on 2013/11/27.
//  Copyright (c) 2013年 Tsuyoshi Miyano. All rights reserved.
//

#import "MHKiiHelper.h"
#import "MHViewController.h"

@interface MHViewController ()

@end

@implementation MHViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [[MHKiiHelper sharedInstance] loginWithBlock:^(BOOL success) {
        if (!success) {
            UIViewController *vc = [[KTLoginViewController alloc] init];
            [self presentViewController:vc animated:YES completion:^{
                
            }];
            
        }
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
