//
//  UIColor+LightDark.m
//  SteamThermo
//
//  Created by Phillip Harris on 2/20/13.
//  Copyright (c) 2013 Phillip Harris. All rights reserved.
//

#import "UIColor+LightDark.h"

@implementation UIColor (LightDark)

//===============================================
#pragma mark -
#pragma mark Helper
//===============================================

+ (UIColor*)r:(int)r g:(int)g b:(int)b {
    return [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:1.0];
}

- (void)log {
    
    float r, g, b, a;
    [self getRed:&r green:&g blue:&b alpha:&a];
    NSLog(@"r:%f g:%f b:%f a:%f", r, g, b, a);
}

//===============================================
#pragma mark -
#pragma mark Modify Existing Colors
//===============================================

- (UIColor *)lighterColor
{
    float h, s, b, a;
    if ([self getHue:&h saturation:&s brightness:&b alpha:&a])
        return [UIColor colorWithHue:h saturation:s brightness:MIN(b * 1.3, 1.0) alpha:a];
    return nil;
}

- (UIColor *)darkerColor
{
    float h, s, b, a;
    if ([self getHue:&h saturation:&s brightness:&b alpha:&a])
        return [UIColor colorWithHue:h saturation:s brightness:b * 0.7 alpha:a];
    return nil;
}

- (UIColor *)lessSaturated
{
    float h, s, b, a;
    if ([self getHue:&h saturation:&s brightness:&b alpha:&a])
        return [UIColor colorWithHue:h saturation:s * 0.6 brightness:b alpha:a];
    return nil;
}

- (UIColor *)completelyDesaturated {
    
    float h, s, b, a;
    if ([self getHue:&h saturation:&s brightness:&b alpha:&a])
        return [UIColor colorWithHue:h saturation:0.0 brightness:b alpha:a];
    return nil;
}

- (UIColor *)makeGrayScale {
    
    float w, a;
    if ([self getWhite:&w alpha:&a]) {
        return [UIColor colorWithWhite:w alpha:a];
    }
    return nil;
}

//===============================================
#pragma mark -
#pragma mark iOS 7 Colors
//===============================================

+ (NSArray *)sevenColors {
    
    return @[[UIColor sevenRed], [UIColor sevenOrange], [UIColor sevenYellow], [UIColor sevenGreen], [UIColor sevenBlue], [UIColor sevenIndigo], [UIColor seveniTunesPurple]];
}

// Calendar, Clock, Compass
+ (UIColor *)sevenRed {
    
    return [UIColor r:255 g:59 b:48];
}

// Reminders, Calculator
+ (UIColor *)sevenOrange {
    
    return [UIColor r:255 g:149 b:0];
}

// Notes, Camera
+ (UIColor *)sevenYellow {
    
    return [UIColor r:255 g:204 b:0];
}

// Battery, Contacts Icon
+ (UIColor *)sevenGreen {
    
    return [UIColor r:76 g:217 b:100];
}

// Messages, Photos, Maps, Newsstand, App Store, Passbook, Settings, Safari, Phone, Mail, Contacts, Facetime
+ (UIColor *)sevenBlue {
    
    return [UIColor r:0 g:122 b:255];
}

// Game Center
+ (UIColor *)sevenIndigo {
    
    return [UIColor r:88 g:86 b:214];
}

// iTunes Icon
+ (UIColor *)seveniTunesPurple {
    
    return [UIColor r:200 g:67 b:250];
}

// Music
+ (UIColor *)sevenPink {
    
    return [UIColor r:255 g:45 b:85];
}

// Weather
+ (UIColor *)sevenGrey {
    
    return [UIColor r:142 g:142 b:147];
}

// Videos, iTunes Store
+ (UIColor *)sevenSkyBlue1 {
    
    return [UIColor r:52 g:170 b:220];
}

// Videos, iTunes Store
+ (UIColor *)sevenSkyBlue2 {
    
    return [UIColor r:90 g:200 b:250];
}

//===============================================
#pragma mark -
#pragma mark Other iOS 7 Colors
//===============================================

+ (UIColor *)sevenGroupedTableViewHeaderTextGray {
    
    return [UIColor r:109 g:109 b:114];
}

+ (UIColor *)sevenGroupedTableSeparatorLineGray {
    
    return [UIColor r:200 g:199 b:204];
}

+ (UIColor *)sevenSwitchGreen {
    
    return [UIColor r:67 g:217 b:93];
}

+ (UIColor *)sevenGroupedTableViewBackground {
    
    return [UIColor r:239 g:239 b:244];
}

+ (UIColor *)sevenNavigationBarBackground {
    
    return [UIColor colorWithWhite:247.0/255.0 alpha:0.99];
}

+ (UIColor *)sevenGreyedOutTableText {
    
    return [UIColor r:200 g:200 b:205]; // my custom color to make it even lighter
    return [UIColor r:148 g:148 b:152]; // actual color in Clock.app
}

//===============================================
#pragma mark -
#pragma mark Colors for Testing
//===============================================

+ (UIColor *)testingRed {
    
    return [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:0.5];
}

+ (UIColor *)testingGreen {
    
    return [UIColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:0.5];
}

+ (UIColor *)testingBlue {
    
    return [UIColor colorWithRed:0.0 green:0.0 blue:1.0 alpha:0.5];
}

//===============================================
#pragma mark -
#pragma mark Strings for Colors for Saving to Dropbox
//===============================================

+ (UIColor *)colorFromStringRepresentation:(NSString *)string {
    
    if (!string) {
        return [UIColor blackColor];
    }
    
    NSArray *components = [string componentsSeparatedByString:@"."];
    
    if ([components count] < 3) {
        return [UIColor blackColor];
    }
    
    int red = [components[0] intValue];
    int green = [components[1] intValue];
    int blue = [components[2] intValue];
    
    return [UIColor r:red g:green b:blue];
}

- (NSString *)stringRepresentation {
    
    float r, g, b, a;
    [self getRed:&r green:&g blue:&b alpha:&a];
    int red = 255 * r;
    int green = 255 * g;
    int blue = 255 * b;
    
    return [NSString stringWithFormat:@"%i.%i.%i", red, green, blue];
}

- (void)testForColorLoss {
    
    NSArray *sevenColors = [UIColor sevenColors];
    
    for (UIColor *color in sevenColors) {
        
        NSString *string = [color stringRepresentation];
        NSLog(@"%@", string);
        
        UIColor *newColor = [UIColor colorFromStringRepresentation:string];
        NSString *newString = [newColor stringRepresentation];
        NSLog(@"%@", newString);
    }
}

@end
