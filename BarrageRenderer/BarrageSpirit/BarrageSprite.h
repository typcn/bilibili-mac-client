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

#import <Foundation/Foundation.h>
#import "BarrageSpriteUtility.h"
#import "BarrageSpriteProtocol.h"

extern NSString * const kBarrageRendererContextCanvasBounds;  // 画布大小
extern NSString * const kBarrageRendererContextRelatedSpirts; // 相关精灵
extern NSString * const kBarrageRendererContextTimestamp;     // 时间戳

/// 精灵基类
@interface BarrageSprite : NSObject<BarrageViewProtocol>
{
    CGPoint _origin;
    BOOL _valid;
    NSView * _view;
    
    NSColor * _backgroundColor;
    CGFloat _borderWidth;
    NSColor * _borderColor;
    CGFloat _cornerRadius;
    CGSize _mandatorySize;
}

/// 延时, 这个是相对于rendered的绝对时间/秒
/// 如果delay<0, 当然不会提前显示 ^ - ^
@property(nonatomic,assign)NSTimeInterval delay;

/// 创建的绝对时间,初始化的时候创建; 目前好像没啥用处
@property(nonatomic,strong,readonly)NSDate * birth;

/// 时间戳,表示这个弹幕处于的时间位置;相对于时间引擎启动的时候;精灵被激活的时候生成
@property(nonatomic,assign,readonly)CFTimeInterval timestamp;

// 最底层是0, 往上依次叠加; 默认值是0
@property(nonatomic,assign)NSUInteger z_index;

/// 起始位置,为了获取这个值,子类需要重写 originInBounds:withSprites: 方法
@property(nonatomic,assign,readonly)CGPoint origin;

/// 为了获取此值,子类可能需要在 updateWithTime: 中修改 _position成员变量
@property(nonatomic,assign,readonly)CGPoint position;

/// calculate inside, return for others;如果需要不同大小的size
@property(nonatomic,assign,readonly)CGSize size;

/// 是否有效,默认YES; 当过了动画时间之后,就会被标记成NO; 永世不得翻身;子类可能需要在 updateWithTime: 中修改 _valid成员变量
@property(nonatomic,assign,readonly,getter=isValid)BOOL valid;

/// 输出的view,这样就不必自己再绘制图形了,并且可以使用硬件加速
@property(nonatomic,strong,readonly)NSView * view;

#pragma mark - called

/// 结合相关上下文激活精灵; 如要覆盖, 请要先调用super方法
- (void)activeWithContext:(NSDictionary *)context;

/// 用相对时间更新状态; 最好不要覆盖此方法; 如要覆盖, 请要先调用super方法
- (void)updateWithTime:(NSTimeInterval)time;

#pragma mark - override -

#pragma mark update
/// _position, 此时刻的位置
- (CGRect)rectWithTime:(NSTimeInterval)time;

/// _valid, 此时刻是否还有效
- (BOOL)validWithTime:(NSTimeInterval)time;

#pragma mark launch
/// 返回弹幕的初始位置
- (CGPoint)originInBounds:(CGRect)rect withSprites:(NSArray *)sprites;

/// 绑定的view
- (NSView *)bindingView;

@end
