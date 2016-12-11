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

#import "BarrageSpriteFactory.h"
#import "BarrageDescriptor.h"
#import "BarrageSprite.h"

@implementation BarrageSpriteFactory

+ (BarrageSprite *)createSpriteWithDescriptor:(BarrageDescriptor *)descriptor
{
    BarrageSprite * sprite = nil;
    
    if (descriptor.spriteName.length != 0) {
        Class class = NSClassFromString(descriptor.spriteName);
        if (class) {
            sprite = [[class alloc]init];
        }
    }
    if (sprite) {
        for (NSString * key in [descriptor.params allKeys]) {
            id value = descriptor.params[key];
            [sprite setValue:value forKey:key];
        }
    }
    return sprite;
}

@end
