//
//  Player.m
//  bilibili
//
//  Created by TYPCN on 2016/3/3.
//  Copyright © 2016 TYPCN. All rights reserved.
//

#import "Player.h"
#import "PlayerManager.h"

@implementation Player{
    NSMutableDictionary *attrs;
    mpv_handle *mpv_handle_var;
}

@synthesize view;
@synthesize windowController;

- (id)init{
    [NSException raise:@"NoVideoError" format:@"You must init player with video"];
    return NULL;
}

- (id)initWithVideo:(VideoAddress *)m_video{
    self = [super init];
    if(self){
        self.video = m_video;
        attrs = [[NSMutableDictionary alloc] init];
        NSStoryboard *storyBoard = [NSStoryboard storyboardWithName:@"Main" bundle:nil];
        windowController = [storyBoard instantiateControllerWithIdentifier:@"playerWindow"];
        view = (PlayerView *)windowController.contentViewController;
        [view loadWithPlayer:self];
        [windowController showWindow:self];
        [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
    }
    return self;
}

- (id)getAttr:(NSString *)key{
    return attrs[key];
}

- (void)setAttr:(NSString *)key data:(id)data{
    attrs[key] = data;
}

- (void)setAttr:(NSDictionary *)dict{
    attrs = [dict mutableCopy];
}

- (void)stopAndDestory{
    [[PlayerManager sharedInstance] removePlayer:self];
    view = nil;
}

@end
