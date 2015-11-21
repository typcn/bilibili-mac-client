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
#import "NHDisplayLink.h"

/// 时间引擎
@interface BarrageClock : NSObject <NHDisplayLinkDelegate>

/// 通过回调block初始化时钟,block中返回逻辑时间,其值会受到speed的影响.
+ (instancetype)clockWithHandler:(void (^)(NSTimeInterval time))block;

/// 时间流速,默认值为1.0f; 设置必须大于0,否则无效.
@property(nonatomic,assign)CGFloat speed;

/// 启动时间引擎,根据刷新频率返回逻辑时间.
- (void)start;

/// 关闭时间引擎; 一些都已结束,或者重新开始,或者归于沉寂.
- (void)stop;

/// 暂停,相等于把speed置为0; 不过通过start可以恢复.
- (void)pause;

@end
