//
//  PTSwipeCell.m
//  PTSwipe
//
//  Created by Phillip Harris on 11/29/13.
//  Copyright (c) 2013 Phillip Harris. All rights reserved.
//

#import "PTSwipeCell.h"

NSString * const PTSwipeCellId = @"PTSwipeCellId";

NSString * const MSDynamicsDrawerBoundaryIdentifier = @"MSDynamicsDrawerBoundaryIdentifier";

const CGFloat MSPaneViewVelocityMultiplier = 1.0;

@interface PTSwipeCell () <UIDynamicAnimatorDelegate>

@property (nonatomic, strong) UIPanGestureRecognizer *panGestureRecognizer;
@property (nonatomic, strong) UIView *colorIndicatorView;
@property (nonatomic, strong) UIImageView *slidingImageView;
@property (nonatomic, assign) PTSwipeCellSide revealedSide;
@property (nonatomic, assign, getter = isDragging) BOOL dragging;
@property (nonatomic, assign) NSInteger draggingIndex;
@property (nonatomic, assign) NSInteger imageIndex;

@property (nonatomic, strong) UIDynamicAnimator *dynamicAnimator;
@property (nonatomic, strong) UIPushBehavior *pushBehaviorInstantaneous;
@property (nonatomic, strong) UIDynamicItemBehavior *elasticityBehavior;
@property (nonatomic, strong) UIGravityBehavior *gravityBehavior;
@property (nonatomic, strong) UICollisionBehavior *boundaryCollisionBehavior;

@property (nonatomic, strong) NSDate *lastPanTime_forVelocityCalculation;

@property (nonatomic, assign) CGRect homeFrm;

@property (nonatomic, assign) BOOL leftButtonsHaveBeenAdded;
@property (nonatomic, assign) BOOL rightButtonsHaveBeenAdded;

@property (nonatomic, assign) PTSwipeCellButtonRevealState buttonRevealState;

@end

@implementation PTSwipeCell

//===============================================
#pragma mark -
#pragma mark Setters
//===============================================

- (void)setDraggingIndex:(NSInteger)draggingIndex {
    
    if (_draggingIndex != draggingIndex) {
        if ([self.delegate respondsToSelector:@selector(swipeCell:didSwipeTo:onSide:)]) {
            [self.delegate swipeCell:self didSwipeTo:draggingIndex onSide:self.revealedSide];
        }
    }
    _draggingIndex = draggingIndex;
}

- (void)setImageIndex:(NSInteger)imageIndex {
    
    if (_imageIndex != imageIndex) {
        
        NSString *imageName = [self imageNameForIndex:imageIndex onSide:self.revealedSide];
        self.slidingImageView.image = imageName ? [UIImage imageNamed:imageName] : nil;
        
        NSLog(@"setting image to %@", imageName);
    }
    _imageIndex = imageIndex;
}

- (void)setRevealedSide:(PTSwipeCellSide)revealedSide {
    
    if (_revealedSide != revealedSide) {
        
        NSString *imageName = [self imageNameForIndex:self.imageIndex onSide:revealedSide];
        self.slidingImageView.image = imageName ? [UIImage imageNamed:imageName] : nil;
        
        NSLog(@"setting image to %@", imageName);
    }
    _revealedSide = revealedSide;
    
    [self setButtonVisibility];
}

- (void)setLeftButtons:(NSArray *)leftButtons {
    
    if (_leftButtons && [_leftButtons count] > 0) {
        for (UIButton *button in _leftButtons) {
            [button removeFromSuperview];
        }
    }
    _leftButtons = leftButtons;
    _leftButtonsHaveBeenAdded = NO;
}

- (void)setRightButtons:(NSArray *)rightButtons {
    
    if (_rightButtons && [_rightButtons count] > 0) {
        for (UIButton *button in _rightButtons) {
            [button removeFromSuperview];
        }
    }
    _rightButtons = rightButtons;
    _rightButtonsHaveBeenAdded = NO;
}

- (void)setButtonRevealState:(PTSwipeCellButtonRevealState)buttonRevealState {
    
    if (_buttonRevealState != buttonRevealState) {
        if ([self.delegate respondsToSelector:@selector(swipeCell:buttonRevealStateDidChangeTo:)]) {
            [self.delegate swipeCell:self buttonRevealStateDidChangeTo:buttonRevealState];
        }
    }
    _buttonRevealState = buttonRevealState;
}

//===============================================
#pragma mark -
#pragma mark Initialization
//===============================================

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self initializer];
    }
    return self;
}
- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initializer];
    }
    return self;
}
- (id)init {
    self = [super init];
    if (self) {
        [self initializer];
    }
    return self;
}

- (void)initializer {
    
    // Private property initialization
    //
    _dragging = NO;
    _draggingIndex = -1;
    _imageIndex = -1;
    _homeFrm = CGRectZero;
    _leftButtonsHaveBeenAdded = NO;
    _rightButtonsHaveBeenAdded = NO;
    _buttonRevealState = PTSwipeCellButtonRevealStateCovered;
    
    // Public property defaults
    //
    _leftSliderShouldSlide = YES;
    _rightSliderShouldSlide = YES;
    _leftAnimationStyle = PTSwipeCellAnimationStyleGravity;
    _rightAnimationStyle = PTSwipeCellAnimationStyleGravity;
    _leftConfiguration = PTSwipeCellConfigurationSwipeAndRelease;
    _rightConfiguration = PTSwipeCellConfigurationSwipeAndRelease;
    _defaultColor = [UIColor lightGrayColor];
    _gravityMagnitude = 3.0;
    _elasticity = 0.3;
    _snapDamping = 0.8; // 0.35
    _defaultButtonWidth = 74.0;
    
    _colorIndicatorView = [[UIView alloc] initWithFrame:self.bounds];
    _colorIndicatorView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    _colorIndicatorView.backgroundColor = self.defaultColor ? self.defaultColor : [UIColor clearColor];
    [self insertSubview:_colorIndicatorView atIndex:0];
    
    _slidingImageView = [[UIImageView alloc] init];
    _slidingImageView.contentMode = UIViewContentModeCenter;
    [_colorIndicatorView addSubview:_slidingImageView];
    
    _panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGestureRecognizer:)];
    [self addGestureRecognizer:_panGestureRecognizer];
    _panGestureRecognizer.delegate = self;
    
    self.dynamicAnimator = [[UIDynamicAnimator alloc] initWithReferenceView:self];
    self.dynamicAnimator.delegate = self;
    
    self.boundaryCollisionBehavior = [[UICollisionBehavior alloc] initWithItems:@[self.contentView]];
    self.gravityBehavior = [[UIGravityBehavior alloc] initWithItems:@[self.contentView]];
    self.pushBehaviorInstantaneous = [[UIPushBehavior alloc] initWithItems:@[self.contentView] mode:UIPushBehaviorModeInstantaneous];
    self.elasticityBehavior = [[UIDynamicItemBehavior alloc] initWithItems:@[self.contentView]];
    
//    _slidingImageView.layer.borderColor = [UIColor blackColor].CGColor;
//    _slidingImageView.layer.borderWidth = 1.0;
}

+ (UIButton *)defaultButton {
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.backgroundColor = [UIColor purpleColor];
    button.titleLabel.textColor = [UIColor whiteColor];
    return button;
}

//===============================================
#pragma mark -
#pragma mark Selection & Highlighting
//===============================================

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    
    self.colorIndicatorView.hidden = highlighted;
    [self setAllButtonsHidden:highlighted onSide:PTSwipeCellSideRight];
    [self setAllButtonsHidden:highlighted onSide:PTSwipeCellSideLeft];
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    [super setHighlighted:highlighted animated:animated];
    
    self.colorIndicatorView.hidden = highlighted;
    [self setAllButtonsHidden:highlighted onSide:PTSwipeCellSideRight];
    [self setAllButtonsHidden:highlighted onSide:PTSwipeCellSideLeft];
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    
    self.colorIndicatorView.hidden = selected;
    [self setAllButtonsHidden:selected onSide:PTSwipeCellSideRight];
    [self setAllButtonsHidden:selected onSide:PTSwipeCellSideLeft];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    
    self.colorIndicatorView.hidden = selected;
    [self setAllButtonsHidden:selected onSide:PTSwipeCellSideRight];
    [self setAllButtonsHidden:selected onSide:PTSwipeCellSideLeft];
}

//===============================================
#pragma mark -
#pragma mark UIGestureRecognizerDelegate
//===============================================

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    
    if ([gestureRecognizer class] == [UIPanGestureRecognizer class]) {
        
        UIPanGestureRecognizer *pgr = (UIPanGestureRecognizer *)gestureRecognizer;
        CGPoint velocity = [pgr velocityInView:self];
        
        if (fabsf(velocity.x) > fabsf(velocity.y) ) {
            return YES;
        }
    }
    return NO;
}

//===============================================
#pragma mark -
#pragma mark UIPanGestureRecognizer
//===============================================

- (void)handlePanGestureRecognizer:(UIPanGestureRecognizer *)gesture {
    
    // We can't really use velocityInView because the gesture recognizer doesn't update the value upon Ended or Cancelled. It just gives you the previous value, even if you hold your finger down without moving for a long time.
    //    CGFloat panGestureVelocityInViewX = [gesture velocityInView:self].x;
    //    NSLog(@"panGestureVelocityInViewX = %f", panGestureVelocityInViewX);
    
    [self.dynamicAnimator removeAllBehaviors];
    
    //
    // There's a weird behavior where the contentView ends up 1/2 a pixel lower than it should be while it is animating. At the end of the animation, let's move it back to its "home" frame. homeFrm starts off as CGRectZero, and it gets set here when the very first pan gesture begins.
    //
    if (gesture.state == UIGestureRecognizerStateBegan) {
        
        self.dragging = YES;
        
        if (CGRectGetWidth(self.homeFrm) < 1.0) {
            self.homeFrm = self.contentView.frame;
        }
        
        if (self.leftConfiguration == PTSwipeCellConfigurationButtons && !_leftButtonsHaveBeenAdded) {
            [self layoutButtonsOnSide:PTSwipeCellSideLeft];
        }
        else if (self.rightConfiguration == PTSwipeCellConfigurationButtons && !_rightButtonsHaveBeenAdded) {
            [self layoutButtonsOnSide:PTSwipeCellSideRight];
        }
    }
    
    static CGFloat lastDeltaX_forVelocityCalculation;
    
    CGPoint translation = [gesture translationInView:self];
    
    [self translateContentViewAlongXaxis:translation.x];
    
    self.revealedSide = [self currentRevealedSide];
    
    self.draggingIndex = [self currentDraggingIndex];
    
    self.imageIndex = [self currentImageIndex];
    
    [self updateSliderFrame];
    
    self.colorIndicatorView.backgroundColor = [self currentColor];
    
    if (self.revealedSide == PTSwipeCellSideLeft) {
        self.buttonRevealState = PTSwipeCellButtonRevealStateLeftExposed;
    }
    else if (self.revealedSide == PTSwipeCellSideRight) {
        self.buttonRevealState = PTSwipeCellButtonRevealStateRightExposed;
    }
    else if (self.revealedSide == PTSwipeCellSideCenter) {
        self.buttonRevealState = PTSwipeCellButtonRevealStateCovered;
    }
    
    //
    // When state is Ended or Cancelled, translationInView always returns CGPointZero. Therefore only cache the delta X if the state is Changed.
    //
    if (gesture.state == UIGestureRecognizerStateChanged) {
        lastDeltaX_forVelocityCalculation = translation.x;
    }
    else if (gesture.state == UIGestureRecognizerStateEnded || gesture.state == UIGestureRecognizerStateCancelled) {
        
        self.dragging = NO;
        
        CGFloat panVelocityX = lastDeltaX_forVelocityCalculation / (-1.0 * [self.lastPanTime_forVelocityCalculation timeIntervalSinceNow]);
        panVelocityX = MIN(10000.0, panVelocityX);
        panVelocityX = MAX(-10000.0, panVelocityX);
        
        if (self.revealedSide == PTSwipeCellSideLeft) {
            if (self.leftConfiguration == PTSwipeCellConfigurationSwipeAndRelease) {
                [self beginAnimationToState:PTSwipeCellButtonRevealStateCovered withPanVelocityX:panVelocityX animationStyle:self.leftAnimationStyle];
            }
            else if (self.leftConfiguration == PTSwipeCellConfigurationButtons) {
                
                PTSwipeCellButtonRevealState restingState = [self restingButtonRevealStateForPanVelocityX:panVelocityX];
                [self beginAnimationToState:restingState withPanVelocityX:panVelocityX animationStyle:self.leftAnimationStyle];
            }
        }
        else if (self.revealedSide == PTSwipeCellSideRight) {
            if (self.rightConfiguration == PTSwipeCellConfigurationSwipeAndRelease) {
                [self beginAnimationToState:PTSwipeCellButtonRevealStateCovered withPanVelocityX:panVelocityX animationStyle:self.rightAnimationStyle];
            }
            else if (self.rightConfiguration == PTSwipeCellConfigurationButtons) {
                
                PTSwipeCellButtonRevealState restingState = [self restingButtonRevealStateForPanVelocityX:panVelocityX];
                [self beginAnimationToState:restingState withPanVelocityX:panVelocityX animationStyle:self.rightAnimationStyle];
            }
        }
        else {
            [self beginGravityAnimationToCenterWithPanVelocityX:panVelocityX];
        }
        
        if (self.draggingIndex != -1) {
            if ([self.delegate respondsToSelector:@selector(swipeCell:didReleaseAt:onSide:)]) {
                [self.delegate swipeCell:self didReleaseAt:self.draggingIndex onSide:self.revealedSide];
            }
        }
    }
    
    [gesture setTranslation:CGPointZero inView:self];
    self.lastPanTime_forVelocityCalculation = [NSDate date];
}

- (void)translateContentViewAlongXaxis:(CGFloat)translationX {
    
    CGRect frm = self.contentView.frame;
    CGFloat newX = CGRectGetMinX(frm) + translationX;
    CGFloat maxX = CGRectGetWidth(self.contentView.bounds);
    CGFloat minX = -1.0 * maxX;
    if (self.leftConfiguration == PTSwipeCellConfigurationNone) maxX = 0.0;
    if (self.rightConfiguration == PTSwipeCellConfigurationNone) minX = 0.0;
    if (newX > maxX) newX = maxX;
    if (newX < minX) newX = minX;
    frm.origin.x = newX;
    self.contentView.frame = frm;
}

- (void)updateSliderFrame {
    
    CGRect frm = self.slidingImageView.frame;
    frm.size = CGSizeMake(50.0, 50.0);
    frm.origin.y = (CGRectGetHeight(self.bounds) - CGRectGetHeight(frm)) / 2.0;
    
    if (self.revealedSide == PTSwipeCellSideRight) {
        CGFloat xPoint = CGRectGetMaxX(self.contentView.frame);
        CGFloat maxX = CGRectGetWidth(self.bounds) - CGRectGetWidth(frm);
        if (xPoint > maxX || !self.rightSliderShouldSlide) xPoint = maxX;
        frm.origin.x = xPoint;
    }
    else if (self.revealedSide == PTSwipeCellSideLeft) {
        CGFloat xPoint = CGRectGetMinX(self.contentView.frame) - CGRectGetWidth(frm);
        CGFloat minX = 0.0;
        if (xPoint < minX || !self.leftSliderShouldSlide) xPoint = minX;
        frm.origin.x = xPoint;
    }
    
    self.slidingImageView.frame = frm;
}

//===============================================
#pragma mark -
#pragma mark Dynamic Animator
//===============================================

- (void)animateToCoveredStateIfExposed {
    if (self.buttonRevealState != PTSwipeCellButtonRevealStateCovered) {
        [self.dynamicAnimator removeAllBehaviors];
        [self beginAnimationToState:PTSwipeCellButtonRevealStateCovered withPanVelocityX:0.0 animationStyle:[self animationStyleForSide:self.revealedSide]];
    }
}

- (void)beginAnimationToState:(PTSwipeCellButtonRevealState)revealState withPanVelocityX:(CGFloat)velocityX animationStyle:(PTSwipeCellAnimationStyle)animationStyle {
    
    self.buttonRevealState = revealState;
    
    if (animationStyle == PTSwipeCellAnimationStyleGravity) {
        [self beginGravityAnimationToState:revealState withPanVelocityX:velocityX];
    }
    else if (animationStyle == PTSwipeCellAnimationStyleSnap) {
        [self beginSnapAnimationToState:revealState withPanVelocityX:velocityX];
    }
}

//- (void)beginAnimationToCenterWithPanVelocityX:(CGFloat)velocityX animationStyle:(PTSwipeCellAnimationStyle)animationStyle {
//    
//    if (animationStyle == PTSwipeCellAnimationStyleGravity) {
//        [self beginGravityAnimationToCenterWithPanVelocityX:velocityX];
//    }
//    else if (animationStyle == PTSwipeCellAnimationStyleSnap) {
//        [self beginSnapAnimationToCenterWithPanVelocityX:velocityX];
//    }
//}

- (void)beginGravityAnimationToCenterWithPanVelocityX:(CGFloat)velocityX {
    [self beginGravityAnimationToState:PTSwipeCellButtonRevealStateCovered withPanVelocityX:velocityX];
}

- (void)beginGravityAnimationToState:(PTSwipeCellButtonRevealState)revealState withPanVelocityX:(CGFloat)velocityX {
    
    UIBezierPath *collisionBoundary = [self boundaryPathForEndingState:revealState];
    
    [self.boundaryCollisionBehavior removeAllBoundaries];
    [self.boundaryCollisionBehavior addBoundaryWithIdentifier:MSDynamicsDrawerBoundaryIdentifier forPath:collisionBoundary];
    [self.dynamicAnimator addBehavior:self.boundaryCollisionBehavior];
    
    self.gravityBehavior.magnitude = self.gravityMagnitude;
    self.gravityBehavior.angle = [self gravityAngleForEndingState:revealState];
    [self.dynamicAnimator addBehavior:self.gravityBehavior];
    
    [self.elasticityBehavior addLinearVelocity:CGPointMake(velocityX / 5.0, 0.0) forItem:self.contentView]; // / 5.0
    self.elasticityBehavior.elasticity = self.elasticity;
    self.elasticityBehavior.allowsRotation = NO;
    [self.dynamicAnimator addBehavior:self.elasticityBehavior];
    
    // If we give the item some initial velocity, we don't need to use the UIPushBehavior.
//    CGFloat pushMagnitude = fabsf(velocityX) * MSPaneViewVelocityMultiplier;
//    self.pushBehaviorInstantaneous.angle = velocityX > 0.0 ? 0.0 : M_PI;
//    self.pushBehaviorInstantaneous.magnitude = pushMagnitude;
//    NSLog(@"angle %f | magnitude %f", self.pushBehaviorInstantaneous.angle, self.pushBehaviorInstantaneous.magnitude);
//    [self.dynamicAnimator addBehavior:self.pushBehaviorInstantaneous];
//    self.pushBehaviorInstantaneous.active = YES;
}

//- (void)beginSnapAnimationToCenterWithPanVelocityX:(CGFloat)velocityX {
//    
//    [self.elasticityBehavior addLinearVelocity:CGPointMake(velocityX, 0.0) forItem:self.contentView];
//    self.elasticityBehavior.allowsRotation = NO;
//    [self.dynamicAnimator addBehavior:self.elasticityBehavior];
//    
//    // This doesn't seem to work right (think i fixed it though). If no boundary is set, the contentView will wobble around its center point (just add another behavior with allowsRotation = NO to fix this). If there is a boundary, the view looks like it gets stuck on the way back to center (this was due to a gravity behavior. get rid of the gravity behavior and the view will animate all the way back to the proper point).
//    CGPoint snapPoint = CGPointMake(CGRectGetWidth(self.contentView.bounds) / 2.0, CGRectGetHeight(self.contentView.bounds) / 2.0);
//    UISnapBehavior *snapBehavior = [[UISnapBehavior alloc] initWithItem:self.contentView snapToPoint:snapPoint];
//    snapBehavior.damping = 0.35;
//    [self.dynamicAnimator addBehavior:snapBehavior];
//}

- (void)beginSnapAnimationToState:(PTSwipeCellButtonRevealState)revealState withPanVelocityX:(CGFloat)velocityX {
    
    [self.elasticityBehavior addLinearVelocity:CGPointMake(velocityX, 0.0) forItem:self.contentView];
    self.elasticityBehavior.allowsRotation = NO;
    [self.dynamicAnimator addBehavior:self.elasticityBehavior];
    
    CGPoint snapPoint;
    if (revealState == PTSwipeCellButtonRevealStateCovered) {
        snapPoint = CGPointMake(CGRectGetWidth(self.contentView.bounds) / 2.0, CGRectGetHeight(self.contentView.bounds) / 2.0);
    }
    else if (revealState == PTSwipeCellButtonRevealStateLeftExposed) {
        CGFloat exposedWidth = [self exposurePointXforSide:PTSwipeCellSideLeft];
        snapPoint = CGPointMake(CGRectGetWidth(self.contentView.bounds) / 2.0 + exposedWidth, CGRectGetHeight(self.contentView.bounds) / 2.0);
    }
    else if (revealState == PTSwipeCellButtonRevealStateRightExposed) {
        CGFloat exposedWidth = CGRectGetWidth(self.contentView.bounds) - [self exposurePointXforSide:PTSwipeCellSideRight];
        snapPoint = CGPointMake(CGRectGetWidth(self.contentView.bounds) / 2.0 - exposedWidth, CGRectGetHeight(self.contentView.bounds) / 2.0);
    }
    
    // This doesn't seem to work right (think i fixed it though). If no boundary is set, the contentView will wobble around its center point (just add another behavior with allowsRotation = NO to fix this). If there is a boundary, the view looks like it gets stuck on the way back to center (this was due to a gravity behavior. get rid of the gravity behavior and the view will animate all the way back to the proper point).
//    CGPoint snapPoint = CGPointMake(CGRectGetWidth(self.contentView.bounds) / 2.0, CGRectGetHeight(self.contentView.bounds) / 2.0);
    UISnapBehavior *snapBehavior = [[UISnapBehavior alloc] initWithItem:self.contentView snapToPoint:snapPoint];
    snapBehavior.damping = self.snapDamping;
    [self.dynamicAnimator addBehavior:snapBehavior];
}

//- (void)beginAnimationToExposeButtonSide:(PTSwipeCellSide)side withPanVelocityX:(CGFloat)velocityX animationStyle:(PTSwipeCellAnimationStyle)animationStyle {
//    
//    if (animationStyle == PTSwipeCellAnimationStyleGravity) {
//        [self beginGravityAnimationToCenterWithPanVelocityX:velocityX];
//    }
//    else if (animationStyle == PTSwipeCellAnimationStyleSnap) {
//        [self beginSnapAnimationToState:PTSwipeCellButtonRevealStateExposed onSide:side withPanVelocityX:velocityX];
//    }
//}

- (UIBezierPath *)boundaryPathForState {
    
    CGRect boundary = CGRectZero;
    boundary.origin.y = -1.0;
    boundary.size.height = (CGRectGetHeight(self.bounds) + 1.0);
    boundary.size.width = ((CGRectGetWidth(self.contentView.bounds) * 2.0) + 2.0);
    boundary.origin.x = (self.revealedSide == PTSwipeCellSideRight) ? -1.0 * CGRectGetWidth(self.contentView.bounds) - 1.0 : -1.0;
    return [UIBezierPath bezierPathWithRect:boundary];
}

- (UIBezierPath *)boundaryPathForEndingState:(PTSwipeCellButtonRevealState)endingRevealState {
    
    CGRect boundary = CGRectZero;
    boundary.origin.y = -1.0;
    boundary.size.height = (CGRectGetHeight(self.bounds) + 1.0);
    
    if (endingRevealState == PTSwipeCellButtonRevealStateCovered) {
        
        boundary.size.width = ((CGRectGetWidth(self.contentView.bounds) * 2.0) + 2.0);
        boundary.origin.x = (self.revealedSide == PTSwipeCellSideRight) ? -1.0 * CGRectGetWidth(self.contentView.bounds) - 1.0 : -1.0;
    }
    else if (endingRevealState == PTSwipeCellButtonRevealStateLeftExposed) {
        
        CGFloat rightEdgeOfRightmostButton = [self exposurePointXforSide:PTSwipeCellSideLeft];
        CGFloat currentLeftEdge = CGRectGetMinX(self.contentView.frame);
        if (currentLeftEdge < rightEdgeOfRightmostButton) {
            boundary.size.width = (CGRectGetWidth(self.contentView.bounds) + rightEdgeOfRightmostButton + 2.0);
            boundary.origin.x = -1.0;
        }
        else {
            boundary.size.width = (CGRectGetWidth(self.contentView.bounds) * 2.0 + 2.0);
            boundary.origin.x = rightEdgeOfRightmostButton - 1.0;
        }
    }
    else if (endingRevealState == PTSwipeCellButtonRevealStateRightExposed) {
        
        CGFloat leftEdgeOfLeftmostButton = [self exposurePointXforSide:PTSwipeCellSideRight];
        CGFloat currentRightEdge = CGRectGetMaxX(self.contentView.frame);
        CGFloat exposedWidth = CGRectGetWidth(self.contentView.bounds) - leftEdgeOfLeftmostButton;
        if (currentRightEdge < leftEdgeOfLeftmostButton) {
            boundary.size.width = (CGRectGetWidth(self.contentView.bounds) * 2.0 + 2.0);
            boundary.origin.x = -1.0 * CGRectGetWidth(self.contentView.bounds) - exposedWidth - 1.0;
        }
        else {
            boundary.size.width = (CGRectGetWidth(self.contentView.bounds) + exposedWidth + 2.0);
            boundary.origin.x = -1.0 * exposedWidth - 1.0;
        }
    }
    
    return [UIBezierPath bezierPathWithRect:boundary];
}

- (CGFloat)gravityAngleForEndingState:(PTSwipeCellButtonRevealState)endingRevealState {
    
    if (endingRevealState == PTSwipeCellButtonRevealStateCovered) {
        return (self.revealedSide == PTSwipeCellSideRight) ? 0.0 : M_PI;
    }
    else if (endingRevealState == PTSwipeCellButtonRevealStateLeftExposed) {
        CGFloat rightEdgeOfRightmostButton = [self exposurePointXforSide:PTSwipeCellSideLeft];
        CGFloat currentLeftEdge = CGRectGetMinX(self.contentView.frame);
        return (currentLeftEdge < rightEdgeOfRightmostButton) ? 0.0 : M_PI;
    }
    else if (endingRevealState == PTSwipeCellButtonRevealStateRightExposed) {
        CGFloat leftEdgeOfLeftmostButton = [self exposurePointXforSide:PTSwipeCellSideRight];
        CGFloat currentRightEdge = CGRectGetMaxX(self.contentView.frame);
        return (currentRightEdge < leftEdgeOfLeftmostButton) ? 0.0 : M_PI;
    }
    return 0.0;
}

- (void)beginGravityAnimationOffScreenWithPanVelocityX:(CGFloat)velocityX {
    
    [self.boundaryCollisionBehavior removeAllBoundaries];
    [self.boundaryCollisionBehavior addBoundaryWithIdentifier:MSDynamicsDrawerBoundaryIdentifier forPath:[self boundaryPathForState]];
    [self.dynamicAnimator addBehavior:self.boundaryCollisionBehavior];
    
    self.gravityBehavior.magnitude = self.gravityMagnitude;
    self.gravityBehavior.angle = (self.revealedSide == PTSwipeCellSideRight) ? M_PI : 0.0;
    [self.dynamicAnimator addBehavior:self.gravityBehavior];
    
    [self.elasticityBehavior addLinearVelocity:CGPointMake(velocityX, 0.0) forItem:self.contentView];
    self.elasticityBehavior.elasticity = 0.0;
    self.elasticityBehavior.allowsRotation = NO;
    [self.dynamicAnimator addBehavior:self.elasticityBehavior];
}

//===============================================
#pragma mark -
#pragma mark UIDynamicAnimatorDelegate
//===============================================

- (void)dynamicAnimatorDidPause:(UIDynamicAnimator *)animator {
    
    NSLog(@"dynamicAnimatorDidPause");
    
    [self.dynamicAnimator removeAllBehaviors];
    
    self.revealedSide = PTSwipeCellSideCenter;
    
//    self.colorIndicatorView.hidden = YES;
//    [self setAllButtonsHidden:YES onSide:PTSwipeCellSideLeft];
//    [self setAllButtonsHidden:YES onSide:PTSwipeCellSideRight];
    
    if (self.draggingIndex != -1 && [self.delegate respondsToSelector:@selector(swipeCell:didFinishAnimatingFrom:onSide:)]) {
        [self.delegate swipeCell:self didFinishAnimatingFrom:self.draggingIndex onSide:self.revealedSide];
    }
    
    // It turns out that we don't want to do this. If the user starts panning the cell in the middle of a dynamic animation, this will cause the contentView to jump back to zero. We want the contentView to stay where it is.
//    self.contentView.frame = self.homeFrm;
}

- (void)dynamicAnimatorWillResume:(UIDynamicAnimator *)animator {
    NSLog(@"dynamicAnimatorWillResume");
}

//===============================================
#pragma mark -
#pragma mark Helpers
//===============================================

- (PTSwipeCellSide)currentRevealedSide {
    
    CGFloat xPoint = CGRectGetMinX(self.contentView.frame);
    if (xPoint < 0.0) {
        return PTSwipeCellSideRight;
    }
    else if (xPoint > 0.0) {
        return PTSwipeCellSideLeft;
    }
    else {
        return PTSwipeCellSideCenter;
    }
}

- (CGFloat)currentRatio {
    
    CGFloat xOffset = CGRectGetMinX(self.contentView.frame);
    CGFloat fullWidth = CGRectGetWidth(self.bounds);
    
    CGFloat ratio = xOffset / fullWidth;
    if (xOffset < 0.0) ratio *= -1.0;
    if (ratio > 1.0) ratio = 1.0;
    else if (ratio < 0.0) ratio = 0.0;
    
    return ratio;
}

- (UIColor *)currentColor {
    
    if (self.draggingIndex != -1) {
        if (self.revealedSide == PTSwipeCellSideLeft) {
            if (self.leftConfiguration == PTSwipeCellConfigurationButtons) {
                return self.defaultColor;
            }
            return [self.leftColors objectAtIndex:self.draggingIndex];
        }
        else if (self.revealedSide == PTSwipeCellSideRight) {
            if (self.rightConfiguration == PTSwipeCellConfigurationButtons) {
                return self.defaultColor;
            }
            return [self.rightColors objectAtIndex:self.draggingIndex];
        }
    }
    return self.defaultColor;
}

- (NSString *)imageNameForIndex:(NSInteger)index onSide:(PTSwipeCellSide)side {
    
    if (index >= 0) {
        if (side == PTSwipeCellSideLeft) {
            if (index >= [self.leftImageNames count]) return nil;
            return [self.leftImageNames objectAtIndex:index];
        }
        else if (side == PTSwipeCellSideRight) {
            if (index >= [self.rightImageNames count]) return nil;
            return [self.rightImageNames objectAtIndex:index];
        }
    }
    return nil;
}

- (NSInteger)currentDraggingIndex {
    
    __block NSInteger draggingIndex = -1;
    
    if (self.revealedSide == PTSwipeCellSideLeft) {
        CGFloat ratio = [self currentRatio];
        [self.leftTriggerRatios enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            CGFloat triggerRatio = [obj floatValue];
            if (ratio >= triggerRatio) {
                draggingIndex = idx;
                *stop = YES;
            }
        }];
    }
    else if (self.revealedSide == PTSwipeCellSideRight) {
        CGFloat ratio = [self currentRatio];
        [self.rightTriggerRatios enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            CGFloat triggerRatio = [obj floatValue];
            if (ratio >= triggerRatio) {
                draggingIndex = idx;
                *stop = YES;
            }
        }];
    }
    return draggingIndex;
}

- (NSInteger)currentImageIndex {
    
    NSInteger currentTriggeredIndex = [self currentDraggingIndex];
    
    if (currentTriggeredIndex != -1) {
        return currentTriggeredIndex;
    }
    else {
        if (self.revealedSide == PTSwipeCellSideLeft) {
            if ([self.leftTriggerRatios count] > 0) {
                return 0;
            }
        }
        else if (self.revealedSide == PTSwipeCellSideRight) {
            if ([self.rightTriggerRatios count] > 0) {
                return 0;
            }
        }
    }
    return -1;
}

- (PTSwipeCellAnimationStyle)animationStyleForSide:(PTSwipeCellSide)side {
    return (side == PTSwipeCellSideLeft) ? self.leftAnimationStyle : self.rightAnimationStyle;
}

//===============================================
#pragma mark -
#pragma mark Button Setup
//===============================================

- (void)layoutButtonsOnSide:(PTSwipeCellSide)side {
    
    if (side == PTSwipeCellSideLeft) {
        
        if (self.leftButtons && [self.leftButtons count] > 0) {
            
            __block CGFloat xPoint = 0.0;
            [self.leftButtons enumerateObjectsUsingBlock:^(UIButton *button, NSUInteger idx, BOOL *stop) {
                CGRect frm = button.frame;
                frm.size.height = CGRectGetHeight(self.colorIndicatorView.frame);
                frm.origin.y = 0.0;
                frm.origin.x = xPoint;
                if (CGRectGetWidth(frm) < 1.0) frm.size.width = self.defaultButtonWidth;
                xPoint += CGRectGetWidth(frm);
                button.frame = frm;
                [self.colorIndicatorView addSubview:button];
            }];
        }
        _leftButtonsHaveBeenAdded = YES;
    }
    else if (side == PTSwipeCellSideRight) {
        
        if (self.rightButtons && [self.rightButtons count] > 0) {
            
            __block CGFloat xPoint = CGRectGetWidth(self.frame);
            [self.rightButtons enumerateObjectsUsingBlock:^(UIButton *button, NSUInteger idx, BOOL *stop) {
                CGRect frm = button.frame;
                frm.size.height = CGRectGetHeight(self.colorIndicatorView.frame);
                frm.origin.y = 0.0;
                if (CGRectGetWidth(frm) < 1.0) frm.size.width = self.defaultButtonWidth;
                xPoint -= CGRectGetWidth(frm);
                frm.origin.x = xPoint;
                button.frame = frm;
                [self.colorIndicatorView addSubview:button];
            }];
        }
        _rightButtonsHaveBeenAdded = YES;
    }
}

- (void)setButtonVisibility {
    
    if (self.revealedSide == PTSwipeCellSideLeft) {
        [self setAllButtonsHidden:YES onSide:PTSwipeCellSideRight];
        [self setAllButtonsHidden:NO onSide:PTSwipeCellSideLeft];
    }
    else if (self.revealedSide == PTSwipeCellSideRight) {
        [self setAllButtonsHidden:NO onSide:PTSwipeCellSideRight];
        [self setAllButtonsHidden:YES onSide:PTSwipeCellSideLeft];
    }
}

- (void)setAllButtonsHidden:(BOOL)hidden onSide:(PTSwipeCellSide)side {
    
    NSArray *array = [self buttonArrayForSide:side];
    if (!array) return;
    [array enumerateObjectsUsingBlock:^(UIButton *button, NSUInteger idx, BOOL *stop) {
        button.hidden = hidden;
    }];
}

- (NSArray *)buttonArrayForSide:(PTSwipeCellSide)side {
    switch (side) {
        case PTSwipeCellSideLeft:
            return self.leftButtons;
        case PTSwipeCellSideRight:
            return self.rightButtons;
        case PTSwipeCellSideCenter:
            return nil;
        default:
            return nil;
    }
}

- (PTSwipeCellButtonRevealState)restingButtonRevealStateForPanVelocityX:(CGFloat)panVelocityX {
    
    if (self.revealedSide == PTSwipeCellSideLeft) {
        if (panVelocityX > 0.1) return PTSwipeCellButtonRevealStateLeftExposed;
        else if (panVelocityX < -0.1) return PTSwipeCellButtonRevealStateCovered;
        else {
            CGFloat maxX = [self exposurePointXforSide:PTSwipeCellSideLeft];
            CGFloat currentX = CGRectGetMinX(self.contentView.frame);
            return (currentX > maxX / 2.0) ? PTSwipeCellButtonRevealStateLeftExposed : PTSwipeCellButtonRevealStateCovered;
        }
    }
    else if (self.revealedSide == PTSwipeCellSideRight) {
        if (panVelocityX < -0.1) return PTSwipeCellButtonRevealStateRightExposed;
        else if (panVelocityX > 0.1) return PTSwipeCellButtonRevealStateCovered;
        else {
            CGFloat minX = [self exposurePointXforSide:PTSwipeCellSideRight];
            CGFloat tripPointX = CGRectGetWidth(self.colorIndicatorView.bounds) - minX / 2.0;
            CGFloat currentX = CGRectGetMaxX(self.contentView.frame);
            return (currentX < tripPointX) ? PTSwipeCellButtonRevealStateRightExposed : PTSwipeCellButtonRevealStateCovered;
        }
    }
    return PTSwipeCellButtonRevealStateCovered;
}

- (CGFloat)exposurePointXforSide:(PTSwipeCellSide)side {
    
    if (side == PTSwipeCellSideLeft) {
        UIButton *rightmostButton = [self.leftButtons lastObject];
        if (rightmostButton) {
            return CGRectGetMaxX(rightmostButton.frame);
        }
        return 99999.0;
    }
    else if (side == PTSwipeCellSideRight) {
        UIButton *leftmostButton = [self.rightButtons lastObject];
        if (leftmostButton) {
            return CGRectGetMinX(leftmostButton.frame);
        }
        return -99999.0;
    }
    return 0.0;
}

//===============================================
#pragma mark -
#pragma mark NSKeyValueObserving
//===============================================
//
// I tried using KeyValueObserving to get callbacks on the contentView's position as it is being animated by UIKit Dynamics, but that doesn't happen.
//
//- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
//    
//    if([keyPath isEqualToString:@"frame"] && (object == self.contentView)) {
//        if([object valueForKeyPath:keyPath] != [NSNull null]) {
//            [self contentViewDidUpdateFrame];
//        }
//    }
//}
//- (void)contentViewDidUpdateFrame {
//    NSLog(@"observed");
//}
//- (void)dealloc {
//    [self.contentView removeObserver:self forKeyPath:@"frame"];
//}

@end
