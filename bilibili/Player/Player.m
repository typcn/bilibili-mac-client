//
//  Player.m
//  bilibili
//
//  Created by TYPCN on 2016/3/3.
//  Copyright © 2016 TYPCN. All rights reserved.
//

#import "Player.h"
#import "PlayerManager.h"

@implementation Player

@synthesize view;

- (id)init{
    [NSException raise:@"NoVideoError" format:@"You must init player with video"];
    return NULL;
}

- (id)initWithVideo:(VideoAddress *)m_video{
    self = [super init];
    if(self){
        self.video = m_video;
        view = [[PlayerView alloc] initWithPlayer:self];
    }
    return self;
}


- (void)stopAndDestory{
    [[PlayerManager sharedInstance] removePlayer:self];
    view = nil;
}

@end
