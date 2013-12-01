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
@property (nonatomic, assign) PTSwipeCellDirection direction;
@property (nonatomic, strong) NSNumber *index;
@property (nonatomic, strong) NSString *imageName;

@property (nonatomic, strong) UIDynamicAnimator *dynamicAnimator;
@property (nonatomic, strong) UIPushBehavior *pushBehaviorInstantaneous;
@property (nonatomic, strong) UIDynamicItemBehavior *elasticityBehavior;
@property (nonatomic, strong) UIGravityBehavior *gravityBehavior;
@property (nonatomic, strong) UICollisionBehavior *boundaryCollisionBehavior;

@property (nonatomic, strong) NSDate *lastPanTime;

@property (nonatomic, assign) CGRect homeFrm;

@end

@implementation PTSwipeCell

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
    
    _defaultColor = [UIColor purpleColor];
    
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
    
    _slidingImageView.layer.borderColor = [UIColor blackColor].CGColor;
    _slidingImageView.layer.borderWidth = 1.0;
}

//===============================================
#pragma mark -
#pragma mark Dynamic Animator
//===============================================

- (void)dynamicDudeWithPanVelocityX:(CGFloat)velocityX {
    
    [self.boundaryCollisionBehavior removeAllBoundaries];
    [self.boundaryCollisionBehavior addBoundaryWithIdentifier:MSDynamicsDrawerBoundaryIdentifier forPath:[self boundaryPathForState]];
    [self.dynamicAnimator addBehavior:self.boundaryCollisionBehavior];
    
    self.gravityBehavior.magnitude = self.gravityMagnitude;
    self.gravityBehavior.angle = [self gravityAngleForState];
    [self.dynamicAnimator addBehavior:self.gravityBehavior];
    
    [self.elasticityBehavior addLinearVelocity:CGPointMake(velocityX / 5.0, 0.0) forItem:self.contentView];
    self.elasticityBehavior.elasticity = _elasticity;
    self.elasticityBehavior.allowsRotation = NO;
    [self.dynamicAnimator addBehavior:self.elasticityBehavior];
    
    // This doesn't seem to work right. If no boundary is set, the contentView will wobble around its center point. If there is a boundary, the view looks like it gets stuck on the way back to center.
//    UISnapBehavior *snapBehavior = [[UISnapBehavior alloc] initWithItem:self.contentView snapToPoint:CGPointMake(CGRectGetWidth(self.contentView.bounds) / 2.0, CGRectGetHeight(self.contentView.bounds) / 2.0)];
//    snapBehavior.damping = 0.2;
//    [self.dynamicAnimator addBehavior:snapBehavior];
    
//    CGFloat pushMagnitude = fabsf(velocityX) * MSPaneViewVelocityMultiplier;
//    self.pushBehaviorInstantaneous.angle = velocityX > 0.0 ? 0.0 : M_PI;
//    self.pushBehaviorInstantaneous.magnitude = pushMagnitude;
//    NSLog(@"angle %f | magnitude %f", self.pushBehaviorInstantaneous.angle, self.pushBehaviorInstantaneous.magnitude);
//    [self.dynamicAnimator addBehavior:self.pushBehaviorInstantaneous];
//    self.pushBehaviorInstantaneous.active = YES;
}

- (UIBezierPath *)boundaryPathForState {
    
    CGRect boundary = CGRectZero;
    boundary.origin.y = -1.0;
    boundary.size.height = (CGRectGetHeight(self.bounds) + 1.0);
    boundary.size.width = ((CGRectGetWidth(self.contentView.bounds) * 2.0) + 2.0);
    boundary.origin.x = (_direction == PTSwipeCellDirectionLeft) ? -1.0 * CGRectGetWidth(self.contentView.bounds) - 1.0 : -1.0;
    return [UIBezierPath bezierPathWithRect:boundary];
}

- (CGFloat)gravityAngleForState {
    return (_direction == PTSwipeCellDirectionLeft) ? 0.0 : M_PI;
}

//===============================================
#pragma mark -
#pragma mark UIDynamicAnimatorDelegate
//===============================================

- (void)dynamicAnimatorDidPause:(UIDynamicAnimator *)animator {
    [self.dynamicAnimator removeAllBehaviors];
    
    self.contentView.frame = self.homeFrm;
}

//===============================================
#pragma mark -
#pragma mark UIPanGestureRecognizer
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

- (void)handlePanGestureRecognizer:(UIPanGestureRecognizer *)gesture {
    
    // We can't really use velocityInView because the gesture recognizer doesn't update the value upon Ended or Cancelled. It just gives you the previous value, even if you hold your finger down without moving for a long time.
//    CGFloat panGestureVelocityInViewX = [gesture velocityInView:self].x;
//    NSLog(@"panGestureVelocityInViewX = %f", panGestureVelocityInViewX);
    
    [self.dynamicAnimator removeAllBehaviors];
    
    //
    // There's a weird behavior where the contentView ends up 1/2 a pixel lower than it should be while it is animating. At the end of the animation, let's move it back to its "home" frame.
    //
    if (gesture.state == UIGestureRecognizerStateBegan) {
        if (CGRectGetWidth(self.homeFrm) < 1.0) {
            self.homeFrm = self.contentView.frame;
            NSLog(@"%@", NSStringFromCGRect(self.homeFrm));
        }
    }
    
    static CGFloat lastDeltaX;
    
    CGPoint translation = [gesture translationInView:self];
    
    [self translateContentViewAlongXaxis:translation.x];
    
    _index = [self currentTriggeredIndex];
    
    [self updateSliderImage];
    
    self.colorIndicatorView.backgroundColor = [self currentColor];
    
    //
    // When state is Ended or Cancelled, translationInView always returns CGPointZero. Therefore only cache the delta X if the state is Changed.
    //
    if (gesture.state == UIGestureRecognizerStateChanged) {
        lastDeltaX = translation.x;
    }
    else if (gesture.state == UIGestureRecognizerStateEnded || gesture.state == UIGestureRecognizerStateCancelled) {
        
        CGFloat panVelocityX = lastDeltaX / (-1.0 * [self.lastPanTime timeIntervalSinceNow]);
        panVelocityX = MIN(10000.0, panVelocityX);
        panVelocityX = MAX(-10000.0, panVelocityX);
        [self dynamicDudeWithPanVelocityX:panVelocityX];
        
        if (_index) {
            if ([self.delegate respondsToSelector:@selector(swipeCell:didExecuteItemAtIndex:)]) {
                [self.delegate swipeCell:self didExecuteItemAtIndex:[_index integerValue]];
            }
        }
    }
    
    [gesture setTranslation:CGPointZero inView:self];
    self.lastPanTime = [NSDate date];
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

- (void)updateSliderImage {
    
    NSString *imageName = [self currentImageName];
    
    [self.slidingImageView setImage:[UIImage imageNamed:imageName]];
    
    CGRect frm = self.slidingImageView.frame;
    frm.size = CGSizeMake(50.0, 50.0);
    frm.origin.y = (CGRectGetHeight(self.bounds) - CGRectGetHeight(frm)) / 2.0;
    
    if (self.direction == PTSwipeCellDirectionLeft) {
        frm.origin.x = CGRectGetMaxX(self.contentView.frame);
    }
    else if (self.direction == PTSwipeCellDirectionRight) {
        frm.origin.x = CGRectGetMinX(self.contentView.frame) - CGRectGetWidth(frm);
    }
    
    self.slidingImageView.frame = frm;
}

//===============================================
#pragma mark -
#pragma mark Helpers
//===============================================

- (PTSwipeCellDirection)currentDirection {
    
    CGFloat xPoint = CGRectGetMinX(self.contentView.frame);
    if (xPoint < 0) {
        return PTSwipeCellDirectionLeft;
    }
    else if (xPoint > 0) {
        return PTSwipeCellDirectionRight;
    }
    else {
        return PTSwipeCellDirectionCenter;
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
    
    if (_index) {
        if (_direction == PTSwipeCellDirectionLeft) {
            return [self.leftColors objectAtIndex:[_index integerValue]];
        }
        else if (_direction == PTSwipeCellDirectionRight) {
            return [self.rightColors objectAtIndex:[_index integerValue]];
        }
    }
    return self.defaultColor;
}

- (NSString *)currentImageName {
    
    if (self.index) {
        if (_direction == PTSwipeCellDirectionLeft) {
            return [self.leftImageNames objectAtIndex:[self.index integerValue]];
        }
        else if (_direction == PTSwipeCellDirectionRight) {
            return [self.rightImageNames objectAtIndex:[self.index integerValue]];
        }
    }
    return nil;
}

- (NSNumber *)currentTriggeredIndex {
    
    _direction = [self currentDirection];
    
    __block NSInteger triggered = -1;
    
    if (_direction == PTSwipeCellDirectionLeft) {
        CGFloat ratio = [self currentRatio];
        [self.leftTriggerRatios enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            CGFloat triggerRatio = [obj floatValue];
            if (ratio >= triggerRatio) {
                triggered = idx;
                *stop = YES;
            }
        }];
    }
    else if (_direction == PTSwipeCellDirectionRight) {
        CGFloat ratio = [self currentRatio];
        [self.rightTriggerRatios enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            CGFloat triggerRatio = [obj floatValue];
            if (ratio >= triggerRatio) {
                triggered = idx;
                *stop = YES;
            }
        }];
    }
    
    if (triggered < 0) {
        return nil;
    }
    return [NSNumber numberWithInteger:triggered];
}

- (NSNumber *)currentDisplayIndex {
    
    NSNumber *currentTriggeredIndex = [self currentTriggeredIndex];
    
    if (currentTriggeredIndex) {
        return currentTriggeredIndex;
    }
    else {
        if (self.direction == PTSwipeCellDirectionLeft) {
            if ([self.leftTriggerRatios count] > 0) {
                return @0;
            }
        }
        else if (self.direction == PTSwipeCellDirectionRight) {
            if ([self.rightTriggerRatios count] > 0) {
                return @0;
            }
        }
    }
    return nil;
}

//===============================================
#pragma mark -
#pragma mark Experimental
//===============================================

- (CGFloat)currentRatioUniversal {
    
    CGFloat xOffset = CGRectGetMinX(self.contentView.frame);
    CGFloat fullWidth = CGRectGetWidth(self.bounds);
    
    CGFloat ratio = xOffset / fullWidth;
    if (ratio > 1.0) ratio = 1.0;
    if (ratio < -1.0) ratio = -1.0;
    
    return ratio;
}

- (NSNumber *)triggeredUniversalIndex {
    
    CGFloat currentRatio = [self currentRatioUniversal];
    
    __block NSInteger triggered = -1;
    
    if (currentRatio < 0.0) {
        [self.triggerRatios enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            CGFloat triggerRatio = [obj floatValue];
            if (triggerRatio < 0.0 && currentRatio <= triggerRatio) {
                triggered = idx;
                *stop = YES;
            }
        }];
    }
    else if (currentRatio > 0.0) {
        [self.triggerRatios enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            CGFloat triggerRatio = [obj floatValue];
            if (triggerRatio > 0.0 && currentRatio >= triggerRatio) {
                triggered = idx;
                *stop = YES;
            }
        }];
    }
    
    if (triggered < 0) {
        return nil;
    }
    return [NSNumber numberWithInteger:triggered];
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
