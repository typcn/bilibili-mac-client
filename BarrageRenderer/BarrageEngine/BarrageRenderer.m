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

#import "BarrageRenderer.h"
#import "BarrageCanvas.h"
#import "BarrageDispatcher.h"
#import "BarrageSprite.h"
#import "BarrageSpriteFactory.h"
#import "BarrageClock.h"
#import "BarrageDescriptor.h"
#import "NSView+UIView.h"
#import "NSValue+iOS.h"

NSString * const kBarrageRendererContextCanvasBounds = @"kBarrageRendererContextCanvasBounds";   // 画布大小
NSString * const kBarrageRendererContextRelatedSpirts = @"kBarrageRendererContextRelatedSpirts"; // 相关精灵
NSString * const kBarrageRendererContextTimestamp = @"kBarrageRendererContextTimestamp";         // 时间戳

@interface BarrageRenderer()<BarrageDispatcherDelegate>
{
    BarrageDispatcher * _dispatcher; //调度器
    BarrageCanvas * _canvas; // 画布
    BarrageClock * _clock;
    NSMutableDictionary * _spriteClassMap;
    __block NSTimeInterval _time;
    NSMutableDictionary * _context; // 渲染器上下文
    
    NSMutableArray * _preloadedDescriptors; //预加载的弹幕
    NSMutableArray * _records;//记录数组
    NSDate * _startTime; //如果是nil,表示弹幕渲染不在运行中; 否则,表示开始的时间
    NSTimeInterval _pausedDuration; // 暂停持续时间
    NSDate * _pausedTime; // 上次暂停时间; 如果为nil, 说明当前没有暂停
}
@property(nonatomic,assign)NSTimeInterval pausedDuration; // 暂停时间
@end

@implementation BarrageRenderer
@synthesize pausedDuration = _pausedDuration;
#pragma mark - init
- (instancetype)init
{
    if (self = [super init]) {
        _canvas = [[BarrageCanvas alloc]init];
        _spriteClassMap = [[NSMutableDictionary alloc]init];
        _zIndex = NO;
        _context = [[NSMutableDictionary alloc]init];
        _recording = NO;
        _startTime = nil; // 尚未开始
        _pausedTime = nil;
        _redisplay = NO;
        self.pausedDuration = 0;
        [self initClock];
    }
    return self;
}

/// 初始化时钟
- (void)initClock
{
    __weak id weakSelf = self;
    _clock = [BarrageClock clockWithHandler:^(NSTimeInterval time){
        BarrageRenderer * strongSelf = weakSelf;
        _time = time;
        [strongSelf update];
    }];
}

#pragma mark - control
- (void)receive:(BarrageDescriptor *)descriptor
{
    if (!_startTime) { // 如果没有启动,则抛弃接收弹幕
        return;
    }
    BarrageDescriptor * descriptorCopy = [descriptor copy];
    [self convertDelayTime:descriptorCopy];
    BarrageSprite * sprite = [BarrageSpriteFactory createSpriteWithDescriptor:descriptorCopy];
    [_dispatcher addSprite:sprite];
    if (_recording) {
        [self recordDescriptor:descriptorCopy];
    }
}

- (void)start
{
    if (!_startTime) { // 尚未启动,则初始化时间系统
        _startTime = [NSDate date];
        _records = [[NSMutableArray alloc]init];
        _dispatcher = [[BarrageDispatcher alloc]init];
        _dispatcher.cacheDeadSprites = self.redisplay;
        _dispatcher.delegate = self;
    }
    else if(_pausedTime)
    {
        _pausedDuration += [[NSDate date]timeIntervalSinceDate:_pausedTime];
    }
    _pausedTime = nil;
    [_clock start];
    if (_preloadedDescriptors.count) {
        for (BarrageDescriptor * descriptor in _preloadedDescriptors) {
            [self receive:descriptor];
        }
        [_preloadedDescriptors removeAllObjects];
    }
}

- (void)pause
{
    if (!_startTime) { // 没有运行, 则暂停无效
        return;
    }
    if (!_pausedTime) { // 当前没有暂停
        [_clock pause];
        _pausedTime = [NSDate date];
    }
    else
    {
        _pausedDuration += [[NSDate date]timeIntervalSinceDate:_pausedTime];
        _pausedTime = [NSDate date];
    }
}

- (void)stop
{
    _startTime = nil;
    [_clock stop];
    [_dispatcher deactiveAllSprites];
}

- (void)setSpeed:(CGFloat)speed
{
    if (speed > 0) {
        _clock.speed = speed;
    }
}

- (CGFloat)speed
{
    return _clock.speed;
}

- (void)setRedisplay:(BOOL)redisplay
{
    _redisplay = redisplay;
    if (_dispatcher) {
        _dispatcher.cacheDeadSprites = _redisplay;
    }
}

- (NSTimeInterval)pausedDuration
{
    return _pausedDuration + (_pausedTime?[[NSDate date]timeIntervalSinceDate:_pausedTime]:0); // 当前处于暂停当中
}

/// 获取当前时间
- (NSTimeInterval)currentTime
{
    NSTimeInterval currentTime = 0.0f;
    if (self.delegate && [self.delegate respondsToSelector:@selector(timeForBarrageRenderer:)]) {
        currentTime = [self.delegate timeForBarrageRenderer:self];
    }
    else
    {
        currentTime = [[NSDate date]timeIntervalSinceDate:_startTime]-self.pausedDuration;
    }
    return currentTime;
}

/// 转换descriptor的delay时间(相对于start), 如果delay<0, 则将delay置为0
- (void)convertDelayTime:(BarrageDescriptor *)descriptor
{
    NSTimeInterval delay = [[descriptor.params objectForKey:@"delay"]doubleValue];
    delay += [self currentTime];
    if (delay < 0) {
        delay = 0;
    }
    [descriptor.params setObject:@(delay) forKey:@"delay"];
}

- (NSInteger)spritesNumberWithName:(NSString *)spriteName
{
    NSInteger number = 0;
    if (spriteName) {
        Class class = NSClassFromString(spriteName);
        if (class) {
            for (BarrageSprite * sprite in _dispatcher.activeSprites) {
                number += [sprite class] == class;
            }
        }
    }
    else
    {
        number = _dispatcher.activeSprites.count;
    }
    return number;
}

#pragma mark - record
/// 此方法会修改desriptor的值
- (void)recordDescriptor:(BarrageDescriptor *)descriptor
{
    __block BOOL exists = NO;
    [_records enumerateObjectsUsingBlock:^(id obj, NSUInteger index, BOOL * stop){
        if([((BarrageDescriptor *)obj).identifier isEqualToString:descriptor.identifier]){
            exists = YES;
            *stop = YES;
        }
    }];
    if(!exists){
        [_records addObject:descriptor];
    }
}

- (NSArray *)records
{
    return [_records copy];
}

- (void)load:(NSArray *)descriptors
{
    if (_startTime) {
        for (BarrageDescriptor * descriptor in descriptors) {
            [self receive:descriptor];
        }
    }
    else
    {
        if (!_preloadedDescriptors) {
            _preloadedDescriptors = [[NSMutableArray alloc]init];
        }
        for (BarrageDescriptor * descriptor in descriptors) {
            [_preloadedDescriptors addObject:[descriptor copy]];
        }
    }

}

#pragma mark - update
/// 每个刷新周期执行一次
- (void)update
{
    [_dispatcher dispatchSprites]; // 分发精灵
    for (BarrageSprite * sprite in _dispatcher.activeSprites) {
        [sprite updateWithTime:_time];
    }
}

#pragma mark - BarrageDispatcherDelegate

- (BOOL)shouldActiveSprite:(BarrageSprite *)sprite
{
    return !_pausedTime;
}

- (void)willActiveSprite:(BarrageSprite *)sprite
{
    NSValue * value = [NSValue valueWithCGRect:_canvas.bounds];
    [_context setObject:value forKey:kBarrageRendererContextCanvasBounds];
    
    NSArray * itemMap = [_spriteClassMap objectForKey:NSStringFromClass([sprite class])];
    if (itemMap) {
        [_context setObject:[itemMap copy] forKey:kBarrageRendererContextRelatedSpirts];
    }
    
    [_context setObject:@(_time) forKey:kBarrageRendererContextTimestamp];
    
    NSInteger index = [self viewIndexOfSprite:sprite];
    
    [sprite activeWithContext:_context];
    [self indexAddSprite:sprite];
    [_canvas insertSubview:sprite.view atIndex:index];
}

- (NSUInteger)viewIndexOfSprite:(BarrageSprite *)sprite
{
    NSInteger index = _dispatcher.activeSprites.count;
    
    /// 添加根据z-index 增序排列
    if (self.zIndex) {
        NSMutableArray * preSprites = [[NSMutableArray alloc]initWithArray:_dispatcher.activeSprites];
        [preSprites addObject:sprite];
        NSArray * sortedSprites = [preSprites sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            return [@(((BarrageSprite *)obj1).z_index) compare:@(((BarrageSprite *)obj2).z_index)];
        }];
        index = [sortedSprites indexOfObject:sprite];
    }
    return index;
}

- (void)willDeactiveSprite:(BarrageSprite *)sprite
{
    [self indexRemoveSprite:sprite];
    [sprite.view removeFromSuperview];
}

- (NSTimeInterval)timeForBarrageDispatcher:(BarrageDispatcher *)dispatcher
{
    if ([dispatcher isEqual:_dispatcher]) {
        return [self currentTime];
    }
    return 0.0f; // 错误情况
}

#pragma mark - indexing className-sprites
/// 更新活跃精灵类型索引
- (void)indexAddSprite:(BarrageSprite *)sprite
{
    NSString * className = NSStringFromClass([sprite class]);
    NSMutableArray * itemMap = [_spriteClassMap objectForKey:className];
    if (!itemMap) {
        itemMap = [[NSMutableArray alloc]init];
        [_spriteClassMap setObject:itemMap forKey:className];
    }
    [itemMap addObject:sprite];
}

/// 更新活跃精灵类型索引
- (void)indexRemoveSprite:(BarrageSprite *)sprite
{
    NSString * className = NSStringFromClass([sprite class]);
    NSMutableArray * itemMap = [_spriteClassMap objectForKey:className];
    if (!itemMap) {
        itemMap = [[NSMutableArray alloc]init];
        [_spriteClassMap setObject:itemMap forKey:className];
    }
    [itemMap removeObject:sprite];
}

#pragma mark - attributes

- (NSView *)view
{
    return _canvas;
}

@end
