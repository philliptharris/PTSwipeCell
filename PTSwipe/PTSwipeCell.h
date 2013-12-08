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

typedef NS_ENUM(NSInteger, PTSwipeCellAnimationStyle) {
    PTSwipeCellAnimationStyleGravity,
    PTSwipeCellAnimationStyleSnap
};

typedef NS_ENUM(NSInteger, PTSwipeCellConfiguration) {
    PTSwipeCellConfigurationSwipeAndRelease,
    PTSwipeCellConfigurationButtons,
    PTSwipeCellConfigurationNone
};

extern NSString * const PTSwipeCellId;

@protocol PTSwipeCellDelegate;

@interface PTSwipeCell : UITableViewCell

/// The object that acts as the delegate of the swipe cell. The object must adopt the PTSwipeCellDelegate protocol.
@property (nonatomic, weak) id <PTSwipeCellDelegate> delegate;

/// Color to show in the cell "undercarriage" when the user hasn't dragged her finger left/right enough to activate any item.
@property (nonatomic, strong) UIColor *defaultColor;

/// An array of UIColor objects. As the user drags her finger, and more-and-more of the undercarriage is revealed, the background color of the undercarriage will change to these values as different items are triggered.
@property (nonatomic, strong) NSArray *leftColors;

/// An array of NSString objects corresponding to images in the app bundle. As the user drags her finger, and more-and-more of the undercarriage is revealed, the slider image will change as different items are triggered.
@property (nonatomic, strong) NSArray *leftImageNames;

/// An array of NSNumber objects corresponding to the activation point of each item. The ratios should always be positive, and always be in ascending order. The ratio is the offset along the X-axis divided by the total width of the cell. As the user drags her finger, and more-and-more of the undercarriage is revealed, the slider image and undercarriage background color will change according to these trigger ratios.
@property (nonatomic, strong) NSArray *leftTriggerRatios;

/// An array of UIColor objects. As the user drags her finger, and more-and-more of the undercarriage is revealed, the background color of the undercarriage will change to these values as different items are triggered.
@property (nonatomic, strong) NSArray *rightColors;

/// An array of NSString objects corresponding to images in the app bundle. As the user drags her finger, and more-and-more of the undercarriage is revealed, the slider image will change as different items are triggered.
@property (nonatomic, strong) NSArray *rightImageNames;

/// An array of NSNumber objects corresponding to the activation point of each item. The ratios should always be positive, and always be in ascending order. The ratio is the offset along the X-axis divided by the total width of the cell. As the user drags her finger, and more-and-more of the undercarriage is revealed, the slider image and undercarriage background color will change according to these trigger ratios.
@property (nonatomic, strong) NSArray *rightTriggerRatios;

/// As the user drags her finger across the cell, this will indicate which side of the cell "undercarriage" is visible (Left or Right). If the cell is perfectly centered, this will be Center.
@property (nonatomic, assign, readonly) PTSwipeCellSide revealedSide;

/// Whether or not the user's finger is currently dragging.
@property (nonatomic, assign, readonly, getter = isDragging) BOOL dragging;

/// As the user drags her finger across the cell, different items activate according to the leftTriggerRatios/rightTriggerRatios. The draggingIndex indicates the array index of the active item. If the user hasn't dragged her finger far enough to activate any item, then this value will be -1.
@property (nonatomic, assign, readonly) NSInteger draggingIndex;

/// As the user drags her finger across the cell, different images are visible according to the leftImageNames/rightImageNames and the leftTriggerRatios/rightTriggerRatios. The imageIndex indicates the array index of the visible image.
@property (nonatomic, assign, readonly) NSInteger imageIndex;

/// Whether or not the slider should slide along with the contentView as the user drags her finger across the cell. Defaults to YES.
@property (nonatomic, assign) BOOL leftSliderShouldSlide;

/// Whether or not the slider should slide along with the contentView as the user drags her finger across the cell. Defaults to YES.
@property (nonatomic, assign) BOOL rightSliderShouldSlide;

/// The magnitude of the gravity vector for the gravity behavior of the cell's contentView. Defaults to 3.0. A magnitude value of 1.0 represents an acceleration of 1000 points / second².
@property (nonatomic, assign) CGFloat gravityMagnitude;

/// The amount of elasticity applied to collisions for the cell's contentView. Default value is 0.3. Valid range is from 0.0 for no bounce upon collision, to 1.0 for completely elastic collisions.
@property (nonatomic, assign) CGFloat elasticity;

/// The amount of oscillation of a dynamic item during the conclusion of a snap. The valid range for damping extends from 0.0, for minimum oscillation, through 1.0, for maximum oscillation. The default value is 0.35.
@property (nonatomic, assign) CGFloat snapDamping;

/// The animation style to use when animating the contentView back to center when the left undercarriage is exposed. Defaults to PTSwipeCellAnimationStyleGravity.
@property (nonatomic, assign) PTSwipeCellAnimationStyle leftAnimationStyle;

/// The animation style to use when animating the contentView back to center when the right undercarriage is exposed. Defaults to PTSwipeCellAnimationStyleGravity.
@property (nonatomic, assign) PTSwipeCellAnimationStyle rightAnimationStyle;

/// The configuration of the left underling of the cell. Use PTSwipeCellConfigurationSwipeAndRelease for a Mailbox.app-style swipe-and-release. Use PTSwipeCellConfigurationButtons for an array of tappable buttons underneath the contentView similar to the Delete and More buttons in Apple's Mail.app. Set to PTSwipeCellConfigurationNone to prevent the cell from being swiped from left-to-right. Defaults to PTSwipeCellConfigurationSwipeAndRelease.
@property (nonatomic, assign) PTSwipeCellConfiguration leftConfiguration;

/// The configuration of the right underling of the cell. Use PTSwipeCellConfigurationSwipeAndRelease for a Mailbox.app-style swipe-and-release. Use PTSwipeCellConfigurationButtons for an array of tappable buttons underneath the contentView similar to the Delete and More buttons in Apple's Mail.app. Set to PTSwipeCellConfigurationNone to prevent the cell from being swiped from right-to-left. Defaults to PTSwipeCellConfigurationSwipeAndRelease.
@property (nonatomic, assign) PTSwipeCellConfiguration rightConfiguration;

/// If leftConfiguration is set to PTSwipeCellConfigurationButtons, then these are the buttons that will be placed under the contentView on the left side of the cell.
@property (nonatomic, strong) NSArray *leftButtons;

/// If rightConfiguration is set to PTSwipeCellConfigurationButtons, then these are the buttons that will be placed under the contentView on the right side of the cell.
@property (nonatomic, strong) NSArray *rightButtons;

/// The width to use for buttons if the left or right side's configuration is set to PTSwipeCellConfigurationButtons. You may manually set the width of each individual button before you pass it into the leftButtons/rightButtons array, or you may set this parameter. Defaults to 74.0;
@property (nonatomic, assign) CGFloat defaultButtonWidth;

+ (UIButton *)defaultButton;

@end


@protocol PTSwipeCellDelegate <NSObject>
@optional
- (void)swipeCell:(PTSwipeCell *)cell didSwipeTo:(NSInteger)index onSide:(PTSwipeCellSide)side;
- (void)swipeCell:(PTSwipeCell *)cell didReleaseAt:(NSInteger)index onSide:(PTSwipeCellSide)side;
- (void)swipeCell:(PTSwipeCell *)cell didFinishAnimatingFrom:(NSInteger)index onSide:(PTSwipeCellSide)side;
@end