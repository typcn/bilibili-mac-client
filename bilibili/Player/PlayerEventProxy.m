//
//  PlayerTouchHandler.m
//  bilibili
//
//  Created by TYPCN on 2016/3/9.
//  Copyright © 2016 TYPCN. All rights reserved.
//

#import "PlayerEventProxy.h"

@implementation PlayerEventProxy

- (void)drawRect:(NSRect)dirtyRect {
    [[NSColor clearColor] setFill];
    NSRectFill(dirtyRect);
}

- (void)rightMouseDown:(NSEvent *)theEvent{
    [self.window rightMouseDown:theEvent];
}

@end
