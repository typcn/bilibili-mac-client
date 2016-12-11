//
//  Player.h
//  bilibili
//
//  Created by TYPCN on 2016/3/3.
//  Copyright © 2016 TYPCN. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "PlayerView.h"
#import "BarrageRenderer.h"

#include "mpv.h"

@class PlayerControlView;

@interface Player : NSObject

@property (nonatomic, readonly, strong) PlayerView *view;
@property (nonatomic, readonly, strong) NSWindowController *windowController;
@property (nonatomic, weak) PlayerControlView *playerControlView;
@property (nonatomic, weak) NSView *videoView;

@property (nonatomic) NSString *siteName;
@property (nonatomic) NSString *playerName;

@property (nonatomic) BarrageRenderer *barrageRenderer;
@property (nonatomic) VideoAddress *video;

@property (nonatomic) BOOL pendingDealloc;

@property (nonatomic, assign) mpv_handle *mpv;
@property (nonatomic, strong) dispatch_queue_t queue;

- (id)initWithVideo:(VideoAddress *)m_video attrs:(NSDictionary *)dict;

- (id)getAttr:(NSString *)key;
- (void)setAttr:(NSString *)key data:(id)data;

- (void)stopAndDestory;
- (void)destory;

@end
