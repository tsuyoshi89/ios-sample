//
//  MHClipViewController.m
//  MHLib
//
//  Created by tsuyoshi on 2013/10/04.
//  Copyright (c) 2013年 Sola Co., Ltd. All rights reserved.
//
#import "MHClipViewController.h"
#import "MHClipView.h"
#import "MHImage.h"

enum {
 tagImageView = 100,
tagClipView,
tagClip,
};

#define VIEW_CONTENT_TOP (44 + NAVI_OFFSETY)

const static CGFloat kTouchMargin = 25;
const static CGRect kDefaultButtonRect = CGRectMake(0, 0, 60, 25);

@interface MHClipViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@end

@implementation MHClipViewController {
    CGSize _clipSize;
    BOOL _isFirst;
    UIPopoverController *_popoverController;
    UIColor *_backgroundColor;
    UIImage *_maskImage;
}

- (void)setBackgroundColor:(UIColor *)backgroundColor {
    _backgroundColor = backgroundColor;
    self.view.backgroundColor = self.backgroundColor;
}

- (UIColor *)backgroundColor {
    if (_backgroundColor == nil) {
        _backgroundColor = [UIColor grayColor];
    }
    return _backgroundColor;
}

- (id)init {
    self = [super init];
    if (self) {
        _isFirst = TRUE;
    }
    return self;
}

- (id)initWithMaskImage:(UIImage *)maskImage {
    self = [self init];
    if (self) {
        _clipSize = maskImage.size;
        _maskImage = maskImage;
    }
    return self;
}

- (id)initWithClipSize:(CGSize)clipSize {
    self = [self init];
    if (self) {
        _clipSize = clipSize;
    }
    return self;
}

- (void)setCompletionBlock:(void (^)(UIImage *))block {
    _completionBlock = block;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    CGRect bounds = self.view.bounds;
    UIImage *image = nil;//[UIImage imageNamed:@"IMG_0977.JPG"];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    imageView.tag = tagImageView;
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.backgroundColor = [UIColor whiteColor];
    imageView.frame = bounds;
    [self.view addSubview:imageView];

    CGRect clipRect = CGRectMake(CGRectGetMidX(imageView.bounds), CGRectGetMidY(imageView.bounds), _clipSize.width, _clipSize.height);
    MHClipView *clipView = [[MHClipView alloc] initWithFrame:clipRect margin:kTouchMargin];
    clipView.tag = tagClipView;
    clipView.hidden = YES;
    clipView.maskImage = _maskImage;
    imageView.userInteractionEnabled = YES;
    [imageView addSubview:clipView];
    
    //UIBarButtonItem *left = [[UIBarButtonItem alloc] initWithTitle:@"Photo" style:UIBarButtonItemStylePlain target:self action:@selector(tapPhoto)];
    UIBarButtonItem *left = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:self action:@selector(tapBack)];
    [self.navigationItem setLeftBarButtonItem:left];
    UIBarButtonItem *right = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStylePlain target:self action:@selector(tapClip)];
    [self.navigationItem setRightBarButtonItem:right];
    
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    self.view.backgroundColor = _backgroundColor;

    [self setEdgesForExtendedLayout:UIRectEdgeNone];
    
    CGRect bounds = self.view.bounds;

    UIImageView *imageView = (UIImageView *)[self.view viewWithTag:tagImageView];
    UIView *clipView = [imageView viewWithTag:tagClipView];
    imageView.backgroundColor = [UIColor clearColor];
    imageView.frame = bounds;
    imageView.center = CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds));
    clipView.center = imageView.center;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    if (_isFirst) {
        _isFirst = FALSE;
        [self tapPhoto];
    } else {
        UIView *clipView = [self.view viewWithTag:tagClipView];
        if (clipView.hidden) {
            CGRect frame = clipView.frame;
            clipView.frame = CGRectMake(clipView.center.x, clipView.center.y, 0, 0);
            clipView.hidden = NO;
            [UIView animateWithDuration:0.5f animations:^{
                clipView.frame = frame;
            }];
        }
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)tapClip {
    UIBezierPath *path = [(MHClipView *)[self.view viewWithTag:tagClipView] getClipPath];
    UIImageView *imageView = (UIImageView *)[self.view viewWithTag:tagImageView];
    [self.view viewWithTag:tagClipView].alpha = 0.0f;
    UIImage *image = [imageView getClipImageWithPath:path maskImage:nil];
    if (_maskImage ) {
        image = [image resize:_maskImage.size backgroundColor:nil];
        image = [image createWithMask:_maskImage];
    }

    [self.view viewWithTag:tagClipView].alpha = 1.0f;
    
    if (_completionBlock) {
        _completionBlock(image);
    }

    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)tapPhoto {
    UIImagePickerController *ipc = [[UIImagePickerController alloc] init];
    ipc.delegate = self;
    ipc.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    //ipc.allowsEditing = YES;
    [self presentViewController:ipc animated:YES completion:nil];
}

- (void)tapBack {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
#if 1
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
#else //editing
    //CGRect rect = [[info objectForKey:UIImagePickerControllerCropRect] CGRectValue];
    //UIImage *image = [info objectForKey:UIImagePickerControllerEditedImage];
    NSLog(@"clip:%@ image-size:%@", toString(rect), toString(image.size));
#endif
    
    UIImageView *view = (UIImageView *)[self.view viewWithTag:tagImageView];
    [view setImage:image];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        [_popoverController dismissPopoverAnimated:YES];
        _popoverController = nil;
    } else {
        [picker dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    NSLog(@"did cancel");
    
    if (_completionBlock) {
        _completionBlock(nil);
    }
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        [_popoverController dismissPopoverAnimated:YES];
        _popoverController = nil;
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        [picker dismissViewControllerAnimated:YES completion:^{
            [self dismissViewControllerAnimated:YES completion:nil];
        }];
    }
}


@end
