//
//  MHViewController.m
//  UISample
//
//  Created by tsuyoshi on 2013/11/25.
//  Copyright (c) 2013年 Tsuyoshi Miyano. All rights reserved.
//

#import "MHViewController.h"
#import "MHCheckbox.h"

@interface MHViewController () <MHCheckboxDelegate, UIAlertViewDelegate>

@end

@implementation MHViewController {
    __weak MHCheckbox *_checkbox;
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
    MHCheckbox *checkbox = [[MHCheckbox alloc] initWithImage:[UIImage imageNamed:@"account_button_private.png"] checked:[UIImage imageNamed:@"account_button_expose.png"] disabled:nil];
    checkbox.center = CGPointMake(CGRectGetMidX(self.view.bounds), 100);
    checkbox.delegate = self;
    [self.view addSubview:checkbox];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
#pragma mark - MHCheckboxDelegate
- (BOOL)checkboxShouldChange:(MHCheckbox *)checkbox checked:(BOOL)checked {
    //チェックボックがONにしようとした場合にはダイアログを表示する
    if (checked) {
       UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"MHCheckboxSample"
                                                       message:@"以下のデータを公開しますか？\n名前\nレベル\nコメント"
                                                      delegate:self
                                             cancelButtonTitle:@"キャンセル"
                                             otherButtonTitles:@"公開", nil];
        _checkbox = checkbox;
        [alert show];
        return FALSE;
    } else {
        return TRUE;
    }
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    //[はい]が選択された場合はチェックボックスをONにする
    if (buttonIndex == 1) {
        [_checkbox setChecked:YES];
    }
}
@end
