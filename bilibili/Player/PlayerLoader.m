//
//  PlayerLoader.m
//  bilibili
//
//  Created by TYPCN on 2016/3/4.
//  Copyright © 2016 TYPCN. All rights reserved.
//

#import "PlayerLoader.h"
#import "PlayerManager.h"
#import "MBProgressHUD.h"
#import "SubtitleHelper.h"
#import "VP_Local.h"
#import <zlib.h>

@interface PlayerLoader ()

@end

@implementation PlayerLoader {
    dispatch_queue_t vl_queue;
    MBProgressHUD *hud;
    NSString *lastPlayerId;
    SubtitleHelper *subHelper;
    
    BOOL isLoading;
    NSInteger thread_id;
    
    // Temp workaround for live play ( currently must enable CALayer ) & Apple's high-end opengl driver
    // If you create two opengl context with CALayer enabled , the first will hang up on "update" , the second will create success but can't draw anything
    // Prevent create two live player
    NSString *lastLivePlayerId;
}

#define IS_VL_QUEUE (strcmp("video_address_load_queue", \
    dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL)) == 0)

+ (instancetype)sharedInstance {
    static id sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] initWithWindowNibName:@"PlayerLoader"];
    });
    return sharedInstance;
}

- (id)initWithWindowNibName:(NSString *)windowNibName {
    self = [super initWithWindowNibName:windowNibName];
    if(self){
        vl_queue = dispatch_queue_create("video_address_load_queue", NULL);
        subHelper = [SubtitleHelper sharedInstance];
    }
    return self;
}


- (void)loadVideoFrom:(VideoProvider *)provider withPageUrl:(NSString *)url{
    if(isLoading){
        return;
    }
    [self setText:@"正在生成解析参数"];
    dispatch_async(vl_queue, ^(void){
        NSDictionary *dict = [provider generateParamsFromURL:url];
        if(!dict){
            [self showError:@"错误" :@"解析参数生成失败，请检查 URL 是否正确"];
            return;
        }
        [self loadVideoFrom:provider withData:dict];
    });
}


- (void)loadVideoFrom:(VideoProvider *)provider withData:(NSDictionary *)params{
    if(isLoading && !IS_VL_QUEUE){
        return;
    }
    [self setText:@"正在解析视频地址"];
    dispatch_async(vl_queue, ^(void){
        @try {
            VideoAddress *video = [provider getVideoAddress:params];
            if(!video){
                [NSException raise:@VP_RESOLVE_ERROR format:@"Empty Content"];
            }
            [self loadVideo:video withAttrs:params];
        }
        @catch (NSException *exception) {
            [self showError:[exception name] :[exception description]];
        }
    });
}

- (void)loadVideoWithLocalFiles:(NSArray *)files {
    if(isLoading){
        return;
    }
    [self setText:@"正在打开本地文件"];
    dispatch_async(vl_queue, ^(void){
        @try {
            NSDictionary *params = @{
                @"files":files
            };
            VideoAddress *video = [[VP_Local sharedInstance] getVideoAddress:params];
            if(!video){
                [NSException raise:@VP_RESOLVE_ERROR format:@"Empty Content"];
            }
            [self loadVideo:video withAttrs:params];
        }
        @catch (NSException *exception) {
            [self showError:[exception name] :[exception description]];
        }
    });
}

- (void)loadVideo:(VideoAddress *)video {
    [self loadVideo:video withAttrs:nil];
}

- (void)loadVideo:(VideoAddress *)video withAttrs:(NSDictionary *)attrs{
    if(isLoading && !IS_VL_QUEUE){
        return;
    }
    dispatch_async(vl_queue, ^(void){
        NSDictionary *_attrs = attrs;
        BOOL haveSub = [subHelper canHandle:_attrs];
        if(haveSub){
            [self setText:@"正在下载弹幕/字幕"];
            _attrs = [subHelper getSubtitle:attrs];
        }
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [self _loadVideo:video withAttrs:_attrs];
        });
    });
}

- (void)_loadVideo:(VideoAddress *)video withAttrs:(NSDictionary *)attrs{
    [self setText:@"正在创建播放器"];
    if(attrs[@"live"] && lastLivePlayerId){
        Player *p = [[PlayerManager sharedInstance] getPlayer:lastLivePlayerId];
        if(p){
            [self showError:@"无法创建两个直播窗口" :@"目前渲染弹幕必须开 CALayer，开两个 CALayer+OpenGLContext 会导致第一个卡死在 Update，第二个会没法画任何东西，我会在之后制作 vo_metal 避免这一问题"];
            return;
        }
    }
    
    NSData* fgurl = [[video firstFragmentURL] dataUsingEncoding:NSUTF8StringEncoding];
    unsigned long result = crc32(0, [fgurl bytes], (UInt)[fgurl length]);
    NSString *playerId = [NSString stringWithFormat:@"%ld",result];
    
    Player *p = [[PlayerManager sharedInstance] createPlayer:playerId withVideo:video attrs:attrs];
    if(!p){
        [self showError:@"错误" :@"播放器创建失败"];
        return;
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"TYPlayerCreated" object:playerId];
    lastPlayerId = playerId;
    if(attrs[@"live"]){
        lastLivePlayerId = playerId;
    }
    [self hide:1.0];
}


- (void)showError:(NSString *)title :(NSString *)desc{
    dispatch_async(dispatch_get_main_queue(), ^(void){
        hud.mode = MBProgressHUDModeText;
        hud.labelText = NSLocalizedString(title, nil);
        hud.detailsLabelText = NSLocalizedString(desc, nil);
        [self hide:3.0];
    });
}

- (void)setText:(NSString *)text{
    dispatch_async(dispatch_get_main_queue(), ^(void){
        [self show];
        hud.labelText = NSLocalizedString(text, nil);
    });
}

- (void)show{
    isLoading = YES;
    if(!hud){
        hud = [MBProgressHUD showHUDAddedTo:self.window.contentView animated:YES];
        hud.removeFromSuperViewOnHide = YES;
        hud.mode = MBProgressHUDModeIndeterminate;
        [self.window setLevel:NSPopUpMenuWindowLevel];
        [self.window makeKeyAndOrderFront:self];
        [[self.window contentView] setHidden:NO];
        [NSApp activateIgnoringOtherApps:YES];
    }
}

- (void)hide:(NSTimeInterval)i{
    dispatch_async(dispatch_get_main_queue(), ^(void){
        [hud hide:YES afterDelay:i];
        [NSTimer scheduledTimerWithTimeInterval:i+0.5
                                         target:self
                                       selector:@selector(hideWindow)
                                       userInfo:nil
                                        repeats:NO];
    });
}

- (void)hideWindow{
    [[self.window contentView] setHidden:YES];
    [self.window setLevel:NSNormalWindowLevel-1];
    [self.window orderBack:self];
    hud = NULL;
    isLoading = NO;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    [self.window setHidesOnDeactivate:YES];
    [self.window setOpaque:NO];
    [self.window setBackgroundColor:[NSColor clearColor]];
}

- (NSString *)lastPlayerId {
    return lastPlayerId;
}

@end


@interface PlayerLoaderWindow : NSWindow
@end


@implementation PlayerLoaderWindow

- (BOOL) canBecomeKeyWindow { return NO; }
- (BOOL) canBecomeMainWindow { return NO; }
- (BOOL) acceptsFirstResponder { return NO; }
- (BOOL) becomeFirstResponder { return NO; }
- (BOOL) resignFirstResponder { return NO; }


@end


@interface PlayerLoaderView : NSView

@end


@implementation PlayerLoaderView

- (id)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    return self;
}

- (void)drawRect:(NSRect)rect
{
    [[NSColor clearColor] set];
    //NSRectFill([selfframe]);
}

@end