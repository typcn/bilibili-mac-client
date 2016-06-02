//
//  PlayerControlView.m
//  bilibili
//
//  Created by TYPCN on 2015/9/6.
//  Copyright (c) 2016 TYPCN. All rights reserved.
//

#import "PlayerControlView.h"
#import "mpv.h"
#import "mpv_nullsafe.h"
#import "PlayerWindow.h"
#import "PlayPosition.h"

@implementation PlayerControlView {
    NSTimer *timeUpdateTimer;
    __weak PlayerWindow *playerWindow;
    __weak IBOutlet NSButton *playPauseButton;
    __weak IBOutlet NSButton *muteButton;
    __weak IBOutlet NSButton *subVisButton;
    __weak IBOutlet NSButton *keepAspectButton;
    __weak IBOutlet NSButton *rightTextSwitchButton;
    __weak IBOutlet NSSlider *volumeSlider;
    __weak IBOutlet NSSlider *timeSlider;
    __weak IBOutlet NSTextField *timeText;
    __weak IBOutlet NSTextField *rightTimeText;

    double v_duration;
    double v_filesize;
    double v_playback_time;

    BOOL isShowingDuration;
    BOOL isAfterVideoRender;
    BOOL isKeepAspect;
    BOOL isHided;
     
    BOOL isFirstBuffed;
     
    BOOL needSaveTime;
}

@synthesize currentPaused;
@synthesize currentMuted;
@synthesize currentFullscreen;
@synthesize currentSubVis;

- (void)onMpvEvent:(mpv_event *)event{
    if(event->event_id == MPV_EVENT_GET_PROPERTY_REPLY || event->event_id == MPV_EVENT_PROPERTY_CHANGE){
        mpv_event_property *propety = event->data;
        void *data = propety->data;
        if(!data){
            return;
        }
        if(strcmp(propety->name, "pause") == 0){
            int paused = *(int *)data;
            [self onPaused:paused];
        }else if(strcmp(propety->name, "mute") == 0){
            int mute = *(int *)data;
            [self onMuted:mute];
        }else if(strcmp(propety->name, "sub-visibility") == 0){
            int vis = *(int *)data;
            [self onSubVisibility:vis];
        }else if(strcmp(propety->name, "options/keepaspect") == 0){
            int keep = *(int *)data;
            [self onKeepAspect:keep];
        }else if(strcmp(propety->name, "volume") == 0){
            double volume = *(double *)data;
            [self onVolume:volume];
        }else if(strcmp(propety->name, "duration") == 0){
            double duration = *(double *)data;
            [self onDuration:duration];
        }else if(strcmp(propety->name, "time-pos") == 0){
            double t = *(double *)data;
            [self onPlaybackTime:t];
        }else if(strcmp(propety->name, "cache-used") == 0){
            double t = *(double *)data;
            [self onCacheSize:t];
        }else if(strcmp(propety->name, "cache") == 0){
            double t = *(double *)data;
            [self onCacheFillRate:t];
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
            [self updateTime];
            break;
        }
        default:{
            break;
        }
    }
}

- (BOOL)allowsVibrancy{
    return YES;
}

- (void)readInitState{
    if(isAfterVideoRender || !self.player.mpv || !self.player.windowController){
        return;
    }
     NSString *cid = [self.player getAttr:@"cid"];
     if(cid && [cid length]){
          needSaveTime = YES;
     }
    isHided = YES;
    isAfterVideoRender = YES;
    mpv_get_property_async(self.player.mpv, 0, "pause", MPV_FORMAT_FLAG);
    mpv_get_property_async(self.player.mpv, 0, "volume", MPV_FORMAT_DOUBLE);
    mpv_get_property_async(self.player.mpv, 0, "time-pos", MPV_FORMAT_DOUBLE);
    mpv_observe_property(self.player.mpv, 0, "pause", MPV_FORMAT_FLAG);
    mpv_observe_property(self.player.mpv, 0, "mute", MPV_FORMAT_FLAG);
    mpv_observe_property(self.player.mpv, 0, "sub-visibility", MPV_FORMAT_FLAG);
    mpv_observe_property(self.player.mpv, 0, "options/keepaspect", MPV_FORMAT_FLAG);
    mpv_observe_property(self.player.mpv, 0, "volume", MPV_FORMAT_DOUBLE);
    mpv_observe_property(self.player.mpv, 0, "duration", MPV_FORMAT_DOUBLE);
    
    [self setMaterial:NSVisualEffectMaterialDark];
    [self setState:NSVisualEffectStateActive];
    [self setAppearance:[NSAppearance appearanceNamed:NSAppearanceNameVibrantDark]];
    [self setBlendingMode:NSVisualEffectBlendingModeBehindWindow];
    
    playerWindow = (PlayerWindow *)self.player.windowController.window;
    
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
    if(currentPaused || !self.player || !self.player.mpv || !self.player.windowController){
        return;
    }
    mpv_get_property_async(self.player.mpv, 0, "time-pos", MPV_FORMAT_DOUBLE);
    if(!isShowingDuration){
        mpv_get_property_async(self.player.mpv, 0, "cache-used", MPV_FORMAT_DOUBLE);
        mpv_get_property_async(self.player.mpv, 0, "cache", MPV_FORMAT_DOUBLE);
    }else if(v_duration > 0){
        [self onDuration:v_duration];
    }
}

- (void)show{
    if(!isHided || !isAfterVideoRender || !playerWindow.isActive){
        return;
    }
    [self setHidden:NO];
    [self setState:NSVisualEffectStateActive];
    if(timeUpdateTimer){
        [timeUpdateTimer invalidate];
    }
    timeUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                       target:self
                                                     selector:@selector(updateTime)
                                                     userInfo:nil
                                                      repeats:YES];
    if(playerWindow.level - NSNormalWindowLevel > -1){
        [self.window setLevel:playerWindow.level + 1];
        [self.window orderWindow:NSWindowAbove relativeTo:playerWindow.windowNumber];
        [[self.window animator] setAlphaValue:1.0];
        isHided = NO;
    }
}

- (void)hide:(BOOL)noAnimation{
    if(isHided){
        return;
    }
    if(needSaveTime){
        [self savePlayPosition];
    }
    [[self.window animator] setAlphaValue:0.0];
    [self.window setLevel:NSNormalWindowLevel];
    [self.window orderWindow:NSWindowAbove relativeTo:playerWindow.windowNumber];
    if(noAnimation){
        [self orderOut];
    }else{
        NSTimeInterval delay = [[NSAnimationContext currentContext] duration] + 0.1;
        [self performSelector:@selector(orderOut) withObject:nil afterDelay:delay];
    }
}

- (void)orderOut{
    [self setState:NSVisualEffectStateInactive];
    [self setHidden:YES];
    [self.window orderOut:self];
    [timeUpdateTimer invalidate];
    timeUpdateTimer = nil;
    isHided = YES;
}

- (IBAction)nextEP:(id)sender {
    const char *args[] = {"playlist-next" ,NULL};
    mpv_command_async(self.player.mpv,0, args);
}

- (IBAction)prevEP:(id)sender {
    const char *args[] = {"playlist-prev" ,NULL};
    mpv_command_async(self.player.mpv,0, args);
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

- (IBAction)mute:(id)sender {
    int mute = 0;
    if(!currentMuted){
        mute = 1;
    }
    mpv_set_property_async(self.player.mpv, 0, "mute", MPV_FORMAT_FLAG, &mute);
}

- (IBAction)fullScreen:(id)sender {
    [playerWindow toggleFullScreen:sender];
}

- (IBAction)subSwitch:(id)sender {
    int vis = 0;
    if(!currentSubVis){
        vis = 1;
    }
    const char *args[] = {"show-text", vis?"已开启弹幕/字幕":"已关闭弹幕/字幕" ,NULL};
    mpv_command_async(self.player.mpv,0, args);
    mpv_set_property_async(self.player.mpv, 0, "sub-visibility", MPV_FORMAT_FLAG, &vis);
}

- (IBAction)keepAspectSwitch:(id)sender {
    int keep = 1;
    if(isKeepAspect){
        keep = 0;
        isKeepAspect = NO;
    }else{
        isKeepAspect = YES;
    }
    const char *args[] = {"show-text", keep?"关闭填满窗口":"开启填满窗口" ,NULL};
    mpv_command_async(self.player.mpv,0, args);
    mpv_set_property_async(self.player.mpv, 0, "options/keepaspect", MPV_FORMAT_FLAG, &keep);
}

- (IBAction)rightTextSwitch:(id)sender {
    if(isShowingDuration){
        isShowingDuration = NO;
    }else{
        isShowingDuration = YES;
    }
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
        v_duration = duration;
    });
}

- (void)onPlaybackTime:(double)t{
    dispatch_async(dispatch_get_main_queue(), ^(void){
        timeSlider.doubleValue = t;
        timeText.stringValue = [self timeFormatted:t];
        v_playback_time = t;
    });
}

- (void)onCacheSize:(double)t{
    dispatch_async(dispatch_get_main_queue(), ^(void){
        if(t > 0){
            int sizeMB = t/1024;
            rightTimeText.stringValue = [NSString stringWithFormat:@"%d MB",sizeMB];
            if(sizeMB > 10 && !isFirstBuffed){
                isFirstBuffed = YES;
                isShowingDuration = YES;
            }
        }
    });
}

- (void)onCacheFillRate:(double)t{
    dispatch_async(dispatch_get_main_queue(), ^(void){
        if(t > 0 && v_duration > 0){
            double playbackRate = (v_playback_time / v_duration)*100;
            double allRate = playbackRate + t;
            if(allRate > 90){
                rightTimeText.stringValue = @"缓冲完成";
                isShowingDuration = YES;
            }
        }
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

- (void)onMuted:(int)isMuted{
    dispatch_async(dispatch_get_main_queue(), ^(void){
        if(isMuted){
            currentMuted = YES;
            muteButton.state = NSOnState;
        }else{
            currentMuted = NO;
            muteButton.state = NSOffState;
        }
    });
}

- (void)onSubVisibility:(int)vis{
    dispatch_async(dispatch_get_main_queue(), ^(void){
        if(vis){
            currentSubVis = YES;
            subVisButton.state = NSOffState;
        }else{
            currentSubVis = NO;
            subVisButton.state = NSOnState;
        }
    });
}

- (void)onKeepAspect:(int)keep{
    dispatch_async(dispatch_get_main_queue(), ^(void){
        // call SetFrame to force opengl canvas resize
        NSView *videoView = self.player.videoView;
        NSRect rect = videoView.frame;
        rect.size.width += 1;
        [videoView setFrame:rect];
        rect.size.width -= 1;
        [videoView setFrame:rect];
        
        if(keep){
            isKeepAspect = YES;
            keepAspectButton.state = NSOffState;
        }else{
            isKeepAspect = NO;
            keepAspectButton.state = NSOnState;
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

- (void)savePlayPosition{
    NSString *cid = [self.player getAttr:@"cid"];
    if(cid && [cid length]){
        if(v_duration - v_playback_time < 120){
            NSLog(@"[PlayerControl] Seems video is ending, remove position record");
            [[PlayPosition sharedManager] removeKey:cid];
        }else{
            [[PlayPosition sharedManager] addKey:cid time:v_playback_time];
            NSLog(@"[PlayerControl] Saving position");
        }
    }
}

- (void)dealloc{
    if(timeUpdateTimer){
        [timeUpdateTimer invalidate];
        timeUpdateTimer = nil;
    }

    NSLog(@"[PlayerControl] Dealloc");
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
    [self.window setOpaque:NO];
    [self.window setBackgroundColor:[NSColor clearColor]];
    [self.window setMovable:YES];
    [self.window setMovableByWindowBackground:YES];
}

@end