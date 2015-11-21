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

#import "BarrageFloatSprite.h"

@interface BarrageFloatSprite()
{
    NSTimeInterval _leftActiveTime;
}
@end

@implementation BarrageFloatSprite

- (instancetype)init
{
    if (self = [super init]) {
        _direction = BarrageFloatDirectionT2B;
        self.duration = 1.0f;
    }
    return self;
}

- (void)setDuration:(NSTimeInterval)duration
{
    _duration = duration;
    _leftActiveTime = _duration;
}

- (void)updateWithTime:(NSTimeInterval)time
{
    [super updateWithTime:time];
    _leftActiveTime = self.duration - (time - self.timestamp);
}

- (NSTimeInterval)estimateActiveTime
{
    return _leftActiveTime;
}

- (BOOL)validWithTime:(NSTimeInterval)time
{
    return [self estimateActiveTime] > 0;
}

- (CGPoint)originInBounds:(CGRect)rect withSprites:(NSArray *)sprites
{
    // 获取同方向精灵
    NSMutableArray * synclasticSprites = [[NSMutableArray alloc]initWithCapacity:sprites.count];
    for (BarrageFloatSprite * sprite in sprites) {
        if (sprite.direction == _direction) {
            [synclasticSprites addObject:sprite];
        }
    }
    
    BOOL down = self.direction == BarrageFloatDirectionT2B; // 是否是朝下方向
    
    static BOOL const AVAERAGE_STRATEGY = NO; // YES:条纹平均精灵策略; NO:最快时间策略(体验会好一些)
    static NSUInteger const STRIP_NUM = 80; // 总共的网格条数
    NSTimeInterval stripMaxActiveTimes[STRIP_NUM]={0}; // 每一条网格 已有精灵中最后退出屏幕的时间
    NSUInteger stripSpriteNumbers[STRIP_NUM]={0}; // 每一条网格 包含精灵的数目
    CGFloat stripHeight = rect.size.height/STRIP_NUM; // 水平条高度
    
    NSUInteger overlandStripNum = (NSUInteger)ceil((double)self.size.height/stripHeight); // 横跨网格条数目
    NSUInteger availableFrom = 0;
    NSUInteger leastActiveTimeStrip = 0; // 最小时间的行
    NSUInteger leastActiveSpriteStrip = 0; // 最小网格精灵的行
    
    for (NSUInteger i = 0; i < STRIP_NUM; i++) {
        //寻找当前行里包含的sprites
        CGFloat stripFrom = down?(i * stripHeight+rect.origin.y):(rect.origin.y+rect.size.height - i * stripHeight);
        CGFloat stripTo = down?(stripFrom + stripHeight):(stripFrom-stripHeight);
        
        for (BarrageFloatSprite * sprite in synclasticSprites) {
            CGFloat spriteFrom = down?sprite.origin.y:(sprite.origin.y+sprite.size.height);
            CGFloat spriteTo = down?(sprite.origin.y + sprite.size.height):sprite.origin.y;
            if (fabs(spriteTo-spriteFrom)+fabs(stripTo-stripFrom)>MAX(fabs(stripTo-spriteFrom), fabs(spriteTo-stripFrom))) { // 在条条里
                stripSpriteNumbers[i]++;
                NSTimeInterval activeTime = [sprite estimateActiveTime];
                if (activeTime > stripMaxActiveTimes[i]){
                    stripMaxActiveTimes[i] = activeTime;
                }
            }
        }
        if (stripMaxActiveTimes[i] > 0) {
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
    origin.x = (rect.origin.x+rect.size.width-self.size.width)/2;
    origin.y = down?(stripHeight * availableFrom+rect.origin.y):(rect.origin.y+rect.size.height-stripHeight * availableFrom - self.size.height);
    return origin;
}

@end
