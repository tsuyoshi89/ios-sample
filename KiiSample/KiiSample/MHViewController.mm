//
//  MHViewController.m
//  KiiSample
//
//  Created by tsuyoshi on 2013/11/27.
//  Copyright (c) 2013年 Tsuyoshi Miyano. All rights reserved.
//

#import "common.h"

#import "MHKiiHelper.h"
#import "MHViewController.h"
#import "MHSelectViewController.h"
#import <FacebookSDK/FacebookSDK.h>


@interface MHViewController () <UIGestureRecognizerDelegate>

@property (nonatomic ,strong) UIView *containerView;
@property (nonatomic, strong) NSString *bucketName;
@property (nonatomic, strong, readonly) KiiBucket *bucket;
@end

@implementation MHViewController {
    KTTableViewController *_tableVC;
    __weak UITextField *_bucketField;
}

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

    self.navigationItem.title = @"Kii Cloud 管理ツール";

    CGFloat posY = 80;
    NSArray *names = [self createField:posY label:@"Bucket Name:" placeFolder:@"input bucket name"];
    UITextField *label = [names objectAtIndex:0];
    UITextField *name = [names objectAtIndex:1];
    label.frame = CGRectMake(10, posY, 90, 30);
    name.frame = CGRectMake(CGRectGetMaxX(label.frame), posY, 110, 30);
    name.text = [KiiManager sharedInstance].bucketName;
    _bucketField = name;

    UITextField *userMode = [[UITextField alloc] initWithFrame:CGRectMake(CGRectGetMaxX(name.frame) + 10, posY, 60, 30)];
    userMode.userInteractionEnabled = FALSE;
    userMode.font = [UIFont boldSystemFontOfSize:13.0f];
    userMode.textColor = [UIColor brownColor];
    userMode.text = @"user";
    UISwitch *sw = [[UISwitch alloc] init];
    sw.selected = NO;
    sw.center = CGPointMake(CGRectGetMaxX(userMode.frame) , userMode.center.y);
    [sw addTarget:self action:@selector(userMode:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:userMode];
    [self.view addSubview:sw];
    posY += 30;

    UIButton *queryButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    queryButton.frame = CGRectMake(CGRectGetMinX(label.frame), posY , 50, 30);
    [queryButton setTitle:@"Query" forState:UIControlStateNormal];
    [queryButton addTarget:self action:@selector(query) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:queryButton];
    
    UIButton *newButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [newButton setTitle:@"New" forState:UIControlStateNormal];
    newButton.frame = CGRectMake(CGRectGetMaxX(queryButton.frame) + 10, posY, 50, 30);
    [newButton addTarget:self action:@selector(newObject) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:newButton];

    posY += 40;

    CGRect bounds = self.view.bounds;
    self.containerView = [[UIView alloc] initWithFrame:CGRectMake(0, posY, bounds.size.width, bounds.size.height - posY)];
    self.containerView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:self.containerView];
    
    UIViewController *vc = _tableVC = [[MHSelectViewController alloc] init];
    [self addChildViewController:vc];
    [self.containerView addSubview:vc.view];
    [vc didMoveToParentViewController:self];
    vc.view.frame = self.containerView.bounds;

    [sw setOn:[KiiManager sharedInstance].userMode];

#if 1
    UITapGestureRecognizer *recog = [[UITapGestureRecognizer alloc] initWithTarget:nil action:nil];
    recog.delegate = self;
    [self.view addGestureRecognizer:recog];
#endif
    
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"object"]) {
        [self query];
    }
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [[MHKiiHelper sharedInstance] loginWithBlock:^(BOOL success) {
        if (success) {
            [self query];
        } else {
            UIViewController *vc = [[KTLoginViewController alloc] init];
            [self presentViewController:vc animated:YES completion:^{
                
            }];
        }
    }];
    [[KiiManager sharedInstance] addObserver:self forKeyPath:@"object" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)viewDidDisappear:(BOOL)animated {
    [[KiiManager sharedInstance] removeObserver:self forKeyPath:@"object"];
    [super viewDidDisappear:animated];
}

- (void)userMode:(UISwitch *)sender {
    [KiiManager sharedInstance].userMode = sender.isOn;
}

- (void)query {
    if (_bucketField.text.length > 0) {
        [KiiManager sharedInstance].bucketName = _bucketField.text;
    }
    _tableVC.bucket = [KiiManager sharedInstance].bucket;
    _tableVC.query = [KiiQuery queryWithClause:nil];
    [_tableVC refreshQuery];
}

- (void)newObject {
    if (_bucketField.text.length > 0) {
        [KiiManager sharedInstance].bucketName = _bucketField.text;
    }
    [[KiiManager sharedInstance] newObject];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    for (UIView *view in self.view.subviews) {
        if (view.isFirstResponder) {
            [view resignFirstResponder];
            break;
        }
    }
    return FALSE;
}
@end
