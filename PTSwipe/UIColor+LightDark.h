//
//  UIColor+LightDark.h
//  SteamThermo
//
//  Created by Phillip Harris on 2/20/13.
//  Copyright (c) 2013 Phillip Harris. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (LightDark)

+ (UIColor*)r:(int)r g:(int)g b:(int)b;
- (void)log;

- (UIColor *)lighterColor;
- (UIColor *)darkerColor;
- (UIColor *)lessSaturated;
- (UIColor *)completelyDesaturated;
- (UIColor *)makeGrayScale;

+ (NSArray *)sevenColors;
+ (UIColor *)sevenRed;
+ (UIColor *)sevenOrange;
+ (UIColor *)sevenYellow;
+ (UIColor *)sevenGreen;
+ (UIColor *)sevenBlue;
+ (UIColor *)sevenIndigo;
+ (UIColor *)seveniTunesPurple;

+ (UIColor *)sevenPink;
+ (UIColor *)sevenGrey;
+ (UIColor *)sevenSkyBlue1;
+ (UIColor *)sevenSkyBlue2;


+ (UIColor *)sevenGroupedTableViewHeaderTextGray;
+ (UIColor *)sevenGroupedTableSeparatorLineGray;
+ (UIColor *)sevenSwitchGreen;
+ (UIColor *)sevenGroupedTableViewBackground;
+ (UIColor *)sevenNavigationBarBackground;
+ (UIColor *)sevenGreyedOutTableText;


+ (UIColor *)testingRed;
+ (UIColor *)testingGreen;
+ (UIColor *)testingBlue;


+ (UIColor *)colorFromStringRepresentation:(NSString *)string;
- (NSString *)stringRepresentation;

@end
