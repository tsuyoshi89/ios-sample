//
//  MHSelectViewController.m
//  KiiSample
//
//  Created by tsuyoshi on 2013/12/01.
//  Copyright (c) 2013年 Tsuyoshi Miyano. All rights reserved.
//
#import "common.h"

#import "KiiObject+MHKiiHelper.h"

#import "MHSelectViewController.h"
#import "MHEditViewController.h"

#import "KiiManager.h"

@interface MHSelectViewController ()

@end

@implementation MHSelectViewController

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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForKiiObject:(KiiObject *)object atIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"sample"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"sample"];
/*
 CGRect bounds = CGRectMake(0, 0, tableView.frame.size.width, 80);
        cell = [[UITableViewCell alloc] initWithFrame:bounds];
        UITextField *label = [[UITextField alloc] initWithFrame:CGRectMake(5, 3, bounds.size.width - 10, 30)];
        label.userInteractionEnabled = FALSE;
 */
        cell.detailTextLabel.numberOfLines = 0;
        
    }
    
    UILabel *textLabel = cell.textLabel;
    UILabel *detailLabel = cell.detailTextLabel;
    
    textLabel.text = object.uuid;
    
    __block NSString *text = @"";
    NSDictionary *dict = [object dictionaryValue];
    [dict enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop) {
        text = [text stringByAppendingString:[NSString stringWithFormat:@"%@(%@): %@\n",
                                              key,
                                              [object typeNameForKey:key],
                                              value]];
    }];

    detailLabel.text = text;
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    KiiObject *object = [self kiiObjectAtIndex:indexPath.row];
    UILabel *label = [[UILabel alloc]init];
    label.font = [UIFont systemFontOfSize:16];
    label.numberOfLines = 0;

    __block NSString *text = @"";
    NSDictionary *dict = [object dictionaryValue];
    [dict enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop) {
        text = [text stringByAppendingString:[NSString stringWithFormat:@"%@(%@): %@\n",
                                              key,
                                              [object typeNameForKey:key],
                                              value]];
    }];

    label.text = text;
    [label sizeToFit];

    CGFloat ret = 24 + label.frame.size.height;
    return ret;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    KiiObject *object = [self kiiObjectAtIndex:indexPath.row];
    [KiiManager sharedInstance].object = object;
    MHEditViewController *vc = [[MHEditViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
    
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    KiiObject *object = [self kiiObjectAtIndex:indexPath.row];
    [[KiiManager sharedInstance] deleteObject:object.uuid];
}
@end
