//
//  MyTableViewController.m
//  PTSwipe
//
//  Created by Phillip Harris on 11/29/13.
//  Copyright (c) 2013 Phillip Harris. All rights reserved.
//

#import "MyTableViewController.h"

#import "PTSwipeCell.h"

@interface MyTableViewController ()

@end

@implementation MyTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.rowHeight = 64.0;
    self.tableView.separatorInset = UIEdgeInsetsZero;
    [self.tableView registerClass:[PTSwipeCell class] forCellReuseIdentifier:PTSwipeCellId];
}

//===============================================
#pragma mark -
#pragma mark UITableViewDataSource
//===============================================

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 30;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    PTSwipeCell *cell = [tableView dequeueReusableCellWithIdentifier:PTSwipeCellId forIndexPath:indexPath];
    
    cell.contentView.backgroundColor = [UIColor whiteColor];
    
    cell.leftTriggerRatios = @[@0.2, @0.4];
    cell.leftColors = @[[UIColor blueColor], [UIColor greenColor]];
    
    cell.rightTriggerRatios = @[@0.5, @0.75];
    cell.rightColors = @[[UIColor orangeColor], [UIColor yellowColor]];
    
    cell.textLabel.text = [NSString stringWithFormat:@"%li", (long)indexPath.row];
    
    return cell;
}

//===============================================
#pragma mark -
#pragma mark UITableViewDelegate
//===============================================

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
