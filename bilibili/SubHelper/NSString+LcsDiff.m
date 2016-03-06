//
//  NSString+LcsDiff.m
//  bilibili
//
//  Created by TYPCN on 2016/3/6.
//  Copyright © 2016 TYPCN. All rights reserved.
//

#import "NSString+LcsDiff.h"

@implementation NSString (LcsDiff)

// From http://jakubturek.pl/blog/2015/06/27/using-swifts-string-type-with-care/
- (NSString*)longestCommonSubsequence:(NSString*)string {
    NSUInteger x = self.length;
    NSUInteger y = string.length;
    
    NSMutableArray<NSMutableArray<NSNumber*>*>* lengths =
    [NSMutableArray arrayWithCapacity:x + 1];
    
    for (unsigned int i = 0; i < (x + 1); ++i) {
        NSMutableArray<NSNumber*>* columns = [NSMutableArray arrayWithCapacity:y + 1];
        
        for (unsigned int j = 0; j < (y + 1); ++j) {
            [columns addObject:@0];
        }
        
        [lengths addObject:columns];
    }
    
    NSMutableString* lcs = [NSMutableString string];
    
    for (unsigned int i = 0; i < x; ++i) {
        for (unsigned int j = 0; j < y; ++j) {
            if ([self characterAtIndex:i] == [string characterAtIndex:j]) {
                lengths[i + 1][j + 1] = @(lengths[i][j].intValue + 1);
            }
            else {
                lengths[i + 1][j + 1] = MAX(lengths[i + 1][j], lengths[i][j + 1]);
            }
        }
    }
    
    while (x != 0 && y != 0) {
        if (lengths[x][y] == lengths[x - 1][y]) {
            --x;
        }
        else if (lengths[x][y] == lengths[x][y - 1]) {
            --y;
        }
        else {
            [lcs appendFormat:@"%c", [self characterAtIndex:x - 1]];
            --x;
            --y;
        }
    }
    
    NSMutableString* reversed = [NSMutableString stringWithCapacity:lcs.length];
    
    for (NSInteger i = lcs.length - 1; i >= 0; --i) {
        [reversed appendFormat:@"%c", [lcs characterAtIndex:i]];
    }
    
    return reversed;
}

- (NSArray *) lcsDiff:(NSString *)string
{
    NSString *lcs = [self longestCommonSubsequence:string];
    NSUInteger l1 = [self length];
    NSUInteger l2 = [string length];
    NSUInteger lc = [lcs length];
    NSUInteger idx1 = 0;
    NSUInteger idx2 = 0;
    NSUInteger idxc = 0;
    NSMutableString *s1 = [[NSMutableString alloc]initWithCapacity:l1];
    NSMutableString *s2 = [[NSMutableString alloc]initWithCapacity:l2];
    NSMutableArray *res = [NSMutableArray arrayWithCapacity:10];
    for (;;) {
        if (idxc >= lc) break;
        unichar c1 = [self characterAtIndex:idx1];
        unichar c2 = [string characterAtIndex:idx2];
        unichar cc = [lcs characterAtIndex:idxc];
        if ((c1==cc) && (c2 == cc)) {
            if ([s1 length] || [s2 length]) {
                NSArray *e = @[ s1, s2];
                [res addObject:e];
                s1 = [[NSMutableString alloc]initWithCapacity:l1];
                s2 = [[NSMutableString alloc]initWithCapacity:l1];
            }
            idx1++; idx2++; idxc++;
            continue;
        }
        if (c1 != cc) {
            [s1 appendString:[NSString stringWithCharacters:&c1 length:1]];
            idx1++;
        }
        if (c2 != cc) {
            [s2 appendString:[NSString stringWithCharacters:&c2 length:1]];
            idx2++;
        }
    }
    if (idx1<l1) {
        [s1 appendString:[self substringFromIndex:idx1]];
    }
    if (idx2<l2) {
        [s2 appendString:[string substringFromIndex:idx2]];
    }
    if ([s1 length] || [s2 length]) {
        NSArray *e = @[ s1, s2];
        [res addObject:e];
    }
    return res;
}

@end
