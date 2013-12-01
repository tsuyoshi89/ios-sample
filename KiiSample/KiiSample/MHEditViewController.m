//
//  MHEditViewController.m
//  KiiSample
//
//  Created by tsuyoshi on 2013/12/01.
//  Copyright (c) 2013年 Tsuyoshi Miyano. All rights reserved.
//

#import "common.h"
#import "MHEditViewController.h"

@interface MHEditViewController () <UIPickerViewDelegate, UIPickerViewDataSource, UIActionSheetDelegate, UIGestureRecognizerDelegate>

@end

static int tagKeyMin = 100;
static int tagValueMin = 200;
static int tagTypeMin = 300;

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
    UIButton *typeButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [typeButton setTitle:@"String" forState:UIControlStateNormal];
    typeButton.frame = CGRectMake(CGRectGetMaxX(valueField.frame), posY - 10, 60, 50);
    [typeButton addTarget:self action:@selector(tapType:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:typeButton];
    keyField.tag = tagKeyMin;
    valueField.tag = tagValueMin;
    typeButton.tag = tagTypeMin;
 
    [self updateValues];
    
    UITapGestureRecognizer *recog = [[UITapGestureRecognizer alloc] initWithTarget:nil action:nil];
    recog.delegate = self;
    [self.view addGestureRecognizer:recog];

}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[KiiManager sharedInstance] addObserver:self forKeyPath:@"object" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)viewDidDisappear:(BOOL)animated {
    [[KiiManager sharedInstance] removeObserver:self forKeyPath:@"object"];
    [super viewDidDisappear:animated];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"object"]) {
        [self updateValues];
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    for (UIView *view in self.view.subviews) {
        if (view.isFirstResponder) {
            [view resignFirstResponder];
            break;;
        }
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
    
    __block CGFloat posY = CGRectGetMaxY([self.view viewWithTag:tagKeyMin].frame);
    __block int tagKey = tagKeyMin + 1;
    __block int tagValue = tagValueMin +1;
    __block int tagType = tagTypeMin + 1;

    
    NSDictionary *dict = [[KiiManager sharedInstance].object dictionaryValue];
    [dict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        NSArray *fields = [self createField:posY label:key placeFolder:@""];
        UITextField *keyField = [fields objectAtIndex:0];
        UITextField *valueField = [fields objectAtIndex:1];
        CGRect frame = valueField.frame;
        frame.size.width = 180;
        valueField.frame = frame;
        UIButton *typeButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [typeButton setTitle:[[KiiManager sharedInstance] typeName:obj] forState:UIControlStateNormal];
        typeButton.frame = CGRectMake(CGRectGetMaxX(valueField.frame), posY - 10, 60, 50);
        [typeButton addTarget:self action:@selector(tapType:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:typeButton];

        keyField.tag = tagKey++;
        valueField.tag = tagValue++;
        typeButton.tag = tagType++;

        valueField.text = [NSString stringWithFormat:@"%@", obj];
        
        
        posY += 40;
    }];
    
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
    return [[KiiManager sharedInstance] valueTypes].count;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return [[[KiiManager sharedInstance] valueTypeNames] objectAtIndex:row];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    UIPickerView *picker = (UIPickerView *)[[actionSheet subviews] lastObject];
    int row = [picker selectedRowInComponent:0];
    NSString *name = [[KiiManager sharedInstance].valueTypeNames objectAtIndex:row];
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


@end
