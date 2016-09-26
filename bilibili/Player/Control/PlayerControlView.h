//
//  PlayerControlView.h
//  bilibili
//
//  Created by TYPCN on 2015/9/6.
//  Copyright (c) 2016 TYPCN. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Player.h"
#import "LiveChat.h"

@interface PlayerControlView : NSVisualEffectView

@property (weak, nonatomic) Player *player;
@property (weak, nonatomic) LiveChat *liveChat;
@property (nonatomic) BOOL currentPaused;
@property (nonatomic) BOOL currentMuted;
@property (nonatomic) BOOL currentFullscreen;
@property (nonatomic) BOOL currentSubVis;

- (void)onMpvEvent:(mpv_event *)event;

- (void)hide:(BOOL)noAnimation;
- (void)show;

@end

// Why do this ? because you can't overlap the apple's opengl view except you enable layer-backed view
// If you enable that , app will take more memory usage,  about 2x cpu usage , sometimes hang up / crash

// I think the best solution is create an borderless window
// I'm going to add vo-metal in the future

@interface PlayerControlWindow : NSWindow

@end

@interface PlayerControlWindowController : NSWindowController


@end
