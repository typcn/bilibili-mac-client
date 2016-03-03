//
//  PlayerControlView.m
//  bilibili
//
//  Created by TYPCN on 2015/9/6.
//  Copyright (c) 2016 TYPCN. All rights reserved.
//

#import "PlayerControlView.h"
#import "mpv.h"



@implementation PlayerControlView{
    Player *player;
    mpv_handle *mpv;
    dispatch_queue_t queue;
}

- (id)initWithPlayer:(Player *)m_player{
    self = [super init];
    if(self){
        player = m_player;
        mpv = player.mpv;
        queue = player.queue;
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect {
    [[NSColor blackColor] setFill];
    NSRectFill(dirtyRect);
    [super drawRect:dirtyRect];
}

- (IBAction)nextEP:(id)sender {

}

- (IBAction)prevEP:(id)sender {
    
}

- (IBAction)playPause:(id)sender {
    if(queue && mpv){
        dispatch_async(queue, ^{
            if(strcmp(mpv_get_property_string(mpv,"pause"),"no")){
                mpv_set_property_string(mpv,"pause","no");
            }else{
                mpv_set_property_string(mpv,"pause","yes");
            }
        });
    }
}

@end
