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
    
    _dragging = NO;
    _draggingIndex = -1;
    _imageIndex = -1;
    _leftSliderShouldSlide = YES;
    _rightSliderShouldSlide = YES;
    
    _defaultColor = [UIColor lightGrayColor];
    
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
    
    self.gravityMagnitude = 3.0;
    self.elasticity = 0.3;
    
    _homeFrm = CGRectZero;
    
//    _slidingImageView.layer.borderColor = [UIColor blackColor].CGColor;
//    _slidingImageView.layer.borderWidth = 1.0;
}

//===============================================
#pragma mark -
#pragma mark Dynamic Animator
//===============================================

- (void)beginGravityAnimationToCenterWithPanVelocityX:(CGFloat)velocityX {
    
    [self.boundaryCollisionBehavior removeAllBoundaries];
    [self.boundaryCollisionBehavior addBoundaryWithIdentifier:MSDynamicsDrawerBoundaryIdentifier forPath:[self boundaryPathForState]];
    [self.dynamicAnimator addBehavior:self.boundaryCollisionBehavior];
    
    self.gravityBehavior.magnitude = self.gravityMagnitude;
    self.gravityBehavior.angle = [self gravityAngleForState];
    [self.dynamicAnimator addBehavior:self.gravityBehavior];
    
    [self.elasticityBehavior addLinearVelocity:CGPointMake(velocityX / 5.0, 0.0) forItem:self.contentView];
    self.elasticityBehavior.elasticity = self.elasticity;
    self.elasticityBehavior.allowsRotation = NO;
    [self.dynamicAnimator addBehavior:self.elasticityBehavior];
    
    // This doesn't seem to work right. If no boundary is set, the contentView will wobble around its center point. If there is a boundary, the view looks like it gets stuck on the way back to center.
//    UISnapBehavior *snapBehavior = [[UISnapBehavior alloc] initWithItem:self.contentView snapToPoint:CGPointMake(CGRectGetWidth(self.contentView.bounds) / 2.0, CGRectGetHeight(self.contentView.bounds) / 2.0)];
//    snapBehavior.damping = 0.2;
//    [self.dynamicAnimator addBehavior:snapBehavior];
    
    // If we give the item some initial velocity, we don't need to use the UIPushBehavior.
//    CGFloat pushMagnitude = fabsf(velocityX) * MSPaneViewVelocityMultiplier;
//    self.pushBehaviorInstantaneous.angle = velocityX > 0.0 ? 0.0 : M_PI;
//    self.pushBehaviorInstantaneous.magnitude = pushMagnitude;
//    NSLog(@"angle %f | magnitude %f", self.pushBehaviorInstantaneous.angle, self.pushBehaviorInstantaneous.magnitude);
//    [self.dynamicAnimator addBehavior:self.pushBehaviorInstantaneous];
//    self.pushBehaviorInstantaneous.active = YES;
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

- (UIBezierPath *)boundaryPathForState {
    
    CGRect boundary = CGRectZero;
    boundary.origin.y = -1.0;
    boundary.size.height = (CGRectGetHeight(self.bounds) + 1.0);
    boundary.size.width = ((CGRectGetWidth(self.contentView.bounds) * 2.0) + 2.0);
    boundary.origin.x = (self.revealedSide == PTSwipeCellSideRight) ? -1.0 * CGRectGetWidth(self.contentView.bounds) - 1.0 : -1.0;
    return [UIBezierPath bezierPathWithRect:boundary];
}

- (CGFloat)gravityAngleForState {
    return (self.revealedSide == PTSwipeCellSideRight) ? 0.0 : M_PI;
}

//===============================================
#pragma mark -
#pragma mark UIDynamicAnimatorDelegate
//===============================================

- (void)dynamicAnimatorDidPause:(UIDynamicAnimator *)animator {
    
    NSLog(@"didPause");
    
    [self.dynamicAnimator removeAllBehaviors];
    
    if (self.draggingIndex != -1 && [self.delegate respondsToSelector:@selector(swipeCell:didFinishAnimatingFrom:onSide:)]) {
        [self.delegate swipeCell:self didFinishAnimatingFrom:self.draggingIndex onSide:self.revealedSide];
    }
    
    // It turns out that we don't want to do this. If the user starts panning the cell in the middle of a dynamic animation, this will cause the contentView to jump back to zero. We want the contentView to stay where it is.
//    self.contentView.frame = self.homeFrm;
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
    }
    
    static CGFloat lastDeltaX_forVelocityCalculation;
    
    CGPoint translation = [gesture translationInView:self];
    
    [self translateContentViewAlongXaxis:translation.x];
    
    self.revealedSide = [self currentRevealedSide];
    
    self.draggingIndex = [self currentDraggingIndex];
    
    self.imageIndex = [self currentImageIndex];
    
    [self updateSliderFrame];
    
    self.colorIndicatorView.backgroundColor = [self currentColor];
    
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
        
//        if (self.imageIndex == 0) {
//            [self beginGravityAnimationToCenterWithPanVelocityX:panVelocityX];
//        }
//        else {
//            [self beginGravityAnimationOffScreenWithPanVelocityX:panVelocityX];
//        }
        [self beginGravityAnimationToCenterWithPanVelocityX:panVelocityX];
        
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
            return [self.leftColors objectAtIndex:self.draggingIndex];
        }
        else if (self.revealedSide == PTSwipeCellSideRight) {
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
