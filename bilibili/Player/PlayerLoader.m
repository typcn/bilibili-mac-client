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

#import <zlib.h>

@interface PlayerLoader ()

@end

@implementation PlayerLoader {
    dispatch_queue_t vl_queue;
    MBProgressHUD *hud;
}

- (BOOL) canBecomeKeyWindow { return YES; }
- (BOOL) canBecomeMainWindow { return YES; }
- (BOOL) acceptsFirstResponder { return YES; }
- (BOOL) becomeFirstResponder { return YES; }
- (BOOL) resignFirstResponder { return YES; }

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
    }
    return self;
}


- (void)loadVideoFrom:(VideoProvider *)provider withPageUrl:(NSString *)url{
    NSDictionary *dict = [provider generateParamsFromURL:url];
    [self loadVideoFrom:provider withData:dict];
}


- (void)loadVideoFrom:(VideoProvider *)provider withData:(NSDictionary *)params{
    [self.window makeKeyAndOrderFront:self];
    hud.labelText = NSLocalizedString(@"正在解析视频地址", nil);
    dispatch_async(vl_queue, ^(void){
        @try {
            VideoAddress *video = [provider getVideoAddress:params];
            if(!video){
                [NSException raise:@VP_RESOLVE_ERROR format:@"Empty Content"];
            }
            dispatch_async(dispatch_get_main_queue(), ^(void){
                [self loadVideo:video];
            });
        }
        @catch (NSException *exception) {
            [self showError:[exception name] :[exception description]];
        }
    });
}

- (void)loadVideoWithLocalFiles:(NSArray *)files {
    [self.window makeKeyAndOrderFront:self];
}

- (void)loadVideo:(VideoAddress *)video {
    hud.labelText = NSLocalizedString(@"正在创建播放器", nil);
    
    NSData* fgurl = [[video firstFragmentURL] dataUsingEncoding:NSUTF8StringEncoding];
    unsigned long result = crc32(0, [fgurl bytes], (UInt)[fgurl length]);
    NSString *playerId = [NSString stringWithFormat:@"%ld",result];
    
    Player *p = [[PlayerManager sharedInstance] createPlayer:playerId withVideo:video];
    if(!p){
        [self showError:@"错误" :@"播放器创建失败"];
    }
    [self hide];
}

- (void)showError:(NSString *)title :(NSString *)desc{
    dispatch_sync(dispatch_get_main_queue(), ^(void){
        hud.mode = MBProgressHUDModeText;
        hud.labelText = title;
        hud.detailsLabelText = desc;
        [self hide];
    });
}

- (void)hide{
    [hud hide:YES afterDelay:3.0];
    [NSTimer scheduledTimerWithTimeInterval:5.0
                                     target:self
                                   selector:@selector(hideWindow)
                                   userInfo:nil
                                    repeats:NO];
}

- (void)hideWindow{
    [self.window orderBack:self];
}

- (void)windowDidLoad {
    [super windowDidLoad];
    [self.window setHidesOnDeactivate:YES];
    [self.window setOpaque:YES];
    [self.window setBackgroundColor:[NSColor clearColor]];

    hud = [MBProgressHUD showHUDAddedTo:self.window.contentView animated:YES];
    hud.mode = MBProgressHUDModeIndeterminate;
    hud.labelText = NSLocalizedString(@"正在载入", nil);
    hud.removeFromSuperViewOnHide = NO;
}

@end


@interface PlayerLoaderWindow : NSWindow
@end


@implementation PlayerLoaderWindow

- (BOOL) canBecomeMainWindow { return YES; }
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