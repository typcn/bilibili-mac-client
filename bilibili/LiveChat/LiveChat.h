//
//  LiveChat.h
//  bilibili
//
//  Created by TYPCN on 2015/5/17.
//  Copyright (c) 2016 TYPCN. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Player.h"

// TODO: Allow render comments on external window, avoid to use CALayer

@interface LiveChat : NSViewController
@property (weak, nonatomic) Player *player;

- (void)setPlayerAndInit:(Player *)player;
- (void)onNewMessage:(NSString *)cmContent :(NSString *)userName :(int)ftype :(int)fsize :(NSColor *)color;
- (void)onNewError:(NSString *)str;

@end
