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

#import "BarrageSpriteUtility.h"

@implementation BarrageSpriteUtility

/// 一维线段分割函数
/// 如果返回YES,通过[from,to]输出最大剪枝; 如果返回NO, 不存在有效剪枝
/// 左右分支相等,优先使用左边的;
/// 除了from,to, 其余的参数都是不可变的
/// threshold>=0
///TODO: 此算法尚未验证
BOOL searchMaxSpace(CGFloat * p_from,CGFloat * p_to,CGFloat begins[],CGFloat ends[], NSInteger n, CGFloat threshold)
{
    if (n <= 0) {
        return YES;
    }
    if (threshold < 0) {
        *p_to = *p_from -1; // 做死了
        return NO;
    }
    CGFloat begin = begins[0]; // 第一次分割
    CGFloat end = ends[0];
    CGFloat from = *p_from;
    CGFloat to = *p_to;
    if (divideLine(&from, &to, &begin, &end)) {
        CGFloat len1 = to - from;
        CGFloat len2 = end - begin;
        if (n>1) {
            if (len1 >= threshold) { // 左侧剪枝
                searchMaxSpace(&from, &to, begins+1, ends+1, n-1, threshold);
            }
            if (len2 >= threshold) { // 右侧剪枝
                searchMaxSpace(&begin, &end, begins+1, ends+1, n-1, threshold);
            }
            
        }
        if (len1 >= len2 && len1 >= threshold) {
            *p_from = from;
            *p_to = to;
            return YES;
        }
        else if(len2 > len1 && len2 >= threshold)
        {
            *p_from = begin;
            *p_to = end;
            return YES;
        }
        *p_to = *p_from -1; // 做死了
        return NO;
    }
    *p_to = *p_from -1; // 做死了
    return NO;
}

///TODO: 很奇怪objective-c为什么不能传引用呢?
/// [1,5]/[2,4] => [1,2]/[4,5];
/// 如果 *to <  *from || *end < *begin, return NO;
BOOL divideLine(CGFloat * from, CGFloat * to, CGFloat *begin, CGFloat *end)
{
    if (*to >= *from && *end >= *begin) {
        CGFloat tmp = *to;
        *to = (*begin <= tmp)?*begin:*from-1;
        *begin = *end;
        *end = (*end >= *from)?tmp:*begin-1;
        return YES;
    }
    return NO;
}

/// 生成在[min,max]的随机数
CGFloat random_between(CGFloat min, CGFloat max)
{
    if (min >= max) {
        return min;
    }
    CGFloat scale = max - min;
    return min + scale * random()/RAND_MAX;
}


@end
