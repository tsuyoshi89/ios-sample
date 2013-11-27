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
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button setTitle:@"unlink with facebook" forState:UIControlStateNormal];
    button.frame = CGRectMake(30, 100, 200, 30);
    [button addTarget:self action:@selector(unlink) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
    
    button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button setTitle:@"link with facebook" forState:UIControlStateNormal];
    button.frame = CGRectMake(30, 50, 200, 30);
    [button addTarget:self action:@selector(link) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
    

    button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button setTitle:@"post to facebook" forState:UIControlStateNormal];
    button.frame = CGRectMake(30, 150, 200, 30);
    [button addTarget:self action:@selector(post) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];

    button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button setTitle:@"delete account" forState:UIControlStateNormal];
    button.frame = CGRectMake(30, 200, 200, 30);
    [button addTarget:self action:@selector(deleteAccount) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];

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

#pragma mark - action
- (void)unlink {
    [[MHKiiHelper sharedInstance] unLinkWithFacebookAccountWithBlock:^(BOOL success) {
        NSLog(@"did unlink:%d", success);
    }];
}

- (void)link {
    [[MHKiiHelper sharedInstance] linkWithFacebookAccountWithBlock:^(BOOL success) {
        NSLog(@"did link:%d", success);
    }];
}

- (void)post {
    
}

- (void)deleteAccount {
    [[MHKiiHelper sharedInstance] deleteAccountWithBlock:^(BOOL success) {
        NSLog(@"did delete account:%d", success);
    }];
}
@end
