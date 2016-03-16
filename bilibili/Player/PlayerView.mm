//
//  PlayerView.m
//  bilibili
//
//  Created by TYPCN on 2015/3/30.
//  Copyleft 2016 TYPCN. All rights reserved.
//


#import "PlayerView.h"
#import "MediaInfoDLL.h"
#import "SimpleVideoFormatParser.h"
#import "BarrageHeader.h"
#import "PreloadManager.h"
#import "Player.h"
#import "PlayerWindow.h"
#import "PlayerControlView.h"
#import "PlayerEventProxy.h"
#import "LiveChat.h"

#import "../CommentConvert/danmaku2ass.hpp"

@interface PlayerView (){
    __weak PlayerWindow *window;
    __weak PlayerControlView *playerControlView;
    __weak NSWindow *lastWindow;
    
    __weak IBOutlet NSView *ContentView;
    __weak IBOutlet NSView *LoadingView;
    
    PlayerControlWindowController *playerControlWindowController;
    NSString *videoDomain;
    
    BOOL windowSetup;
}

@end


@implementation PlayerView


@synthesize liveChatWC;

void wakeup(void *context) {
    if(context){
        PlayerView *a = (__bridge PlayerView *) context;
        if(a &&
           [a.className isEqualToString:@"PlayerView"] &&
           [a respondsToSelector:@selector(readEvents)]){
            [a readEvents];
        }
    }
}

inline void check_error(int status)
{
    if (status < 0) {
        NSLog(@"mpv API error: %s", mpv_error_string(status));
        dispatch_async(dispatch_get_main_queue(), ^(void){
            NSAlert *alert = [[NSAlert alloc] init];
            [alert setMessageText:@"Fatal Error\nPlease open console.app and upload logs to GitHub or send email to typcncom@gmail.com"];
            [alert runModal];
        });
    }
}

- (void)loadWithPlayer:(Player *)m_player{
    [m_player setVideoView:ContentView];
    self.player = m_player;
    if(window){
        [window setPlayerAndInit:self.player];
        [window setAcceptsMouseMovedEvents:YES];
    }
    [self loadControls];
    [self loadVideo:self.player.video];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    lastWindow = [[NSApplication sharedApplication] keyWindow];
    [lastWindow resignKeyWindow];
    [lastWindow miniaturize:self];
    
    double Wheight = [[NSUserDefaults standardUserDefaults] doubleForKey:@"playerheight"];
    double Wwidth = [[NSUserDefaults standardUserDefaults] doubleForKey:@"playerwidth"];

    NSString *res = [NSString stringWithFormat:@"%dx%d",(int)Wwidth,(int)Wheight];
    
    NSLog(@"[PlayerView] Width: %f Height: %f",Wwidth,Wheight);
    
    if(Wwidth < 300 || Wheight < 300){
        NSLog(@"[PlayerView] Size set to fillscreen");
        NSRect rect = [[NSScreen mainScreen] visibleFrame];
        NSNumber *viewHeight = [NSNumber numberWithFloat:rect.size.height];
        NSNumber *viewWidth = [NSNumber numberWithFloat:rect.size.width];
        res = [NSString stringWithFormat:@"%dx%d",[viewWidth intValue],[viewHeight intValue]];
        [self.view setFrame:rect];
    }else{
        NSRect rect = self.view.frame;
        rect.size = NSMakeSize(Wwidth, Wheight);
        [self.view setFrame:rect];
    }
}

- (void)viewDidAppear{
    window = (PlayerWindow *)self.view.window;
    [window makeKeyAndOrderFront:NSApp];
    [window makeMainWindow];
    if(!windowSetup){
        [self setupWindow];
        windowSetup = YES;
    }
}

- (void)loadControls {
    playerControlWindowController = [[PlayerControlWindowController alloc] initWithWindowNibName:@"PlayerControl"];
    
    playerControlView = (PlayerControlView *)playerControlWindowController.window.contentView;
    [playerControlView setPlayer:self.player];
    
    self.player.playerControlView = playerControlView;
}

- (void)setupWindow {
    double WX = [[NSUserDefaults standardUserDefaults] doubleForKey:@"playerX"];
    double WY = [[NSUserDefaults standardUserDefaults] doubleForKey:@"playerY"];
    NSPoint pos = NSMakePoint(WX, WY);
    NSLog(@"[PlayerView] X: %f Y: %f",WX,WY);
    [window setFrameOrigin:pos];
    [window setPlayerAndInit:self.player];
    [window setLastWindow:lastWindow];
    [window setAcceptsMouseMovedEvents:YES];
    [self.loadingImage setAnimates:YES];
    
    PlayerEventProxy *ep = [[PlayerEventProxy alloc] init];
    [ep setAcceptsTouchEvents:YES];
    [ep setFrame:NSMakeRect(0,0,self.view.frame.size.width,self.view.frame.size.height)];
    [ep setAutoresizingMask:NSViewMaxYMargin|NSViewMinXMargin|NSViewWidthSizable|NSViewMaxXMargin|NSViewHeightSizable|NSViewMinYMargin];
    [self.view addSubview:ep positioned:NSWindowAbove relativeTo:nil];
}

- (void)setTip:(NSString *)text{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.textTip setStringValue:NSLocalizedString(text, nil)];
    });
}

- (void)loadVideo:(VideoAddress *)video{
    NSLog(@"[PlayerView] Starting load video");

    dispatch_async(self.player.queue, ^{
getInfo:

        NSString *playURL = [video nextPlayURL];
        if(!playURL){
            return [self setTip:@"所有视频源连接失败，可能视频已失效"];
        }

        [self setTip:@"正在获取视频信息"];

        NSLog(@"[PlayerView] Reading video info");
        
        NSString *firstVideo = [video firstFragmentURL];
        NSLog(@"%@",[self.player getAttr:@"commentFile"]);
        if([self.player getAttr:@"commentFile"]){
            NSDictionary *VideoInfoJson = [self getVideoInfo:firstVideo];
            
            NSLog(@"[PlayerView] Read video info completed");
            
            NSNumber *width = [VideoInfoJson objectForKey:@"width"];
            NSNumber *height = [VideoInfoJson objectForKey:@"height"];
            
            if([height intValue] < 100 || [width intValue] < 100){
                goto getInfo;
            }
            
            [self.player setAttr:@"vheight" data:height];
            [self.player setAttr:@"vwidth" data:width];
        }
        
        NSString *fvHost = [[NSURL URLWithString:firstVideo] host];
        if([fvHost length] > 0){
            videoDomain = fvHost;
        }
        
        [self playVideo: playURL];
    });
}

- (void)setMPVOption:(const char *)name :(const char*)data{
    int status = mpv_set_option_string(self.player.mpv, name, data);
    check_error(status);
}

- (void)setTitle:(NSString *)title{
    if(videoDomain){
        title = [NSString stringWithFormat:NSLocalizedString(@"%@ - 服务器: %@", nil),title, videoDomain];
    }
    [window setTitle:title];
}

- (void)playVideo:(NSString *)URL{

    // Start Playing Video
    self.player.mpv  = mpv_create();

    if (!self.player.mpv) {
        NSLog(@"[PlayerView] Failed creating context");
        return [self setTip:@"无法创建播放器"];
    }
    
    [self setTip:@"正在载入视频"];
    
    int64_t wid = (intptr_t) ContentView;
    check_error(mpv_set_option(self.player.mpv, "wid", MPV_FORMAT_INT64, &wid));
    
    [self setMPVOption:"input-default-bindings" :"yes"];
    [self setMPVOption:"input-vo-keyboard" :"yes"];
    [self setMPVOption:"input-cursor" :"no"];
    [self setMPVOption:"osc" :"no"];
    //[self setMPVOption:"script-opts" :"osc-layout=box,osc-seekbarstyle=bar"];
    [self setMPVOption:"user-agent" :[userAgent cStringUsingEncoding:NSUTF8StringEncoding]];
    [self setMPVOption:"framedrop" :"vo"];
    [self setMPVOption:"hr-seek" :"yes"];
    [self setMPVOption:"fs-black-out-screens" :"yes"];
    [self setMPVOption:"vo" :"opengl:pbo:dither=no:alpha=no"];
    [self setMPVOption:"screenshot-directory" :"~/Desktop"];
    [self setMPVOption:"screenshot-format" :"png"];


    [self setMPVOption:"input-media-keys" :"no"];
    
    int maxBuffer = [self getSettings:@"maxBufferSize"];
    NSString *maxBufStr = [NSString stringWithFormat:@"%d",maxBuffer];
    if(maxBufStr && [maxBufStr length] > 3){
        [self setMPVOption:"cache-default" :[maxBufStr UTF8String]];
    }

    int disableKeepAspect = [self getSettings:@"disableKeepAspect"];
    if(disableKeepAspect == 1){
        [self setMPVOption:"keepaspect" :"no"];
    }
    
    if(self.title){
        [self setMPVOption:"force-media-title" :[self.title UTF8String]];
    }
    
    int enableHW = [self getSettings:@"enableHW"];
    if(enableHW){
        [self setMPVOption: "hwdec" : "videotoolbox"];
        //[self setMPVOption: "sub-fps" : "60"];
        [self setMPVOption: "display-fps" : "60"];
        [self setMPVOption: "demuxer-rawvideo-fps" : "60"];
    }else{
        [self setMPVOption: "vf" : "lavfi=\"fps=fps=60:round=down\""];
    }

    if([self.player getAttr:@"live"] && [self.player getAttr:@"cid"]){
        dispatch_async(dispatch_get_main_queue(), ^{
            BarrageRenderer *_renderer = [[BarrageRenderer alloc] init];
            [self.view setWantsLayer:YES];
            [_renderer.view setFrame:NSMakeRect(0,0,self.view.frame.size.width,self.view.frame.size.height)];
            [_renderer.view setAutoresizingMask:NSViewMaxYMargin|NSViewMinXMargin|NSViewWidthSizable|NSViewMaxXMargin|NSViewHeightSizable|NSViewMinYMargin];
            [self.view addSubview:_renderer.view positioned:NSWindowAbove relativeTo:nil];
            [_renderer start];
            self.player.barrageRenderer = _renderer;
            NSStoryboard *storyBoard = [NSStoryboard storyboardWithName:@"Main" bundle:nil];
            self.liveChatWC = [storyBoard instantiateControllerWithIdentifier:@"LiveChatWindow"];
            [self.liveChatWC showWindow:self];
            LiveChat *lc = (LiveChat *)self.liveChatWC.window.contentViewController;
            [lc setPlayerAndInit:self.player];
        });
    }

    NSString *windowTitle = [self.player getAttr:@"title"];
    if(![windowTitle length]){
        windowTitle = @"TYPCN Media Player";
    }
    
    NSString *cmfile = [self.player getAttr:@"commentFile"];
    NSString *subfile = [self.player getAttr:@"subtitleFile"];
    
    if(cmfile){ // If have comment file
        NSString *converted_comment = [self convertComments:cmfile]; // Convert comment file to ass sub
        if(converted_comment && subfile){ // If convert success and have sub file
            [self addSubtitle:subfile withCommentFile:converted_comment]; // Append comment to sub file
            subfile = converted_comment;
        }else if(converted_comment){ // If convert success but not have sub file
            subfile = converted_comment;
        }else{
            windowTitle = [windowTitle stringByAppendingString:NSLocalizedString(@" - 弹幕转换失败", nil)];
        }
    }
    
    if(subfile){
        [self setMPVOption: "sub-ass" : "yes"];
        
        int substatus = mpv_set_option_string(self.player.mpv, "sub-file", [subfile UTF8String]);
        if(substatus < 0){
            windowTitle = [windowTitle stringByAppendingString:NSLocalizedString(@" - 字幕载入失败", nil)];
        }
    }
    
    dispatch_async(dispatch_get_main_queue(), ^(void){
        [self setTitle:windowTitle];
    });
    
    [self loadMPVSettings];
    
    // request important errors
    check_error(mpv_request_log_messages(self.player.mpv, "warn"));
    
    check_error(mpv_initialize(self.player.mpv));
    
    // Register to be woken up whenever mpv generates new events.
    mpv_set_wakeup_callback(self.player.mpv, wakeup, (__bridge void *) self);
    
    // Load the indicated file
    const char *cmd[] = {"loadfile", [URL cStringUsingEncoding:NSUTF8StringEncoding], NULL};
    check_error(mpv_command(self.player.mpv, cmd));
}

- (void) loadMPVSettings{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *applicationSupportDirectory = [paths firstObject];
    NSString *confDir = [NSString stringWithFormat:@"%@/com.typcn.bilibili/conf/",applicationSupportDirectory];
    
    BOOL isDir = NO;
    BOOL isExist = [[NSFileManager defaultManager] fileExistsAtPath:confDir isDirectory:&isDir];
    if(!isExist){
        [[NSFileManager defaultManager] createDirectoryAtPath:confDir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    NSString *oldsettings = [[NSUserDefaults standardUserDefaults] objectForKey:@"mpvSettings"];
    if(oldsettings && [oldsettings length] > 1){
        // For OSX chinese auto corrention
        oldsettings = [oldsettings stringByReplacingOccurrencesOfString:@"“" withString:@"\""];
        oldsettings = [oldsettings stringByReplacingOccurrencesOfString:@"”" withString:@"\""];
        oldsettings = [oldsettings stringByReplacingOccurrencesOfString:@"＃" withString:@"#"];
        
        NSString *confFile = [NSString stringWithFormat:@"%@mpv.conf",confDir];
        
        [oldsettings writeToFile:confFile atomically:YES encoding:NSUTF8StringEncoding error:nil];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"mpvSettings"];
    }
    
    mpv_set_option_string(self.player.mpv, "config-dir",[confDir UTF8String]);
    [self setMPVOption:"config" :"yes"];
}

- (NSDictionary *) getVideoInfo:(NSString *)url{
    NSLog(@"[VideoReader] Video Address: %@",url);
    if([url containsString:@"acgvideo.com"] && ![url containsString:@"live"]){
        NSDictionary *dic =  readVideoInfoFromURL(url);
        if(dic){
            return dic;
        }
    }
    MediaInfoDLL::MediaInfo MI = *new MediaInfoDLL::MediaInfo;
    MI.Open([url cStringUsingEncoding:NSUTF8StringEncoding]);
    MI.Option(__T("Inform"), __T("Video;%Width%"));
    NSString *width = [NSString stringWithCString:MI.Inform().c_str() encoding:NSUTF8StringEncoding];
    MI.Option(__T("Inform"), __T("Video;%Height%"));
    NSString *height = [NSString stringWithCString:MI.Inform().c_str() encoding:NSUTF8StringEncoding];
    NSDictionary *info = @{
                           @"width": width,
                           @"height": height,
                           };
    return info;
}

- (NSString *) convertComments:(NSString *)file{

    NSNumber *width = [self.player getAttr:@"vwidth"];
    NSNumber *height = [self.player getAttr:@"vheight"];
    
    NSString *resolution = [NSString stringWithFormat:@"%@x%@",width,height];
    NSLog(@"Video resolution: %@",resolution);
    
    if([height intValue] < 100 || [width intValue] < 100){
        return NULL;
    }
    
    if(![[NSFileManager defaultManager] fileExistsAtPath:file]){
        return NULL;
    }
    
    [self setTip:@"正在读取弹幕"];
    
    NSString *fontName = [[NSUserDefaults standardUserDefaults] objectForKey:@"fontName"];
    if(!fontName || [fontName length] < 1){
        fontName = @"STHeiti";
    }
    
    NSString *OutFile = [NSString stringWithFormat:@"%@%@.cminfo.ass", NSTemporaryDirectory(),[self.player playerName]];
    
    float mq = 6.75*[width doubleValue]/[height doubleValue]-4;
    float moveSpeed = [self getSettings:@"moveSpeed"];
    if(!moveSpeed){
        moveSpeed = 1.0;
    }else{
        moveSpeed = (0-moveSpeed)+1;
    }
    mq = mq*moveSpeed;
    float fontsize = [self getSettings:@"fontsize"];
    if(!fontsize){
        fontsize = 25.1;
    }else{
        fontsize = fontsize + 0.1;
    }
    if(mq < 3.0){
        mq = 3.0;
    }
    
    bool disableBottom;
    float disableSettings = [self getSettings:@"disableBottomComment"];
    if(disableSettings > 0 ){
        disableBottom = true;
    }else{
        disableBottom = false;
    }
    
    [[NSFileManager defaultManager] removeItemAtPath:OutFile error:nil];
    
    CommentParser *p = new CommentParser;
    
    NSString *block = [[NSUserDefaults standardUserDefaults] objectForKey:@"blockKeywords"];
    int blockBadword = [self getSettings:@"blcokBadword"];
    int blockDate = [self getSettings:@"blockDate"];
    int blockSpoiler = [self getSettings:@"blockSpoilers"];
    int block2B = [self getSettings:@"block2B"];
    
    if([block length] > 1){
        NSLog(@"Blockword got");
        NSMutableString *blockstr = [block mutableCopy];
        if(blockBadword == 1){
            [blockstr appendString:@"|脑残|傻|大脑有|大脑进|你妈|孙子"];
        }
        if(blockDate == 1){
            [blockstr appendString:@"|201|200|周目"];
        }
        if(blockSpoiler == 1){
            [blockstr appendString:@"|然后|后来|结果|剧透"];
        }
        if(block2B == 1){
            [blockstr appendString:@"|笑看|笑摸|笑而不语|看着你们"];
        }
        NSArray *blocks = [blockstr componentsSeparatedByString:@"|"];
        if([block length] > 0){
            for (NSString* string in blocks) {
                p->SetBlockWord([string cStringUsingEncoding:NSUTF8StringEncoding]);
            }
        }
    }
    
    p->SetFile([file cStringUsingEncoding:NSUTF8StringEncoding], [OutFile cStringUsingEncoding:NSUTF8StringEncoding]);
    p->SetRes([width intValue], [height intValue]);
    p->SetFont([fontName cStringUsingEncoding:NSUTF8StringEncoding], (int)[height intValue]/fontsize);
    p->SetDuration(mq,5);
    p->SetAlpha([[NSString stringWithFormat:@"%.2f",[self getSettings:@"transparency"]] floatValue]);
    p->SetRemoveBottom(disableBottom);
    bool isSuc = p->Convert(0);
    if(!isSuc){
        return NULL;
    }
    
    NSLog(@"Comment converted to %@",OutFile);
    return OutFile;
}

- (void) addSubtitle:(NSString *)filename withCommentFile:(NSString *)comment
{
    [self setTip:@"正在合并弹幕字幕"];
    
    NSError *error = nil;
    NSString *str = [[NSString alloc] initWithContentsOfFile:filename
                                                    encoding:NSUTF8StringEncoding
                                                       error:&error];
    // 字幕全文
    if(error){
        return;
    }
    
    NSMutableString *commentText = [[[NSString alloc] initWithContentsOfFile:comment
                                                                   encoding:NSUTF8StringEncoding
                                                                      error:&error] mutableCopy];
    // 弹幕全文
    if(error){
        return;
    }
    
    // 从字幕中匹配出 Style
    NSRegularExpression *styleRegex = [NSRegularExpression regularExpressionWithPattern:@"(Style:.*)" options:NSRegularExpressionCaseInsensitive error:&error];
    
    if(error){
        return;
    }
    
    NSArray *matches = [styleRegex matchesInString:str options:0 range:NSMakeRange(0, [str length])];
    if(matches.count < 1){
        return;
    }

    
    NSRange styleEndRange = [commentText rangeOfString:@"1, 1, 0, 7, 0, 0, 0, 0"];
    
    long endLocation = styleEndRange.location + styleEndRange.length; // 弹幕中找到 Style 结束的位置
    
    for (id object in matches) {
        NSRange matchRange = [object range];
        NSString *style = [str substringWithRange:matchRange]; // Style 字符串
        [commentText insertString:[NSString stringWithFormat:@"\n%@\n",style] atIndex:endLocation]; // 将 Style 插入弹幕
    }
    
    long DialogueStartLocation = [str rangeOfString:@"\nDialogue"].location; // 获取字幕中第一个 Dialogue 的位置
    long DialogueLength = [str length] - DialogueStartLocation;
    
    NSString *Dialogue = [str substringWithRange:NSMakeRange(DialogueStartLocation, DialogueLength)];
    
    [commentText appendString:Dialogue]; // 向弹幕最后加入字幕的全部内容
    [commentText writeToFile:comment atomically:YES encoding:NSUTF8StringEncoding error:nil]; // 将弹幕写入文件
}
- (void) handleEvent:(mpv_event *)event
{
    if(playerControlView){
        [playerControlView onMpvEvent:event];
    }
    switch (event->event_id) {
        case MPV_EVENT_SHUTDOWN: {
            dispatch_async(dispatch_get_main_queue(), ^(void){
                [self.view.window performClose:self];
            });
            NSLog(@"Stopping player");
            break;
        }
            
        case MPV_EVENT_LOG_MESSAGE: {
            struct mpv_event_log_message *msg = (struct mpv_event_log_message *)event->data;
            NSLog(@"[%s] %s: %s", msg->prefix, msg->level, msg->text);
            break;
        }
            
        case MPV_EVENT_VIDEO_RECONFIG: {
            
            break;
        }
        
        case MPV_EVENT_START_FILE:{
            dispatch_async(dispatch_get_main_queue(), ^{
                if([[[NSUserDefaults standardUserDefaults] objectForKey:@"FirstPlayed"] length] != 3){
                    [[NSUserDefaults standardUserDefaults] setObject:@"yes" forKey:@"FirstPlayed"];
                    [self.textTip setStringValue:NSLocalizedString(@"正在创建字体缓存", nil)];
                    [self.subtip setStringValue:NSLocalizedString(@"首次播放需要最多 2 分钟来建立缓存\n请不要关闭窗口", nil)];
                }else{
                    [self.textTip setStringValue:NSLocalizedString(@"正在缓冲", nil)];
                }
            });
            break;
        }
            
        case MPV_EVENT_PLAYBACK_RESTART: {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.loadingImage setAnimates:NO];
                [LoadingView setHidden:YES];
            });
            break;
        }
        
        case MPV_EVENT_END_FILE:{
            dispatch_async(dispatch_get_main_queue(), ^{
                [LoadingView setHidden:NO];
                [self.textTip setStringValue:NSLocalizedString(@"播放完成，关闭窗口继续", nil)];
                [self runAutoSwitch];
                [self.view.window performClose:self];
            });
            break;
        }
        
        case MPV_EVENT_PAUSE: {
            break;
        }
        case MPV_EVENT_UNPAUSE: {
            break;
        }
            
        default: ;
            //NSLog(@"Player Event: %s", mpv_event_name(event->event_id));
    }
}

- (void) readEvents
{
    dispatch_async(self.player.queue, ^{
        while (self.player.mpv) {
            mpv_event *event = mpv_wait_event(self.player.mpv, 0);
            if(!event)
                break;
            if (event->event_id == MPV_EVENT_NONE)
                break;
            if(self && [self respondsToSelector:@selector(handleEvent:)]){
                [self handleEvent:event];
            }else{
                return;
            }
        }
    });
}

- (void)runAutoSwitch
{
    int autoplay = [self getSettings:@"autoPlay"];
    if(!autoplay){
        return;
    }
    WebTabView *tv = (WebTabView *)[browser activeTabContents];
    if(!tv){
        return;
    }
    TWebView *twv = [tv GetTWebView];
    if(!twv){
        return;
    }
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"webpage/autoswitch" ofType:@"js"];
    NSString *script = [[NSString alloc] initWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    if(script){
        [twv runJavascript:script];
    }
}

- (float) getSettings:(NSString *) key
{
    NSUserDefaults *settingsController = [NSUserDefaults standardUserDefaults];
    if([key isEqualToString:@"quality"]){
        long quality = [settingsController integerForKey:@"quality"];
        if(!quality){
            NSLog(@"Select max quanlity");
            return 4;
        }else{
            return quality;
        }
    }else if ([key isEqualToString:@"transparency"]){
        float result = [settingsController floatForKey:key];
        if(!result){
            return 0.8;
        }else{
            return result;
        }
    }else{
        float result = [settingsController floatForKey:key];
        if(!result){
            return 0;
        }else{
            return result;
        }
    }
}


- (void)dealloc{
    NSLog(@"[PlayerView] Dealloc");
}

@end