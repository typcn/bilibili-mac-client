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
    NSTimer *timeUpdateTimer;
    __weak IBOutlet NSButton *playPauseButton;
    __weak IBOutlet NSSlider *volumeSlider;
    __weak IBOutlet NSSlider *timeSlider;
    __weak IBOutlet NSTextField *timeText;
    __weak IBOutlet NSTextField *rightTimeText;
    
    BOOL currentPaused;
}

- (void)drawRect:(NSRect)dirtyRect {
    [[NSColor blackColor] setFill];
    NSRectFill(dirtyRect);
    [super drawRect:dirtyRect];
}

- (void)onMpvEvent:(mpv_event *)event{
    if(event->event_id == MPV_EVENT_GET_PROPERTY_REPLY || event->event_id == MPV_EVENT_PROPERTY_CHANGE){
        mpv_event_property *propety = event->data;
        void *data = propety->data;
        if(strcmp(propety->name, "pause") == 0){
            int paused = *(int *)data;
            [self onPaused:paused];
        }else if(strcmp(propety->name, "volume") == 0){
            double volume = *(double *)data;
            [self onVolume:volume];
        }else if(strcmp(propety->name, "duration") == 0){
            double duration = *(double *)data;
            [self onDuration:duration];
        }else if(strcmp(propety->name, "time-pos") == 0){
            double t = *(double *)data;
            [self onPlaybackTime:t];
        }
    }else{
        mpv_event_id event_id = event->event_id;
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [self onOnlyEventId:event_id];
        });
    }
}

- (void)onOnlyEventId:(mpv_event_id)event_id{
    switch (event_id) {
        case MPV_EVENT_VIDEO_RECONFIG: {
            [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(readInitState)
                                           userInfo:nil repeats:NO];
            break;
        }
        case MPV_EVENT_SEEK: {
            [self updateRealTime];
            break;
        }
        default:{
            break;
        }
    }
}

- (void)readInitState{
    mpv_get_property_async(self.player.mpv, 0, "pause", MPV_FORMAT_FLAG);
    mpv_get_property_async(self.player.mpv, 0, "volume", MPV_FORMAT_DOUBLE);
    mpv_get_property_async(self.player.mpv, 0, "duration", MPV_FORMAT_DOUBLE);
    mpv_get_property_async(self.player.mpv, 0, "time-pos", MPV_FORMAT_DOUBLE);
    mpv_observe_property(self.player.mpv, 0, "pause", MPV_FORMAT_FLAG);
    mpv_observe_property(self.player.mpv, 0, "volume", MPV_FORMAT_DOUBLE);
    
    NSWindow *playerWindow = self.player.windowController.window;
    
    // OSX Screen rect 0 start from left-bottom
    
    // Control bottom relative to screen  = Player window bottom + 40
    CGFloat y = 40 + playerWindow.frame.origin.y;
    
    // Control left = (Player width / 2) - ( Control width / 2 )
    CGFloat x = (playerWindow.frame.size.width - self.window.frame.size.width) / 2;

    // Control left relative to screen = Control left + Player Window left
    x += playerWindow.frame.origin.x;
    
    [self.window setFrameOrigin: NSMakePoint(x,y)];
    [self show];
}

- (void)updateTime {
    if(currentPaused || !self.player || !self.player.mpv){
        return;
    }
    // If you use mpv api to get time when you perform pause/play , Will cause deadlock, So here calc fake time
     mpv_get_property_async(self.player.mpv, 0, "time-pos", MPV_FORMAT_DOUBLE);}

- (void)updateRealTime {
    mpv_get_property_async(self.player.mpv, 0, "time-pos", MPV_FORMAT_DOUBLE);
//    last_update_video_time = [self getDouble:"playback-time"];
//    last_update_system_time = CFAbsoluteTimeGetCurrent();
}

- (void)show{
    [self setHidden:NO];
    if(timeUpdateTimer){
        [timeUpdateTimer invalidate];
    }
    timeUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                       target:self
                                                     selector:@selector(updateTime)
                                                     userInfo:nil
                                                      repeats:YES];
    [self.window setLevel:self.player.windowController.window.level + 1];
    [self.window orderWindow:NSWindowAbove relativeTo:self.player.windowController.window.windowNumber];
}

- (void)hide{
    [self setHidden:YES];
    [timeUpdateTimer invalidate];
    timeUpdateTimer = nil;
    [self.window setLevel:NSNormalWindowLevel];
    [self.window orderOut:self];
}

- (IBAction)nextEP:(id)sender {

}

- (IBAction)prevEP:(id)sender {
    
}


- (IBAction)setVolume:(id)sender {
    double volume = volumeSlider.doubleValue;
    mpv_set_property_async(self.player.mpv, 0, "volume", MPV_FORMAT_DOUBLE, &volume);
}

- (IBAction)seekTo:(id)sender {
    double time = timeSlider.doubleValue;
    mpv_set_property_async(self.player.mpv, 0, "playback-time", MPV_FORMAT_DOUBLE, &time);
}

- (IBAction)playPause:(id)sender {
    int pause = 0;
    if(!currentPaused){
        pause = 1;
    }
    mpv_set_property_async(self.player.mpv, 0, "pause", MPV_FORMAT_FLAG, &pause);
}

- (void)onVolume:(double)volume{
    dispatch_async(dispatch_get_main_queue(), ^(void){
        volumeSlider.doubleValue = volume;
    });
}

- (void)onDuration:(double)duration{
    dispatch_async(dispatch_get_main_queue(), ^(void){
        timeSlider.maxValue = duration;
        rightTimeText.stringValue = [self timeFormatted:duration];
    });
}

- (void)onPlaybackTime:(double)t{
    dispatch_async(dispatch_get_main_queue(), ^(void){
        timeSlider.doubleValue = t;
        timeText.stringValue = [self timeFormatted:t];
    });
}

- (void)onPaused:(int)isPaused{
    dispatch_async(dispatch_get_main_queue(), ^(void){
        if(isPaused){
            currentPaused = YES;
            playPauseButton.state = NSOffState;
        }else{
            currentPaused = NO;
            playPauseButton.state = NSOnState;
        }
    });
}

- (NSString *)timeFormatted:(int)totalSeconds
{
    
    int seconds = totalSeconds % 60;
    int minutes = (totalSeconds / 60) % 60;
    int hours = totalSeconds / 3600;
    
    return [NSString stringWithFormat:@"%02d:%02d:%02d",hours, minutes, seconds];
}


- (void)removeFromSuperviewWithoutNeedingDisplay{
    [super removeFromSuperviewWithoutNeedingDisplay];
    [timeUpdateTimer invalidate];
    timeUpdateTimer = nil;
}

@end

@implementation PlayerControlWindow

// Make sure this window never got focus

- (BOOL) canBecomeKeyWindow { return NO; }
- (BOOL) canBecomeMainWindow { return YES; }
- (BOOL) acceptsFirstResponder { return NO; }

@end

@implementation PlayerControlWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    [self.window setOpaque:YES];
    [self.window setBackgroundColor:[NSColor clearColor]];
    [self.window setMovable:YES];
    [self.window setMovableByWindowBackground:YES];
}

@end