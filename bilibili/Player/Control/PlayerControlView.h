//
//  PlayerControlView.h
//  bilibili
//
//  Created by TYPCN on 2015/9/6.
//  Copyright (c) 2016 TYPCN. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Player.h"

@interface PlayerControlView : NSVisualEffectView

@property (weak, nonatomic) Player *player;

- (void)onMpvEvent:(mpv_event *)event;

- (void)hide;
- (void)show;

@end

// Why do this ? because you can't overlap the apple's opengl view except you enable layer-backed view
// If you enable that , app will take more memory usage,  about 2x cpu usage , sometimes hang up / crash

// I think the best solution is create an borderless window

@interface PlayerControlWindow : NSWindow

@end

@interface PlayerControlWindowController : NSWindowController


@end