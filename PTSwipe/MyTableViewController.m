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
    _dataSource = [NSMutableArray array];
    [_dataSource addObjectsFromArray:@[@"Milk", @"Bread", @"Bananas", @"Apples", @"Orange Juice", @"Bacon", @"Turkey", @"Ham", @"London Broil", @"Cheese", @"Ice Cream", @"Tomatoes", @"Potatoes", @"Onions", @"Garlic"]];
    
    self.tableView.rowHeight = 64.5;
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
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    cell.delegate = self;
    cell.leftSliderShouldSlide = NO;
    cell.rightSliderShouldSlide = YES;
    cell.leftAnimationStyle = PTSwipeCellAnimationStyleGravity;
    cell.rightAnimationStyle = PTSwipeCellAnimationStyleSnap;
    cell.rightConfiguration = PTSwipeCellConfigurationButtons;
    
    UIButton *deleteButton = [PTSwipeCell defaultButton];
    [deleteButton setTitle:@"Delete" forState:UIControlStateNormal];
    [deleteButton setBackgroundColor:[UIColor sevenRed]];
    cell.rightButtons = @[deleteButton];
//    UIButton *moreButton = [PTSwipeCell defaultButton];
//    [moreButton setTitle:@"More" forState:UIControlStateNormal];
//    [moreButton setBackgroundColor:[UIColor sevenGroupedTableSeparatorLineGray]];
//    cell.rightButtons = @[deleteButton, moreButton];
    
    cell.defaultColor = [UIColor sevenGroupedTableViewBackground];
    cell.contentView.backgroundColor = [UIColor whiteColor];
    
    cell.leftTriggerRatios = @[@0.15];
    cell.leftColors = @[[UIColor sevenGreen]];
    cell.leftImageNames = @[@"check"];
    
//    cell.rightTriggerRatios = @[@0.15, @0.3, @0.45, @0.6];
//    cell.rightColors = @[[UIColor sevenOrange], [UIColor sevenIndigo], [UIColor sevenBlue], [UIColor sevenRed]];
//    cell.rightImageNames = @[@"replyArrow", @"pencil", @"folder", @"cross"];
    
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

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    if (scrollView.dragging && scrollView.tracking) {
        for (PTSwipeCell *visibleCell in self.tableView.visibleCells) {
            [visibleCell animateToCoveredStateIfExposed];
        }
    }
}

//===============================================
#pragma mark -
#pragma mark PTSwipeCellDelegate
//===============================================

- (void)swipeCell:(PTSwipeCell *)cell didSwipeTo:(NSInteger)index onSide:(PTSwipeCellSide)side {
    NSLog(@"didSwipeTo:%li onSide:%li", (long)index, side);
    
    if (side == PTSwipeCellSideLeft && index == 0) {
        cell.contentView.backgroundColor = [UIColor sevenGroupedTableViewBackground];
    }
    else {
        cell.contentView.backgroundColor = [UIColor whiteColor];
    }
}

- (void)swipeCell:(PTSwipeCell *)cell didReleaseAt:(NSInteger)index onSide:(PTSwipeCellSide)side {
    NSLog(@"didReleaseAt:%li onSide:%li", (long)index, side);
    
//    if (side == PTSwipeCellSideLeft && index == 1) {
//        NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
//        [self.dataSource removeObjectAtIndex:indexPath.row];
//        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationRight];
//    }
}

- (void)swipeCell:(PTSwipeCell *)cell didFinishAnimatingFrom:(NSInteger)index onSide:(PTSwipeCellSide)side {
    NSLog(@"didFinishAnimatingFrom:%li onSide:%li", (long)index, side);
}

- (void)swipeCell:(PTSwipeCell *)cell buttonRevealStateDidChangeTo:(PTSwipeCellButtonRevealState)revealState {
    NSLog(@"swipeCell:buttonRevealStateDidChangeTo:");
    
    for (PTSwipeCell *visibleCell in self.tableView.visibleCells) {
        if (visibleCell != cell) {
            [visibleCell animateToCoveredStateIfExposed];
        }
    }
}

@end
