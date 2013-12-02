//
//  MyTableViewController.m
//  PTSwipe
//
//  Created by Phillip Harris on 11/29/13.
//  Copyright (c) 2013 Phillip Harris. All rights reserved.
//

#import "MyTableViewController.h"

#import "PTSwipeCell.h"

#import "UIColor+LightDark.h"

@interface MyTableViewController () <PTSwipeCellDelegate>
@property (nonatomic, strong) NSMutableArray *dataSource;
@end

@implementation MyTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _dataSource = [NSMutableArray array];
    for (int i = 0; i < 30; i++) {
        [_dataSource addObject:[NSString stringWithFormat:@"Item %i", i]];
    }
    
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
    return [self.dataSource count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    PTSwipeCell *cell = [tableView dequeueReusableCellWithIdentifier:PTSwipeCellId forIndexPath:indexPath];
    cell.delegate = self;
//    cell.sliderSlides = NO;
    
    cell.defaultColor = [UIColor sevenGroupedTableViewBackground];
    cell.contentView.backgroundColor = [UIColor whiteColor];
    
    cell.leftTriggerRatios = @[@0.2, @0.7];
    cell.leftColors = @[[UIColor sevenGreen], [UIColor sevenRed]];
    cell.leftImageNames = @[@"check", @"cross"];
    
    cell.rightTriggerRatios = @[@0.2, @0.5];
    cell.rightColors = @[[UIColor sevenBlue], [UIColor sevenIndigo]];
    cell.rightImageNames = @[@"pencil", @"plus"];
    
    cell.textLabel.text = self.dataSource[indexPath.row];
    cell.textLabel.backgroundColor = [UIColor clearColor];
    
    return cell;
}

//===============================================
#pragma mark -
#pragma mark UITableViewDelegate
//===============================================

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

//===============================================
#pragma mark -
#pragma mark UITableViewDataSource
//===============================================

- (void)swipeCell:(PTSwipeCell *)cell didSwipeTo:(NSInteger)index onSide:(PTSwipeCellSide)side {
    NSLog(@"didSwipeTo:%li onSide:%li", (long)index, side);
    
//    if (side == PTSwipeCellSideLeft && index == 0) {
//        cell.contentView.backgroundColor = [UIColor sevenGroupedTableViewBackground];
//    }
//    else {
//        cell.contentView.backgroundColor = [UIColor whiteColor];
//    }
}

- (void)swipeCell:(PTSwipeCell *)cell didReleaseAt:(NSInteger)index onSide:(PTSwipeCellSide)side {
    NSLog(@"didReleaseAt:%li onSide:%li", (long)index, side);
    
    if (side == PTSwipeCellSideLeft && index == 1) {
        NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
        [self.dataSource removeObjectAtIndex:indexPath.row];
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationRight];
    }
}

@end
