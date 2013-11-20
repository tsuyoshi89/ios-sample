//
//  MHSampleViewController.m
//  Sample
//
//  Created by tsuyoshi on 2013/11/20.
//  Copyright (c) 2013年 Tsuyoshi Miyano. All rights reserved.
//

#import "MHSampleViewController.h"
#import "MHTileImage.h"

@interface MHSampleViewController ()

@end


@implementation MHSampleViewController

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

    
    [self.view addSubview:resizableView];
    [self.view addSubview:resizedView];
    [self.view addSubview:myResizedView];

    
    UILabel *label1 = [[UILabel alloc] init];
    label1.text = @"resizableImageそのまま";
    [label1 sizeToFit];
    label1.center = resizableView.center;

    UILabel *label2 = [[UILabel alloc] init];
    label2.text = @"resizableImageを拡大描画";
    [label2 sizeToFit];
    label2.center = resizedView.center;

    UILabel *label3 = [[UILabel alloc] init];
    label3.text = @"自力でタイリング";
    [label3 sizeToFit];
    label3.center = myResizedView.center;
    
    [self.view addSubview:label1];
    [self.view addSubview:label2];
    [self.view addSubview:label3];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
