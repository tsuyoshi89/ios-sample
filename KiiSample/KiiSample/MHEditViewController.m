//
//  MHEditViewController.m
//  KiiSample
//
//  Created by tsuyoshi on 2013/12/01.
//  Copyright (c) 2013年 Tsuyoshi Miyano. All rights reserved.
//

#import "common.h"

#import "KiiObject+MHKiiHelper.h"

#import "MHEditViewController.h"
#import "MHImage.h"
#import "MHFileHelper.h"

#import "KiiManager.h"

@interface MHEditViewController () <UIPickerViewDelegate, UIPickerViewDataSource, UIActionSheetDelegate, UIGestureRecognizerDelegate, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, KiiManagerDelegate>

@end

static int tagKeyMin = 100;
static int tagValueMin = 200;
static int tagTypeMin = 300;
static int tagImage = 400;

@implementation MHEditViewController {
    UIScrollView *_view;
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
    
    _view = [[UIScrollView alloc] initWithFrame:self.view.frame];
    self.view = _view;
    self.view.backgroundColor = [UIColor whiteColor];
    
    NSString *title = @"編集";
    
    self.navigationItem.title = title;
    
    UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStylePlain target:self action:@selector(save)];
    UIBarButtonItem *saveAll = [[UIBarButtonItem alloc] initWithTitle:@"SaveAll" style:UIBarButtonItemStylePlain target:self action:@selector(saveAll)];
    
    [self.navigationItem setRightBarButtonItems:@[saveButton, saveAll]];
    
    CGFloat posY = 0;

    NSArray *ids = [self createField:posY label:@"uuid" placeFolder:@""];
    //UITextField *idLabel = [ids objectAtIndex:0];
    UITextField *idField = [ids objectAtIndex:1];
    idField.userInteractionEnabled = NO;
    idField.text = [KiiManager sharedInstance].object.uuid;
    posY += 40;
    
    
    NSArray *heads = [self createField:posY label:@"Key" placeFolder:@""];
    UITextField *keyHead = [heads objectAtIndex:0];
    UITextField *valueHead = [heads objectAtIndex:1];
    CGRect frame = valueHead.frame;
    frame.size.width = 180;
    valueHead.frame = frame;

    valueHead.text = @"Value";
    keyHead.backgroundColor = [UIColor colorWithRed:0.9f green:0.9f blue:1.0f alpha:1.0f];
    valueHead.backgroundColor = [UIColor colorWithRed:0.9f green:0.9f blue:1.0f alpha:1.0f];
    valueHead.userInteractionEnabled = FALSE;
    posY += 40;
    
    
    NSArray *inputs = [self createField:posY label:@"" placeFolder:@"add new value"];
    UITextField *keyField = [inputs objectAtIndex:0];
    keyField.userInteractionEnabled = YES;
    keyField.placeholder = @"";
    keyField.backgroundColor = [UIColor yellowColor];
    UITextField *valueField = [inputs objectAtIndex:1];
    valueField.backgroundColor = [UIColor yellowColor];
    frame = valueField.frame;
    frame.size.width = 180;
    valueField.frame = frame;
    valueField.delegate = self;
    UIButton *typeButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [typeButton setTitle:@"String" forState:UIControlStateNormal];
    typeButton.frame = CGRectMake(CGRectGetMaxX(valueField.frame), posY - 10, 60, 50);
    [typeButton addTarget:self action:@selector(tapType:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:typeButton];
    keyField.tag = tagKeyMin;
    valueField.tag = tagValueMin;
    typeButton.tag = tagTypeMin;
 
#if 1//old code
    NSString *path = [MHFileHelper makeCachePath:[NSString stringWithFormat:@"%@.png", [KiiManager sharedInstance].object.uuid]];
    if ([MHFileHelper isFileAtPath:path]) {
        [MHFileHelper removeItemAtPath:path];
        NSLog(@"delete image file:%@", path);
    }
#endif

    [self updateValues];
    
    UITapGestureRecognizer *recog = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
    recog.delegate = self;
    [self.view addGestureRecognizer:recog];

}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [KiiManager sharedInstance].delegate = self;
}

- (void)tap:(UITapGestureRecognizer *)recog {
    UIView *view = [self.view viewWithTag:tagImage];
    CGPoint pt = [recog locationInView:view];
    if (CGRectContainsPoint(view.bounds,pt)) {
        [[KiiManager sharedInstance] deleteBody];
    }
}
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    for (UIView *view in self.view.subviews) {
        if (view.isFirstResponder) {
            [view resignFirstResponder];
            break;;
        }
    }

    UIView *view = [self.view viewWithTag:tagImage];
    CGPoint pt = [touch locationInView:view];
    if (CGRectContainsPoint(view.bounds,pt)) {
        return TRUE;
    }
    return FALSE;
}

- (void)updateValues {
    
    for (int i = 1; i < 100; i++) {
        UIView *key = [self.view viewWithTag:tagKeyMin + i];
        if (!key) {
            break;
        }
        [key removeFromSuperview];
        [[self.view viewWithTag:tagValueMin + i] removeFromSuperview];
        [[self.view viewWithTag:tagTypeMin + i] removeFromSuperview];
    }
    [[self.view viewWithTag:tagImage] removeFromSuperview];
    
    __block CGFloat posY = CGRectGetMaxY([self.view viewWithTag:tagKeyMin].frame);
    __block int tagKey = tagKeyMin + 1;
    __block int tagValue = tagValueMin +1;
    __block int tagType = tagTypeMin + 1;

    KiiObject *object = [KiiManager sharedInstance].object;
    NSDictionary *dict = [object dictionaryValue];
    [dict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        NSArray *fields = [self createField:posY label:key placeFolder:@""];
        UITextField *keyField = [fields objectAtIndex:0];
        UITextField *valueField = [fields objectAtIndex:1];
        CGRect frame = valueField.frame;
        frame.size.width = 180;
        valueField.frame = frame;
        UIButton *typeButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [typeButton setTitle:[object typeNameForKey:key] forState:UIControlStateNormal];
        typeButton.frame = CGRectMake(CGRectGetMaxX(valueField.frame), posY - 10, 60, 50);
        [typeButton addTarget:self action:@selector(tapType:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:typeButton];

        keyField.tag = tagKey++;
        valueField.tag = tagValue++;
        typeButton.tag = tagType++;

        valueField.text = [NSString stringWithFormat:@"%@", obj];
        
        
        posY += 40;
    }];

    UIImageView *imageView = [[UIImageView alloc]initWithFrame:CGRectMake(100, posY, 160, 160)];
    imageView.tag = tagImage;
    [self.view addSubview:imageView];
    imageView.image = [UIImage imageWithData:[object _bodyCache]];

    posY += 160;

    [_view setContentSize:CGSizeMake(self.view.frame.size.width, posY)];
}

- (void)save {
    [self doSave:NO];
}

- (void)saveAll {
    [self doSave:YES];
}

- (void)doSave:(BOOL)isAll {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    NSMutableArray *deleteKeys = [[NSMutableArray alloc] init];
    int index = 0;
    do {
        UITextField *keyField = (UITextField *)[self.view viewWithTag:(tagKeyMin + index)];
        if (keyField == nil) {
            break;
        }
        UITextField *valueField = (UITextField *)[self.view viewWithTag:(tagValueMin + index)];
        UIButton *typeButton = (UIButton *)[self.view viewWithTag:(tagTypeMin + index)];
        
        NSString *key = keyField.text;
        NSString *value = valueField.text;
        NSString *type = typeButton.titleLabel.text;
        
        if (value.length == 0) {
            [deleteKeys addObject:key];
            index++;
            continue;
        }
        id obj;
        if ([type isEqualToString:@"Int"]) {
            obj = [NSNumber numberWithInt:[value intValue]];
        } else if ([type isEqualToString:@"Boolean"]) {
            obj = [NSNumber numberWithBool:[value boolValue]];
        } else if ([type isEqualToString:@"Long"]) {
            obj = [NSNumber numberWithLong:[value intValue]];
        } else if ([type isEqualToString:@"Double"]) {
            obj = [NSNumber numberWithDouble:[value doubleValue]];
        } else {
            obj = value;
        }
        
        [dict setObject:obj forKey:key];
        
        index++;
    } while(1);
    if (isAll) {
        [[KiiManager sharedInstance] saveAll:dict widthDeleteKeys:deleteKeys];
    } else {
        [[KiiManager sharedInstance] save:dict];
    }
}

- (int)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return [KiiObject valueTypeNames].count;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return [[KiiObject valueTypeNames] objectAtIndex:row];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    UIPickerView *picker = (UIPickerView *)[[actionSheet subviews] lastObject];
    int row = [picker selectedRowInComponent:0];
    NSString *name = [[KiiObject valueTypeNames] objectAtIndex:row];
    [actionSheet dismissWithClickedButtonIndex:buttonIndex animated:YES];
    UIButton *button = (UIButton *)[self.view viewWithTag:picker.tag];
    [button setTitle:name forState:UIControlStateNormal];
}

- (void)tapType:(UIButton *) sender {
    
    UIPickerView *picker = [[UIPickerView alloc] initWithFrame:CGRectMake(0, 30, 320, 365)];
    picker.delegate = self;
    picker.dataSource = self;
    picker.showsSelectionIndicator = YES;
    picker.tag = sender.tag;
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:nil
                                                       delegate:nil cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    
    [sheet addButtonWithTitle:@"Close"];
    [sheet showInView:self.view];
    [sheet addSubview:picker];
    [sheet setBounds:CGRectMake(0, 0, 320, 415)];
    sheet.delegate = self;
}

#pragma mark - text field delegate

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    UIButton *button = (UIButton *)[self.view viewWithTag:tagTypeMin];
    if ([button.titleLabel.text isEqualToString:@"Body"]) {
        [self showImagePicker];
        return FALSE;
    }
    return TRUE;
}

- (void)showImagePicker {
    UIImagePickerController *ipc = [[UIImagePickerController alloc] init];
    ipc.delegate = self;
    ipc.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    //ipc.allowsEditing = YES;
    [self presentViewController:ipc animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    image = [image resize:CGSizeMake(50, 50) backgroundColor:nil];
    [[KiiManager sharedInstance] uploadData:UIImagePNGRepresentation(image)];
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - KiiManagerDelegate
- (void)kiiManager:(KiiManager *)manager didChangeObject:(KiiObject *)object {
    [self updateValues];
}
@end
