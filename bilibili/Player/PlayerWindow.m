//
//  PlayerWindow.m
//  bilibili
//
//  Created by TYPCN on 2016/3/4.
//  Copyright © 2016 TYPCN. All rights reserved.
//

#import "PlayerWindow.h"
#import "PlayerControlView.h"

@implementation PlayerWindow{
    BOOL paused;
    BOOL hide;
    BOOL shiftKeyPressed;
    BOOL frontMost;
    CGPoint initialLocation;
}

@synthesize postCommentWindowC;

- (BOOL)canBecomeMainWindow { return YES; }
- (BOOL)canBecomeKeyWindow { return YES; }
- (BOOL)acceptsFirstResponder { return YES; }
- (BOOL)becomeFirstResponder { return YES; }
- (BOOL)resignFirstResponder { return YES; }

- (NSArray *)customWindowsToEnterFullScreenForWindow:(NSWindow *)window{
    return nil;
}

- (void)window:(NSWindow *)window
startCustomAnimationToEnterFullScreenWithDuration:(NSTimeInterval)duration{
    
}

- (void)becomeKeyWindow{
    if(self.player.playerControlView){
        [self.player.playerControlView.window setLevel:self.level + 1];
        [self.player.playerControlView.window orderWindow:NSWindowAbove relativeTo:self.windowNumber];
    }
    [super becomeKeyWindow];
}

- (void)resignKeyWindow{
    if(self.player.playerControlView){
        [self.player.playerControlView.window setLevel:self.level];
        [self.player.playerControlView.window orderWindow:NSWindowAbove relativeTo:self.windowNumber];
    }
    [super resignKeyWindow];
}

// setMovableByWindowBackground will not work with NSOpenGLContext
-(void)mouseDown:(NSEvent *)theEvent {
    NSRect  windowFrame = self.frame;
    
    initialLocation = [NSEvent mouseLocation];
    
    initialLocation.x -= windowFrame.origin.x;
    initialLocation.y -= windowFrame.origin.y;
}

- (void)mouseDragged:(NSEvent *)theEvent {
    CGPoint currentLocation = [NSEvent mouseLocation];
    
    CGPoint newOrigin;
    CGPoint oldOrigin = self.frame.origin;
    
    currentLocation = [NSEvent mouseLocation];
    newOrigin.x = currentLocation.x - initialLocation.x;
    newOrigin.y = currentLocation.y - initialLocation.y;
    
    [self setFrameOrigin:newOrigin];

    // move player control view
    
    if(self.player.playerControlView){
        newOrigin = self.frame.origin; // If moved to top bar , new origin will changed by system
        CGFloat movedX = newOrigin.x - oldOrigin.x;
        CGFloat movedY = newOrigin.y - oldOrigin.y;
    
        NSWindow *pcw = self.player.playerControlView.window;
        CGPoint pOrigin = [pcw frame].origin;
        pOrigin.x += movedX;
        pOrigin.y += movedY;
        
        [pcw setFrameOrigin:pOrigin];
    }
}


- (NSSize)windowWillResize:(NSWindow *)sender
                    toSize:(NSSize)frameSize{

    [[NSUserDefaults standardUserDefaults] setDouble:frameSize.width forKey:@"playerwidth"];
    [[NSUserDefaults standardUserDefaults] setDouble:frameSize.height forKey:@"playerheight"];
    return frameSize;
}

- (void)flagsChanged:(NSEvent *) event {
    shiftKeyPressed = ([event modifierFlags] & NSShiftKeyMask) != 0;
}

- (void)keyDown:(NSEvent*)event {
    
    [self flagsChanged:event];
    
    if(!self.player.mpv){
        NSLog(@"MPV not exists");
        return;
    }
    
    // mpv is thread-safe , just run command on new thread to prevent block main thread
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        switch( [event keyCode] ) {
            case 125:{ // ⬇️
                int volume = atoi(mpv_get_property_string(self.player.mpv,"volume"));
                if(volume < 5){
                    return;
                }
                char volstr[4];
                snprintf(volstr , 4, "%d", volume - 5);
                NSLog(@"Volume: %s",volstr);
                mpv_set_property_string(self.player.mpv,"volume",volstr);
                break;
            }
            case 126:{ // ⬆️
                
                int volume = atoi(mpv_get_property_string(self.player.mpv,"volume"));
                if(volume > 94){
                    return;
                }
                char volstr[3];
                snprintf(volstr , 4, "%d", volume + 5);
                NSLog(@"Volume: %s",volstr);
                mpv_set_property_string(self.player.mpv,"volume",volstr);
                
                break;
            }
            case 124:{ // 👉
                
                const char *args[] = {"seek", shiftKeyPressed?"1":"5" ,NULL};
                mpv_command(self.player.mpv, args);
                break;
            }
            case 123:{ // 👈
                const char *args[] = {"seek", shiftKeyPressed?"-1":"-5" ,NULL};
                mpv_command(self.player.mpv, args);
                break;
            }
            case 49:{ // Space
                
                if(strcmp(mpv_get_property_string(self.player.mpv,"pause"),"no")){
                    mpv_set_property_string(self.player.mpv,"pause","no");
                }else{
                    mpv_set_property_string(self.player.mpv,"pause","yes");
                }
                
                break;
            }
            case 36:{ // Enter
                if(self.player.mpv){
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSStoryboard *storyBoard = [NSStoryboard storyboardWithName:@"Main" bundle:nil];
                        postCommentWindowC = [storyBoard instantiateControllerWithIdentifier:@"PostCommentWindow"];
                        [postCommentWindowC showWindow:self];
                    });
                }
                break;
            }
            case 53:{ // Esc key to hide mouse
                // Nothing to do
                break;
            }
            case 3:{
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSUInteger flags = [[NSApp currentEvent] modifierFlags];
                    if ((flags & NSCommandKeyMask)) {
                        [self toggleFullScreen:self]; // Command+F key to toggle fullscreen
                    }else if(frontMost){
                        [self setLevel:NSNormalWindowLevel];
                        frontMost = NO;
                    }else{
                        [self setLevel:NSScreenSaverWindowLevel + 1]; // F key to front most
                        [self orderFront:nil];
                        [self becomeKeyWindow];
                        frontMost = YES;
                    }
                });
                break;
            }
            case 51:{ // BACKSPACE
                mpv_set_property_string(self.player.mpv,"speed","1");
                break;
            }
                
            default:{
                [self handleKeyboardEvnet:event keyDown:YES];
                break;
            }
        }
    });
}

-(void)keyUp:(NSEvent*)event {
    
    [self flagsChanged:event];
    
    if(!self.player.mpv){
        return;
    }
    
    [self handleKeyboardEvnet:event keyDown:NO];
    
}

- (void)handleKeyboardEvnet:(NSEvent *)event keyDown:(BOOL)keyDown {
    
    const char *keyState = keyDown?"keydown":"keyup";
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        switch ( [event keyCode] ) {
            case 1:{ // s
                const char *args[] = {keyState, shiftKeyPressed?"S":"s", NULL};
                mpv_command(self.player.mpv, args);
                break;
            }
            case 9:{ // v
                const char *args[] = {keyState, shiftKeyPressed?"V":"v", NULL};
                mpv_command(self.player.mpv, args);
                break;
            }
            case 31:{ // o
                const char *args[] = {keyState, shiftKeyPressed?"O":"o", NULL};
                mpv_command(self.player.mpv, args);
                break;
            }
            case 43:{ // ,
                
                const char *args[] = {keyState, shiftKeyPressed?"<":"," ,NULL};
                mpv_command(self.player.mpv, args);
                
                break;
            }
            case 47:{ // .
                
                const char *args[] = {keyState, shiftKeyPressed?">":"." ,NULL};
                mpv_command(self.player.mpv, args);
                break;
            }
            case 33:{ // [{
                const char *args[] = {keyState, shiftKeyPressed?"{":"[" ,NULL};
                mpv_command(self.player.mpv, args);
                break;
            }
            case 30:{ // ]}
                const char *args[] = {keyState, shiftKeyPressed?"}":"]" ,NULL};
                mpv_command(self.player.mpv, args);
                break;
            }
            case 6:{ // z
                const char *args[] = {keyState, "z" ,NULL};
                mpv_command(self.player.mpv, args);
                break;
            }
            case 7:{ // x
                const char *args[] = {keyState, "x" ,NULL};
                mpv_command(self.player.mpv, args);
                break;
            }
            case 37:{ // l
                const char *args[] = {keyState, shiftKeyPressed?"L":"l" ,NULL};
                mpv_command(self.player.mpv, args);
                break;
            }
            default: // Unknow
                NSLog(@"Key pressed: %hu", [event keyCode]);
                break;
        }
    });
}


- (void) mpv_cleanup
{
    if (self.player.mpv) {
        dispatch_async(self.player.queue, ^{
            mpv_set_wakeup_callback(self.player.mpv, NULL,NULL);
            
            const char *stop[] = {"stop", NULL};
            mpv_command(self.player.mpv, stop);
            
            const char *quit[] = {"quit", NULL};
            mpv_command(self.player.mpv, quit);
            
            mpv_detach_destroy(self.player.mpv);
            self.player.mpv = NULL;
        });
    }
}

- (BOOL)windowShouldClose:(id)sender{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"LastPlay"];
    NSLog(@"[PlayerWindow] Closing Window");

    if(self.player.queue){
        [self mpv_cleanup];
        [self.player destory];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSUserDefaults standardUserDefaults] setDouble:self.frame.origin.x forKey:@"playerX"];
        [[NSUserDefaults standardUserDefaults] setDouble:self.frame.origin.y forKey:@"playerY"];
        [postCommentWindowC close];
        if(self.player.playerControlView.window){
            // The dealloc of player control view will have delay , hide it first
            [self.player.playerControlView hide];
        }
        if([browser tabCount] > 0){
            [self.lastWindow makeKeyAndOrderFront:nil];
        }
    });
    return YES;
}

@end