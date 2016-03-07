//
//  PlayerWindow.m
//  bilibili
//
//  Created by TYPCN on 2016/3/4.
//  Copyright © 2016 TYPCN. All rights reserved.
//

#import "PlayerWindow.h"
#import "PlayerControlView.h"
#import <CoreFoundation/CoreFoundation.h>
#import <Carbon/Carbon.h>

@implementation PlayerWindow{
    BOOL paused;
    BOOL hide;
    BOOL shiftKeyPressed;
    BOOL frontMost;
    CGPoint initialLocation;
    NSTimer *hideCursorTimer;
}

@synthesize postCommentWindowC;
@synthesize isActive;

- (BOOL)canBecomeMainWindow { return YES; }
- (BOOL)canBecomeKeyWindow { return YES; }
- (BOOL)acceptsFirstResponder { return YES; }
- (BOOL)becomeFirstResponder { return YES; }
- (BOOL)resignFirstResponder { return YES; }

- (void)setPlayerAndInit:(Player *)player{
    [self hideCursorAndHudAfter:1.0];
    self.player = player;
    isActive = YES;
}

- (void)becomeKeyWindow{
    if(self.player.playerControlView){
        [self.player.playerControlView show];
    }
    isActive = YES;
    [super becomeKeyWindow];
}

- (void)resignKeyWindow{
    if(self.player.playerControlView){
        [self.player.playerControlView hide];
    }
    isActive = NO;
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
    
    currentLocation = [NSEvent mouseLocation];
    newOrigin.x = currentLocation.x - initialLocation.x;
    newOrigin.y = currentLocation.y - initialLocation.y;
    
    [self setFrameOrigin:newOrigin];
}

- (void)setFrame:(NSRect)windowFrame
         display:(BOOL)displayViews{
    NSRect oldRect = self.frame;
    [super setFrame:windowFrame display:displayViews];
    [self resizePlayerControlView:oldRect new:windowFrame];
}

- (void)setFrameOrigin:(NSPoint)aPoint{
    NSRect oldRect = self.frame;

    [super setFrameOrigin:aPoint];
     NSRect newRect = self.frame;
    [self resizePlayerControlView:oldRect new:newRect];

}

- (void)resizePlayerControlView:(NSRect)old new:(NSRect)new{
    if(self.player.playerControlView){
        NSRect pcw = self.player.playerControlView.window.frame;

        CGFloat playerLeft = old.origin.x;
        CGFloat playerRight = playerLeft + old.size.width;
        CGFloat playerBottom = old.origin.y;
        CGFloat playerTop = playerBottom + old.size.height;
        
        CGFloat controlLeft = pcw.origin.x;
        CGFloat controlRight = controlLeft + pcw.size.width;
        CGFloat controlBottom = pcw.origin.y;
        CGFloat controlTop = controlBottom + pcw.size.height;
        
        
        // 检查播放控制条是否与播放器窗口有重叠区域
        if(controlRight < playerLeft || controlLeft > playerRight || controlBottom > playerTop || controlTop < playerBottom){
            // 没有则认为用户已经分离播放器和控制条，不做任何处理
            return;
        }
        
        // 播放条是否在播放器中心
        
        BOOL isAtCenter = NO;
        CGFloat playerCenterAbs = (old.size.width / 2) + old.origin.x;
        CGFloat controlCenterAbs = (pcw.size.width / 2) + pcw.origin.x;
        
        if(ABS(playerCenterAbs - controlCenterAbs) < 10){
            isAtCenter = YES;
        }
        

        if(!CGSizeEqualToSize(old.size, new.size)){
            // 播放器大小有变化
            if(pcw.size.width > (new.size.width * 0.8)){ // Width overflow
                pcw.size.width = (new.size.width * 0.8);
            }
            
            if(pcw.size.width < 480){ // Min size
                pcw.size.width = 480;
            }
            
            CGFloat newControlRight = pcw.origin.x + pcw.size.width;
            CGFloat newPlayerRight = new.origin.x + new.size.width;
            
            // 右边溢出，拖回来
            if(newControlRight > newPlayerRight){
                CGFloat diff = new.size.width - old.size.width;
                pcw.origin.x += diff;
            }
            
            // OSX 的 Y 坐标是从下面开始的，转换成人的习惯，缩小的时候顶间距不变
            CGFloat diff = new.size.height - old.size.height;
            pcw.origin.y += diff;
            
            // 下边溢出，或者播放条在屏幕底部
            if(pcw.origin.y < new.origin.y || (controlBottom - playerBottom < 300 && new.size.height > 300)){
                pcw.origin.y -= diff;
            }
        }
        if(!CGPointEqualToPoint(old.origin, new.origin)){
            // 位置有变化
            pcw.origin.x += new.origin.x - old.origin.x;
            pcw.origin.y += new.origin.y - old.origin.y;
        }
        
        
        if(isAtCenter){
            pcw.origin.x = ((new.size.width - pcw.size.width) / 2) + new.origin.x; // Reset location to center
        }
        
        [self.player.playerControlView.window setFrame:pcw display:YES];
    }
}

- (void)mouseMoved:(NSEvent *)event
{
    if(self.player.playerControlView){
        NSInteger windowId = [NSWindow windowNumberAtPoint:[NSEvent mouseLocation] belowWindowWithWindowNumber:0];
        if(windowId == self.player.playerControlView.window.windowNumber){
            // Cursor is in control window
            if(hideCursorTimer){
                [hideCursorTimer invalidate];
                hideCursorTimer = nil;
            }
            return;
            
        }else if (windowId != self.windowNumber) {
            // Cursor is outside this window
            [self hideCursorAndHudAfter:0.5];
        }else{
            
            // Sometimes the mousemoved event will still called even if loss focus
            if(!isActive){
                return;
            }
            // Cursor is in window
            [self.player.playerControlView show];
            if(hideCursorTimer){
                return;
            }
            [self hideCursorAndHudAfter:1.0];
        }
    }
}

- (void)hideCursor{
    [hideCursorTimer invalidate];
    hideCursorTimer = nil;
    if (CGEventSourceSecondsSinceLastEventType(kCGEventSourceStateCombinedSessionState, kCGEventMouseMoved) >= 1) {
        [NSCursor setHiddenUntilMouseMoves:YES];
        [self.player.playerControlView hide];
    }else{
        [self hideCursorAndHudAfter:0.5];
    }
}

- (void)hideCursorAndHudAfter:(NSTimeInterval)time{
    if(hideCursorTimer){
        [hideCursorTimer invalidate];
        hideCursorTimer = nil;
    }
    hideCursorTimer = [NSTimer scheduledTimerWithTimeInterval:time target:self selector:@selector(hideCursor) userInfo:nil repeats:NO];
}

- (void)rightMouseDown:(NSEvent *)theEvent{
    if(self.player.mpv){
        int pause = 0;
        if(!self.player.playerControlView.currentPaused){
            pause = 1;
        }
        mpv_set_property_async(self.player.mpv, 0, "pause", MPV_FORMAT_FLAG, &pause);
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
    
    switch( [event keyCode] ) {
        case 125:{ // ⬇️
            const char *args[] = {"add", "volume", shiftKeyPressed?"-5":"-20" ,NULL};
            mpv_command_async(self.player.mpv, 0, args);
            break;
        }
        case 126:{ // ⬆️
            const char *args[] = {"add", "volume", shiftKeyPressed?"5":"20" ,NULL};
            mpv_command_async(self.player.mpv, 0, args);
            break;
        }
        case 124:{ // 👉
            const char *args[] = {"seek", shiftKeyPressed?"1":"5" ,NULL};
            mpv_command_async(self.player.mpv, 0, args);
            break;
        }
        case 123:{ // 👈
            const char *args[] = {"seek", shiftKeyPressed?"-1":"-5" ,NULL};
            mpv_command_async(self.player.mpv, 0, args);
            break;
        }
        case 49:{ // Space
            
            int pause = 0;
            if(!self.player.playerControlView.currentPaused){
                pause = 1;
            }
            mpv_set_property_async(self.player.mpv, 0, "pause", MPV_FORMAT_FLAG, &pause);
            
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
        case 53:{ // Esc key
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
            double speed = 1;
            mpv_set_property_async(self.player.mpv, 0, "speed", MPV_FORMAT_DOUBLE, &speed);
            break;
        }
            
        default:{
            [self handleKeyboardEvnet:event keyDown:YES];
            break;
        }
    }
}

-(void)keyUp:(NSEvent*)event {
    
    [self flagsChanged:event];
    
    [self handleKeyboardEvnet:event keyDown:NO];
    
}

- (void)handleKeyboardEvnet:(NSEvent *)event keyDown:(BOOL)keyDown {
    if(!self.player.mpv){
        return;
    }
    const char *keyState = keyDown?"keydown":"keyup";
    NSString *str = [self stringByKeyEvent:event];
    
    const char *args[] = {keyState, [str UTF8String], NULL};
    mpv_command_async(self.player.mpv, 0, args);
}

CFStringRef stringByKeyCode(CGKeyCode keyCode)
{
    TISInputSourceRef currentKeyboard = TISCopyInputSourceForLanguage(CFSTR("en-US"));
    CFDataRef layoutData = TISGetInputSourceProperty(currentKeyboard, kTISPropertyUnicodeKeyLayoutData);
    const UCKeyboardLayout *keyboardLayout =
    (const UCKeyboardLayout *)CFDataGetBytePtr(layoutData);
    
    UInt32 keysDown = 0;
    UniChar chars[4];
    UniCharCount realLength;
    
    UCKeyTranslate(keyboardLayout,
                   keyCode,
                   kUCKeyActionDisplay,
                   0,
                   LMGetKbdType(),
                   kUCKeyTranslateNoDeadKeysBit,
                   &keysDown,
                   sizeof(chars) / sizeof(chars[0]),
                   &realLength,
                   chars);
    CFRelease(currentKeyboard);
    
    return CFStringCreateWithCharacters(kCFAllocatorDefault, chars, 1);
}


- (NSString *)stringByKeyEvent:(NSEvent*)event
{
    NSString *str = @"";
    int cocoaModifiers = [event modifierFlags];
    if (cocoaModifiers & NSControlKeyMask)
        str = [str stringByAppendingString:@"Ctrl+"];
    if (cocoaModifiers & NSCommandKeyMask)
        str = [str stringByAppendingString:@"Meta+"];
    if (cocoaModifiers & NSAlternateKeyMask)
        str = [str stringByAppendingString:@"Alt+"];
    if (cocoaModifiers & NSShiftKeyMask)
        str = [str stringByAppendingString:@"Shift+"];
    
    NSString *keystr = (__bridge NSString *)stringByKeyCode([event keyCode]);
    
    str = [str stringByAppendingString:keystr];
    
    NSLog(@"[PlayerWindow] Key event: %@",str);
    return str;
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
            [self.player.playerControlView setHidden:YES];
        }
        if(hideCursorTimer){
            [hideCursorTimer invalidate];
            hideCursorTimer = nil;
        }
        if([browser tabCount] > 0){
            [self.lastWindow makeKeyAndOrderFront:nil];
        }
    });
    return YES;
}

- (void)dealloc{
    NSLog(@"[PlayerWindow] Dealloc");
}

@end