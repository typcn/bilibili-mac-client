//
//  Player.h
//  bilibili
//
//  Created by TYPCN on 2016/3/3.
//  Copyright © 2016 TYPCN. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "PlayerView.h"
#import "VideoAddress.h"
#import "BarrageRenderer.h"

#include "mpv.h"

@interface Player : NSObject

@property (readonly, strong) PlayerView *view;

@property BarrageRenderer *barrageRenderer;
@property VideoAddress *video;

@property mpv_handle *mpv;
@property dispatch_queue_t queue;

- (id)initWithVideo:(VideoAddress *)video;


- (void)stopAndDestory;

@end
