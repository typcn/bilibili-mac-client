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

#import "BarrageDispatcher.h"
#import "BarrageSprite.h"

@interface BarrageDispatcher()
{
    NSMutableArray * _activeSprites;
    NSMutableArray * _waitingSprites;
    NSMutableArray * _deadSprites;
    NSTimeInterval _previousTime;
}
@end

@implementation BarrageDispatcher

- (instancetype)init
{
    if (self = [super init]) {
        _activeSprites = [[NSMutableArray alloc]init];
        _waitingSprites = [[NSMutableArray alloc]init];
        _deadSprites = [[NSMutableArray alloc]init];
        _cacheDeadSprites = NO;
        _previousTime = 0.0f;
    }
    return self;
}

- (void)setDelegate:(id<BarrageDispatcherDelegate>)delegate
{
    _delegate = delegate;
    _previousTime = [self currentTime];
}

- (NSTimeInterval)currentTime
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(timeForBarrageDispatcher:)]) {
        return [self.delegate timeForBarrageDispatcher:self];
    }
    return 0.0f;
}

- (void)addSprite:(BarrageSprite *)sprite
{
    if ([sprite isKindOfClass:[BarrageSprite class]]) {
        [_waitingSprites addObject:sprite];
    }
}

/// 停止当前被激活的精灵
- (void)deactiveAllSprites
{
    for (NSInteger i = 0; i < _activeSprites.count; i ++) { // 活跃精灵队列
        BarrageSprite * sprite = [_activeSprites objectAtIndex:i];
        if (_cacheDeadSprites) {
            [_deadSprites addObject:sprite];
        }
        [self deactiveSprite:sprite];
        [_activeSprites removeObjectAtIndex:i--];
    }
}

/// 派发精灵
- (void)dispatchSprites
{
    for (NSInteger i = 0; i < _activeSprites.count; i ++) {
        BarrageSprite * sprite = [_activeSprites objectAtIndex:i];
        if (!sprite.isValid) {
            if (_cacheDeadSprites) {
                [_deadSprites addObject:sprite];
            }
            [self deactiveSprite:sprite];
            [_activeSprites removeObjectAtIndex:i--];
        }
    }
    static NSTimeInterval const MAX_EXPIRED_SPRITE_RESERVED_TIME = 0.5f; // 弹幕最大保留时间
    NSTimeInterval currentTime = [self currentTime];
    NSTimeInterval timeWindow = currentTime - _previousTime; // 有可能为正,也有可能为负(如果倒退的话)
//    NSLog(@"内部时间:%f -- 变化时间:%f",currentTime,timeWindow);
    //如果是正, 可能是正常时钟,也可能是快进
    if (timeWindow >= 0) {
        for (NSInteger i = 0; i < _waitingSprites.count; i++) {
            BarrageSprite * sprite = [_waitingSprites objectAtIndex:i];
            NSTimeInterval overtime = currentTime - sprite.delay;
            if (overtime >= 0) {
                if (overtime < timeWindow && overtime <= MAX_EXPIRED_SPRITE_RESERVED_TIME) {
                    if ([self shouldActiveSprite:sprite]) {
                        [self activeSprite:sprite];
                        [_activeSprites addObject:sprite];
                    }
                }
                else
                {
                    if (_cacheDeadSprites) {
                        [_deadSprites addObject:sprite];
                    }
                }
                [_waitingSprites removeObjectAtIndex:i--];
            }
        }
    }
    else // 倒退,需要起死回生
    {
        for (NSInteger i = 0; i < _deadSprites.count; i++) { // 活跃精灵队列
            BarrageSprite * sprite = [_deadSprites objectAtIndex:i];
            if (sprite.delay > currentTime) {
                [_waitingSprites addObject:sprite];
                [_deadSprites removeObjectAtIndex:i--];
            }
            else if (sprite.delay == currentTime)
            {
                if ([self shouldActiveSprite:sprite]) {
                    [self activeSprite:sprite];
                    [_activeSprites addObject:sprite];
                    [_deadSprites removeObjectAtIndex:i--];
                }
            }
        }
    }
    
    _previousTime = currentTime;
}

/// 是否可以激活精灵
- (BOOL)shouldActiveSprite:(BarrageSprite *)sprite
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(shouldActiveSprite:)]) {
        return [self.delegate shouldActiveSprite:sprite];
    }
    return YES;
}

/// 激活精灵
- (void)activeSprite:(BarrageSprite *)sprite
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(willActiveSprite:)]) {
        [self.delegate willActiveSprite:sprite];
    }
}

/// 精灵失活
- (void)deactiveSprite:(BarrageSprite *)sprite
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(willDeactiveSprite:)]) {
        [self.delegate willDeactiveSprite:sprite];
    }
}

@end
