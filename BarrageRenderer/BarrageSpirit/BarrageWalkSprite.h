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

#import "BarrageSprite.h"

typedef NS_ENUM(NSUInteger, BarrageWalkDirection) {
    BarrageWalkDirectionR2L = 1,  // 右向左
    BarrageWalkDirectionL2R = 2,  // 左向右
    BarrageWalkDirectionT2B = 3,  // 上往下
    BarrageWalkDirectionB2T = 4   // 下往上
};

/// 移动文字精灵
@interface BarrageWalkSprite : BarrageSprite
{
    CGPoint _destination;
}

/// 速度,point/second
@property(nonatomic,assign)CGFloat speed;

/// 运动方向
@property(nonatomic,assign)BarrageWalkDirection direction;

/// 需要在originInBounds:withSprites: 方法中修改 _destination的值以表示运动的终点
@property(nonatomic,assign,readonly)CGPoint destination;

@end
