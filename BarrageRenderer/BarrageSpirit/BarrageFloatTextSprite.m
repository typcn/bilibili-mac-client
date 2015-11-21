// Part of BarrageRenderer. Created by UnAsh.
// Blog: http://blog.exbye.com
// Github: https://github.com/unash/BarrageRenderer

// This code is distributed under the terms and conditions of the MIT license.

// Copyright (c) 2015年 UnAsh.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "BarrageFloatTextSprite.h"
#import "NSLabel.h"

@implementation BarrageFloatTextSprite

@synthesize fontSize = _fontSize;
@synthesize textColor = _textColor;
@synthesize text = _text;
@synthesize fontFamily = _fontFamily;
@synthesize shadowColor = _shadowColor;
@synthesize shadowOffset = _shadowOffset;
@synthesize attributedText = _attributedText;

- (instancetype)init
{
    if (self = [super init]) {
        _textColor = [NSColor blackColor];
        _fontSize = 16.0f;
        _shadowColor = nil;
        _shadowOffset = CGSizeMake(0, -1);
    }
    return self;
}

#pragma mark - launch

- (NSView *)bindingView
{
    NSLabel * label = [[NSLabel alloc]init];
    label.text = self.text;
    label.textColor = self.textColor;
    // Not supported yet
    //label.shadowColor = _shadowColor;
    //label.shadowOffset = _shadowOffset;
    label.font = self.fontFamily?[NSFont fontWithName:self.fontFamily size:self.fontSize]:[NSFont systemFontOfSize:self.fontSize];
    if (self.attributedText) {
        label.attributedText = self.attributedText;
    }
    return label;
}

@end
