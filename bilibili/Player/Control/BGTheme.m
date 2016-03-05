//
//  BGThemeManager.m
//  BGHUDAppKit
//
//  Created by BinaryGod on 6/15/08.
//
//  Copyright (c) 2008, Tim Davis (BinaryMethod.com, binary.god@gmail.com)
//  All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without modification,
//  are permitted provided that the following conditions are met:
//
//		Redistributions of source code must retain the above copyright notice, this
//	list of conditions and the following disclaimer.
//
//		Redistributions in binary form must reproduce the above copyright notice,
//	this list of conditions and the following disclaimer in the documentation and/or
//	other materials provided with the distribution.
//
//		Neither the name of the BinaryMethod.com nor the names of its contributors
//	may be used to endorse or promote products derived from this software without
//	specific prior written permission.
//
//	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS AS IS AND
//	ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//	WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
//	IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
//	INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
//	BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
//	OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
//	WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
//	ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
//	POSSIBILITY OF SUCH DAMAGE.

#import "BGTheme.h"


@implementation BGTheme

#pragma mark Scroller Theme

-(id)init {
    
    self = [super init];
    
    return self;
}

-(NSColor *)scrollerStroke {
    
    return [NSColor colorWithDeviceRed: 0.749f green: 0.761f blue: 0.788f alpha: 1.0f];
}

-(NSGradient *)scrollerKnobGradient {
    
    return [[NSGradient alloc] initWithStartingColor: [NSColor colorWithDeviceRed: 0.631f green: 0.639f blue: 0.655f alpha: 1.0f]
                                         endingColor: [NSColor colorWithDeviceRed: 0.439f green: 0.447f blue: 0.471f alpha: 1.0f]];
}

-(NSGradient *)scrollerTrackGradient {
    
    return [[NSGradient alloc] initWithStartingColor: [NSColor colorWithDeviceRed: 0.137f green: 0.137f blue: 0.137f alpha: .75f]
                                         endingColor: [NSColor colorWithDeviceRed: 0.278f green: 0.278f blue: 0.278f alpha: .75f]];
}

-(NSGradient *)scrollerArrowNormalGradient {
    
    return [[NSGradient alloc] initWithStartingColor: [NSColor colorWithDeviceRed: 0.251f green: 0.251f blue: 0.255f alpha: [self scrollerAlphaValue]]
                                         endingColor: [NSColor colorWithDeviceRed: 0.118f green: 0.118f blue: 0.118f alpha: [self scrollerAlphaValue]]];
}

-(NSGradient *)scrollerArrowPushedGradient {
    
    return [[NSGradient alloc] initWithStartingColor: [NSColor colorWithDeviceRed: 0.451f green: 0.451f blue: 0.455f alpha: [self scrollerAlphaValue]]
                                         endingColor: [NSColor colorWithDeviceRed: 0.318f green: 0.318f blue: 0.318f alpha: [self scrollerAlphaValue]]];
}

-(CGFloat)scrollerAlphaValue {
    
    return 0.5f;
}

#pragma mark -
#pragma mark Slider Theme

#define colorEnable (0.7f)
#define colorDisable (0.3f)

-(NSColor *)sliderTrackColor {
    
    return [NSColor colorWithDeviceRed: colorEnable green: colorEnable blue: colorEnable alpha: [self alphaValue]];
}

-(NSColor *)disabledSliderTrackColor {
    
    return [NSColor colorWithDeviceRed: colorDisable green: colorDisable blue: colorDisable alpha: [self disabledAlphaValue]];
}

-(NSGradient *)knobColor {
    
    return [[NSGradient alloc] initWithStartingColor: [NSColor colorWithDeviceRed: colorEnable green: colorEnable blue: colorEnable alpha: 1.0f]
                                         endingColor: [NSColor colorWithDeviceRed: colorEnable green: colorEnable blue: colorEnable alpha: 1.0f]];
}

-(NSGradient *)highlightKnobColor {
    
    return [[NSGradient alloc] initWithStartingColor: [NSColor colorWithDeviceRed: colorEnable green: colorEnable blue: colorEnable alpha: 1.0f]
                                         endingColor: [NSColor colorWithDeviceRed: colorEnable green: colorEnable blue: colorEnable alpha: 1.0f]];
}

-(NSGradient *)disabledKnobColor {
    
    return [[NSGradient alloc] initWithStartingColor: [NSColor colorWithDeviceRed: colorDisable green: colorDisable blue: colorDisable alpha: [self disabledAlphaValue]]
                                         endingColor: [NSColor colorWithDeviceRed: colorDisable green: colorDisable blue: colorDisable alpha: [self disabledAlphaValue]]];
}

#pragma mark -
#pragma mark Text Based Theme

-(BOOL)isOverrideFillColor {
    return YES;
}
-(NSColor *)textFillColor {
    
    return [NSColor colorWithDeviceRed: .224f green: .224f blue: .224f alpha: .95f];
}

-(NSColor *)selectionHighlightActiveColor {
    
    return [NSColor darkGrayColor];
}

-(NSColor *)selectionHighlightInActiveColor {
    
    return [NSColor darkGrayColor];
}

-(NSColor *)selectionTextActiveColor {
    
    return [NSColor whiteColor];
}

-(NSColor *)selectionTextInActiveColor {
    
    return [NSColor whiteColor];
}

-(NSColor *)placeholderTextColor {
    
    return [NSColor grayColor];
}

#pragma mark -
#pragma mark Progress Theme

-(NSGradient *)progressTrackGradient {
    
    return [[NSGradient alloc] initWithStartingColor: [NSColor colorWithCalibratedRed: 0.125f green: 0.125f blue: 0.125f alpha: 1.0f]
                                         endingColor: [NSColor colorWithCalibratedRed: 0.208f green: 0.208f blue: 0.208f alpha: 1.0f]];
}

#pragma mark -
#pragma mark Token Theme

-(NSColor *)tokenFillNormal {
    
    return [NSColor colorWithDeviceRed: 0.249f green: 0.261f blue: 0.288f alpha: 1.0f];
}

-(NSColor *)tokenFillHighlight {
    
    return [NSColor colorWithDeviceRed: 0.449f green: 0.461f blue: 0.488f alpha: 1.0f];
}

-(NSColor *)tokenBorder {
    
    return [NSColor whiteColor];
}

-(NSColor *)tokenTextColor {
    
    return [NSColor whiteColor];
}

#pragma mark -
#pragma mark Table Theme

-(NSColor *)cellHighlightColor {
    
    return [NSColor colorWithDeviceRed: 0.549f green: 0.561f blue: 0.588f alpha: 1];
}

-(NSArray *)cellAlternatingRowColors {
    
    return [NSArray arrayWithObjects:
            [NSColor colorWithCalibratedWhite: 0.16f alpha: 0.86f],
            [NSColor colorWithCalibratedWhite: 0.15f alpha: 0.8f],
            nil];
}

-(NSColor *)cellSelectedTextColor {
    
    return [NSColor blackColor];
}

-(NSColor *)cellEditingFillColor {
    
    return [NSColor colorWithDeviceRed: 0.141f green: 0.141f blue: 0.141f alpha: [self alphaValue]];
}

-(NSColor *)tableBackgroundColor {
    
    return [NSColor colorWithCalibratedRed: 0 green: 0 blue: 0 alpha: 0];
}

-(NSColor *)tableHeaderCellBorderColor {
    
    return [NSColor colorWithDeviceRed: 0.349f green: 0.361f blue: 0.388f alpha: 1.0f];
}

-(NSGradient *)tableHeaderCellNormalFill {
    
    return [[NSGradient alloc] initWithStartingColor: [NSColor colorWithDeviceRed: 0.251f green: 0.251f blue: 0.255f alpha: 1.0f]
                                         endingColor: [NSColor colorWithDeviceRed: 0.118f green: 0.118f blue: 0.118f alpha: 1.0f]];
}

-(NSGradient *)tableHeaderCellPushedFill {
    
    return [[NSGradient alloc] initWithStartingColor: [NSColor colorWithDeviceRed: 0.451f green: 0.451f blue: 0.455f alpha: 1.0f]
                                         endingColor: [NSColor colorWithDeviceRed: 0.318f green: 0.318f blue: 0.318f alpha: 1.0f]];
}

-(NSGradient *)tableHeaderCellSelectedFill {
    
    return [[NSGradient alloc] initWithStartingColor: [NSColor colorWithDeviceRed: 0.651f green: 0.651f blue: 0.655f alpha: 1.0f]
                                         endingColor: [NSColor colorWithDeviceRed: 0.518f green: 0.518f blue: 0.518f alpha: 1.0f]];
}

#pragma mark -
#pragma mark General Theme

-(CGFloat)gradientAngle {
    return 90.0f;
}
-(NSGradient *)normalGradient {
    
    return [[NSGradient alloc] initWithStartingColor: [NSColor colorWithDeviceRed: 0.118f green: 0.118f blue: 0.118f alpha: [self alphaValue]]
                                         endingColor: [NSColor colorWithDeviceRed: 0.118f green: 0.118f blue: 0.118f alpha: [self alphaValue]]];
}

-(NSGradient *)disabledNormalGradient {
    
    return [[NSGradient alloc] initWithStartingColor: [NSColor colorWithDeviceRed: 0.118f green: 0.118f blue: 0.118f alpha: [self disabledAlphaValue]]
                                         endingColor: [NSColor colorWithDeviceRed: 0.118f green: 0.118f blue: 0.118f alpha: [self disabledAlphaValue]]];
}

-(NSGradient *)pushedGradient {
    
    return [[NSGradient alloc] initWithStartingColor: [NSColor colorWithDeviceRed: 0.318f green: 0.318f blue: 0.318f alpha: [self alphaValue]]
                                         endingColor: [NSColor colorWithDeviceRed: 0.318f green: 0.318f blue: 0.318f alpha: [self alphaValue]]];
}

-(NSGradient *)highlightGradient {
    
    return [[NSGradient alloc] initWithStartingColor: [NSColor colorWithDeviceRed: 0.318f green: 0.318f blue: 0.318f alpha: [self alphaValue]]
                                         endingColor: [NSColor colorWithDeviceRed: 0.318f green: 0.318f blue: 0.318f alpha: [self alphaValue]]];
}

-(NSGradient *)normalComplexGradient {
    
    return [[NSGradient alloc] initWithColorsAndLocations: [NSColor colorWithDeviceRed: 0.324f green: 0.331f blue: 0.347f alpha: [self alphaValue]],
            (CGFloat)0, [NSColor colorWithDeviceRed: 0.245f green: 0.253f blue: 0.269f alpha: [self alphaValue]], (CGFloat).5,
            [NSColor colorWithDeviceRed: 0.206f green: 0.214f blue: 0.233f alpha: [self alphaValue]], (CGFloat).5,
            [NSColor colorWithDeviceRed: 0.139f green: 0.147f blue: 0.167f alpha: [self alphaValue]], (CGFloat)1.0f, nil];
}

-(NSGradient *)disabledNormalComplexGradient {
    
    return [[NSGradient alloc] initWithColorsAndLocations: [NSColor colorWithDeviceRed: 0.324f green: 0.331f blue: 0.347f alpha: [self disabledAlphaValue]],
            (CGFloat)0, [NSColor colorWithDeviceRed: 0.245f green: 0.253f blue: 0.269f alpha: [self disabledAlphaValue]], (CGFloat).5,
            [NSColor colorWithDeviceRed: 0.206f green: 0.214f blue: 0.233f alpha: [self disabledAlphaValue]], (CGFloat).5,
            [NSColor colorWithDeviceRed: 0.139f green: 0.147f blue: 0.167f alpha: [self disabledAlphaValue]], (CGFloat)1.0f, nil];
}

-(NSGradient *)pushedComplexGradient {
    
    return [[NSGradient alloc] initWithColorsAndLocations: [NSColor colorWithDeviceRed: 0.524f green: 0.531f blue: 0.547f alpha: [self alphaValue]],
            (CGFloat)0, [NSColor colorWithDeviceRed: 0.445f green: 0.453f blue: 0.469f alpha: [self alphaValue]], (CGFloat).5,
            [NSColor colorWithDeviceRed: 0.406f green: 0.414f blue: 0.433f alpha: [self alphaValue]], (CGFloat).5,
            [NSColor colorWithDeviceRed: 0.339f green: 0.347f blue: 0.367f alpha: [self alphaValue]], (CGFloat)1.0f, nil];
}

-(NSGradient *)highlightComplexGradient {
    
    return [[NSGradient alloc] initWithColorsAndLocations: [NSColor colorWithDeviceRed: 0.524f green: 0.531f blue: 0.547f alpha: [self alphaValue]],
            (CGFloat)0, [NSColor colorWithDeviceRed: 0.445f green: 0.453f blue: 0.469f alpha: [self alphaValue]], (CGFloat).5,
            [NSColor colorWithDeviceRed: 0.406f green: 0.414f blue: 0.433f alpha: [self alphaValue]], (CGFloat).5,
            [NSColor colorWithDeviceRed: 0.339f green: 0.347f blue: 0.367f alpha: [self alphaValue]], (CGFloat)1.0f, nil];
}

-(NSColor *)normalSolidFill {
    
    return [NSColor colorWithDeviceRed: 0.141f green: 0.141f blue: 0.141f alpha: [self alphaValue]];
}

-(NSColor *)disabledNormalSolidFill {
    
    return [NSColor colorWithDeviceRed: 0.141f green: 0.141f blue: 0.141f alpha: [self disabledAlphaValue]];
}

-(NSColor *)pushedSolidFill {
    
    return [NSColor colorWithDeviceRed: 0.941f green: 0.941f blue: 0.941f alpha: [self alphaValue]];
}

-(NSColor *)highlightSolidFill {
    
    return [NSColor colorWithDeviceRed: 0.941f green: 0.941f blue: 0.941f alpha: [self alphaValue]];
}

-(NSColor *)strokeColor {
    
    return [NSColor colorWithDeviceRed: 0.749f green: 0.761f blue: 0.788f alpha: 1.0f];
}

-(NSColor *)disabledStrokeColor {
    
    return [NSColor colorWithDeviceRed: 0.749f green: 0.761f blue: 0.788f alpha: [self disabledAlphaValue]];
}

-(NSColor *)darkStrokeColor {
    
    return [NSColor colorWithDeviceRed: 0.141f green: 0.141f blue: 0.141f alpha: 0.5f];
}

-(NSColor *)textColor {
    
    return [NSColor whiteColor];
}

-(NSColor *)highlightTextColor {
    
    return [NSColor whiteColor];
}
-(NSColor *)disabledTextColor {
    
    return [NSColor colorWithDeviceRed: 1 green: 1 blue: 1 alpha: [self disabledAlphaValue]];
}

-(NSShadow *)dropShadow {
    
    NSShadow *shadow = [[NSShadow alloc] init];
    [shadow setShadowColor: [NSColor blackColor]];
    [shadow setShadowBlurRadius: 2];
    [shadow setShadowOffset: NSMakeSize( 0, -1)];
    
    return shadow;
}

-(CGFloat)alphaValue {
    
    return 0.8f;
}

-(CGFloat)disabledAlphaValue {
    
    return 0.4f;
}

-(NSShadow *)focusRing {
    
    NSShadow *shadow = [[NSShadow alloc] init];
    [shadow setShadowColor: [NSColor whiteColor]];
    [shadow setShadowBlurRadius: 3];
    [shadow setShadowOffset: NSMakeSize( 0, 0)];
    
    return shadow;
}

#pragma mark -


@end
