//
//  PTSwipeCell.h
//  PTSwipe
//
//  Created by Phillip Harris on 11/29/13.
//  Copyright (c) 2013 Phillip Harris. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, PTSwipeCellSide) {
    PTSwipeCellSideLeft,
    PTSwipeCellSideCenter,
    PTSwipeCellSideRight
};

extern NSString * const PTSwipeCellId;

@protocol PTSwipeCellDelegate;

@interface PTSwipeCell : UITableViewCell

@property (nonatomic, weak) id <PTSwipeCellDelegate> delegate;

/// Color for background, when any state hasn't triggered yet
@property (nonatomic, strong) UIColor *defaultColor;

@property (nonatomic, strong) NSArray *leftColors;
@property (nonatomic, strong) NSArray *leftImageNames;
@property (nonatomic, strong) NSArray *leftTriggerRatios;
@property (nonatomic, strong) NSArray *leftTriggerPoints;

@property (nonatomic, strong) NSArray *rightColors;
@property (nonatomic, strong) NSArray *rightImageNames;
@property (nonatomic, strong) NSArray *rightTriggerRatios;
@property (nonatomic, strong) NSArray *rightTriggerPoints;

// Experimental
@property (nonatomic, strong) NSArray *colors;
@property (nonatomic, strong) NSArray *imageNames;
@property (nonatomic, strong) NSArray *triggerRatios;
//

///-------------------------------------
/// @name Configuring Dynamics Behaviors
///-------------------------------------

/**
 The magnitude of the gravity vector that affects the pane view.
 
 Default value of `2.0`. A magnitude value of `1.0` represents an acceleration of 1000 points / second².
 */
@property (nonatomic, assign) CGFloat gravityMagnitude;

/**
 The elasticity applied to the pane view.
 
 Default value of `0.0`. Valid range is from `0.0` for no bounce upon collision, to `1.0` for completely elastic collisions.
 */
@property (nonatomic, assign) CGFloat elasticity;

@end


@protocol PTSwipeCellDelegate <NSObject>

@optional
- (void)swipeCell:(PTSwipeCell *)cell didExecuteItemAtIndex:(NSInteger)index;

@end