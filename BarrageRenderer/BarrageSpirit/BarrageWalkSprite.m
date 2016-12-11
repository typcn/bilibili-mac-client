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

#import "BarrageWalkSprite.h"

@interface BarrageWalkSprite()
{
    BarrageWalkDirection _direction;
}
@end

@implementation BarrageWalkSprite
@synthesize direction = _direction;
@synthesize destination = _destination;

- (instancetype)init
{
    if (self = [super init]) {
        _direction = BarrageWalkDirectionR2L;
        _speed = 30.0f; // 默认值
    }
    return self;
}

#pragma mark - update

- (BOOL)validWithTime:(NSTimeInterval)time
{
    return [self estimateActiveTime] > 0;
}

- (CGRect)rectWithTime:(NSTimeInterval)time
{
    CGFloat X = self.destination.x - self.origin.x;
    CGFloat Y = self.destination.y - self.origin.y;
    CGFloat L = sqrt(X*X + Y*Y);
    NSTimeInterval duration = time - self.timestamp;
    CGPoint position = CGPointMake(self.origin.x + duration * self.speed * X/L, self.origin.y + duration * self.speed * Y/L);
    return CGRectMake(position.x, position.y, self.size.width, self.size.height);
}

/// 估算精灵的剩余存活时间
- (NSTimeInterval)estimateActiveTime
{
    CGFloat activeDistance = 0;
    switch (_direction) {
        case BarrageWalkDirectionR2L:
            activeDistance = self.position.x - _destination.x;
            break;
        case BarrageWalkDirectionL2R:
            activeDistance = _destination.x - self.position.x;
            break;
        case BarrageWalkDirectionT2B:
            activeDistance = _destination.y - self.position.y;
            break;
        case BarrageWalkDirectionB2T:
            activeDistance = self.position.y - _destination.y;
        default:
            break;
    }
    return activeDistance/self.speed;
}

#pragma mark - launch

- (CGPoint)originInBounds:(CGRect)rect withSprites:(NSArray *)sprites
{
    // 获取同方向精灵
    NSMutableArray * synclasticSprites = [[NSMutableArray alloc]initWithCapacity:sprites.count];
    for (BarrageWalkSprite * sprite in sprites) {
        if (sprite.direction == _direction) {
            [synclasticSprites addObject:sprite];
        }
    }
    
    static BOOL const AVAERAGE_STRATEGY = YES; // YES:条纹平均精灵策略(体验会好一些); NO:最快时间策略
    static NSUInteger const STRIP_NUM = 160; // 总共的网格条数
    NSTimeInterval stripMaxActiveTimes[STRIP_NUM]={0}; // 每一条网格 已有精灵中最后退出屏幕的时间
    NSUInteger stripSpriteNumbers[STRIP_NUM]={0}; // 每一条网格 包含精灵的数目
    CGFloat stripHeight = rect.size.height/STRIP_NUM; // 水平条高度
    CGFloat stripWidth = rect.size.width/STRIP_NUM; // 竖直条宽度
    BOOL oritation = _direction == BarrageWalkDirectionL2R || _direction == BarrageWalkDirectionR2L; // 方向, YES代表水平弹幕
    /// 计算数据结构,便于应用算法
    NSUInteger overlandStripNum = 1; // 横跨网格条数目
    if (oritation) { // 水平
        overlandStripNum = (NSUInteger)ceil((double)self.size.height/stripHeight);
    }
    else // 竖直
    {
        overlandStripNum = (NSUInteger)ceil((double)self.size.width/stripWidth);
    }
    /// 当前精灵需要的时间,左边碰到边界, 不是真实的活跃时间
    NSTimeInterval maxActiveTime = oritation?rect.size.width/self.speed:rect.size.height/self.speed;
    NSUInteger availableFrom = 0;
    NSUInteger leastActiveTimeStrip = 0; // 最小时间的行
    NSUInteger leastActiveSpriteStrip = 0; // 最小网格的行
    
    for (NSUInteger i = 0; i < STRIP_NUM; i++) {
        //寻找当前行里包含的sprites
        CGFloat stripFrom = i * (oritation?stripHeight:stripWidth);
        CGFloat stripTo = stripFrom + (oritation?stripHeight:stripWidth);
        CGFloat lastDistanceAllOut = YES;
        for (BarrageWalkSprite * sprite in synclasticSprites) {
            CGFloat Sy = sprite.origin.y;
            if(oritation){
                // Cocoa 的上下坐标是反的
                Sy = rect.size.height - sprite.size.height - Sy;
            }
            CGFloat spriteFrom = oritation?Sy:sprite.origin.x;
            CGFloat spriteTo = spriteFrom + (oritation?sprite.size.height:sprite.size.width);
            if ((spriteTo-spriteFrom)+(stripTo-stripFrom)>MAX(stripTo-spriteFrom, spriteTo-stripFrom)) { // 在条条里
                stripSpriteNumbers[i]++;
                NSTimeInterval activeTime = [sprite estimateActiveTime];
                if (activeTime > stripMaxActiveTimes[i]){ // 获取最慢的那个
                    stripMaxActiveTimes[i] = activeTime;
                    CGFloat distance = oritation?fabs(sprite.position.x-sprite.origin.x):fabs(sprite.position.y-sprite.origin.y);
                    lastDistanceAllOut = distance > (oritation?sprite.size.width:sprite.size.height);
                }
            }
        }
        if (stripMaxActiveTimes[i]>maxActiveTime || !lastDistanceAllOut) {
            availableFrom = i+1;
        }
        else if (i - availableFrom >= overlandStripNum - 1){
            break; // eureka!
        }
        if (i <= STRIP_NUM - overlandStripNum) {
            if (stripMaxActiveTimes[i] < stripMaxActiveTimes[leastActiveTimeStrip]) {
                leastActiveTimeStrip = i;
            }
            if (stripSpriteNumbers[i] < stripSpriteNumbers[leastActiveSpriteStrip]) {
                leastActiveSpriteStrip = i;
            }
        }
    }
    if (availableFrom > STRIP_NUM - overlandStripNum) { // 那就是没有找到喽
        availableFrom = AVAERAGE_STRATEGY?leastActiveSpriteStrip:leastActiveTimeStrip; // 使用最小个数 or 使用最短时间
    }
    
    CGPoint origin = CGPointZero;
    if (oritation) { // 水平
        _destination.y = origin.y = rect.size.height - (stripHeight * availableFrom + rect.origin.y) - self.size.height; // Cocoa 的上下坐标是反的
        origin.x = (self.direction == BarrageWalkDirectionL2R)?rect.origin.x - self.size.width:rect.origin.x + rect.size.width;
        _destination.x = (self.direction == BarrageWalkDirectionL2R)?rect.origin.x + rect.size.width:rect.origin.x - self.size.width;
    }
    else
    {
        _destination.x = origin.x = stripWidth * availableFrom + rect.origin.x;
        origin.y = (self.direction == BarrageWalkDirectionT2B)?rect.origin.y - self.size.height:rect.origin.y + rect.size.height;
        _destination.y = (self.direction == BarrageWalkDirectionT2B)?rect.origin.y + rect.size.height:rect.origin.y - self.size.height;
    }
    return origin;
}

@end
