//
//  PlayerControlView.m
//  bilibili
//
//  Created by TYPCN on 2015/9/6.
//  Copyright (c) 2015 TYPCN. All rights reserved.
//

#import "PlayerControlView.h"
#import "client.h"

extern mpv_handle *mpv;
extern dispatch_queue_t queue;

@implementation PlayerControlView

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
