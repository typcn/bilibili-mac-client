//
//  PlayerControlView.h
//  bilibili
//
//  Created by TYPCN on 2015/9/6.
//  Copyright (c) 2016 TYPCN. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Player.h"

@interface PlayerControlView : NSView

@property (weak, nonatomic) Player *player;

- (void)onMpvEvent:(mpv_event *)event;

- (void)hide;
- (void)show;

@end
