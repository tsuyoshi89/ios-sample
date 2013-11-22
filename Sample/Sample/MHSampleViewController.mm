//
//  MHSampleViewController.m
//  Sample
//
//  Created by tsuyoshi on 2013/11/20.
//  Copyright (c) 2013年 Tsuyoshi Miyano. All rights reserved.
//

#import "MHSampleViewController.h"

#import "MHTileImage.h"
#import "MHJob.h"
#import "MHCloudHelper.h"
#import "MHFileHelper.h"

@interface MHSampleViewController () <MHCloudStateObserver>

@end


@implementation MHSampleViewController {
    NSURL *_containerURL;
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
    
    UIEdgeInsets insets = UIEdgeInsetsMake(20, 30, 30, 30);
    

    UIImage *originalImage = [UIImage imageNamed:@"hukidashi.png"];
    UIImage *resizableImage = [originalImage resizableImageWithCapInsets:insets resizingMode:UIImageResizingModeTile];

    CGFloat offsetY = 50;
    
    //case 0
    UIImageView *originalView = [[UIImageView alloc] initWithImage:originalImage];
    [originalView setFrame:CGRectMake(20, 10 + offsetY, originalImage.size.width, originalImage.size.height)];
    offsetY += originalImage.size.height + 10;

    //case 05
    UIImageView *scaleView = [[UIImageView alloc] initWithImage:originalImage];
    [scaleView setFrame:CGRectMake(20, 10 + offsetY, 280, 100)];
    [scaleView setContentMode:UIViewContentModeScaleToFill];
    offsetY += 110;

    //case 1
    UIImageView *resizableView = [[UIImageView alloc] initWithImage:resizableImage];
    [resizableView setContentMode:UIViewContentModeScaleToFill];
    [resizableView setFrame:CGRectMake(20, 10 + offsetY, 280, 100)];

    //case 2
    CGRect rect = CGRectMake(0, 0, 280, 100);
    UIGraphicsBeginImageContextWithOptions(rect.size, FALSE, 0.0f);
    [resizableImage drawInRect:rect];
    UIImage *resizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    UIImageView *resizedView = [[UIImageView alloc] initWithImage:resizedImage];
    [resizedView setFrame:CGRectMake(20, 120 + offsetY, 280, 100)];

    //case 3
    UIImage *myResizedImage = [[MHTileImage tileImage:@"hukidashi.png" splitInsets:insets] create9SliceScallingImageWithSize:CGSizeMake(280, 100)];
    UIView *myResizedView = [[UIImageView alloc] initWithImage:myResizedImage];
    [myResizedView setFrame:CGRectMake(20, 230 + offsetY, 280, 100)];

    
    [self.view addSubview:originalView];
    [self.view addSubview:scaleView];
    [self.view addSubview:resizableView];
    [self.view addSubview:resizedView];
    [self.view addSubview:myResizedView];
    
    UILabel *label0 = [[UILabel alloc] init];
    label0.text = @"オリジナル";
    [label0 sizeToFit];
    label0.center = originalView.center;

    UILabel *label05 = [[UILabel alloc] init];
    label05.text = @"オリジナルをScaleToFillで拡大";
    [label05 sizeToFit];
    label05.center = scaleView.center;

    UILabel *label1 = [[UILabel alloc] init];
    label1.text = @"resizableImageで拡大";
    [label1 sizeToFit];
    label1.center = resizableView.center;

    UILabel *label2 = [[UILabel alloc] init];
    label2.text = @"resizableImageを描画して拡大";
    [label2 sizeToFit];
    label2.center = resizedView.center;

    UILabel *label3 = [[UILabel alloc] init];
    label3.text = @"自力でタイリングして拡大";
    [label3 sizeToFit];
    label3.center = myResizedView.center;
    
    [self.view addSubview:label0];
    [self.view addSubview:label05];
    [self.view addSubview:label1];
    [self.view addSubview:label2];
    [self.view addSubview:label3];
    
    MHJob *job = [[MHJob alloc] init];
    job.isBackgroundTask = YES;
    job.expirationBlock = ^(MHJob *job){
        //[job cancel];//jobを中止する

    };
    job.completionBlock = ^(BOOL success) {
        NSLog(@"completion(%d)!", success);
    };
    [job run:^(MHJob *job){
        while (1) {
            //NSLog(@"remain:%4.1f", [[UIApplication sharedApplication] backgroundTimeRemaining]);
            int count = [[UIApplication sharedApplication] applicationIconBadgeNumber] + 1;
            [[UIApplication sharedApplication] setApplicationIconBadgeNumber:count];
            if (job.state == MHJobState_Canceling) {
                return;
            }
            [job wait:1];
            count += 1;
        }
    }];
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    button.frame = CGRectMake(160, 50, 150, 50);
    [button setTitle:@"save badge number" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(saveNumber) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
    
    [[MHCloudHelper sharedInstance] addStateObserver:self];
}

- (void)saveNumber {
    if (!_containerURL) {
        NSLog(@"please, login icloud");
        return;
    }

    int num = [[UIApplication sharedApplication] applicationIconBadgeNumber];
    NSData *data = [NSData dataWithBytes:&num length:sizeof(num)];

    if ([MHCloudHelper fileExistsAtURL:_containerURL]) {
        [MHCloudHelper writeDataAtURL:_containerURL data:data append:NO completion:^(BOOL success) {
            NSLog(@"update cloud file:%d", success);
        }];
    } else {
        [MHCloudHelper createItemAtURL:_containerURL data:data completion:^(BOOL success) {
            NSLog(@"create cloud file:%d", success);
        }];
    }
   
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)cloudAvailabilityChanged:(BOOL)available tokenChanged:(BOOL)tokenChanged {
    if (!available) {
        _containerURL = nil;
        return;
    }
    _containerURL = [[MHCloudHelper sharedInstance] documentsURLByAppendingPathComponent:@"badge.txt"];
    
    if ([MHCloudHelper fileExistsAtURL:_containerURL]) {
        NSData *data = [NSData dataWithContentsOfURL:_containerURL];
        NSAssert(data.length == sizeof(int), @"invalid data!!");
        int num;
        memcpy(&num, data.bytes, sizeof(int));
        [[UIApplication sharedApplication] setApplicationIconBadgeNumber:num];
        NSLog(@"load badge number:%d", num);
    }
}

@end
