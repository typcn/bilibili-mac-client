//
//  PlayerControlView.m
//  bilibili
//
//  Created by TYPCN on 2015/9/6.
//  Copyright (c) 2015 TYPCN. All rights reserved.
//

#import "PlayerControlView.h"

@implementation PlayerControlView

- (void)drawRect:(NSRect)dirtyRect {
    
    [[NSColor colorWithRed:0 green:0 blue:0 alpha:0.6] setFill];
    NSRectFill(dirtyRect);
    [super drawRect:dirtyRect];
    // Drawing code here.
}

@end
