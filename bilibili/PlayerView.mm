//
//  PlayerView.m
//  bilibili
//
//  Created by TYPCN on 2015/3/30.
//  Copyleft 2015 TYPCN. All rights reserved.
//

#import "client.h"
#import "PlayerView.h"
#import "ISSoundAdditions.h"
#import <CommonCrypto/CommonDigest.h>
#import "APIKey.h"
#import "MediaInfoDLL.h"

#include "danmaku2ass_native/danmaku2ass.h"
#include <stdio.h>
#include <stdlib.h>
#include <sstream>

extern NSString *vUrl;
extern NSString *vCID;
extern NSString *userAgent;
extern NSString *cmFile;
NSString *vAID;
NSString *vPID;


extern BOOL parsing;
extern BOOL isTesting;

mpv_handle *mpv;
BOOL isCancelled;
BOOL isPlaying;

NSButton *postCommentButton;

static inline void check_error(int status)
{
    if (status < 0) {
        NSLog(@"mpv API error: %s", mpv_error_string(status));
        exit(1);
    }
}

@interface PlayerView (){
    dispatch_queue_t queue;
    NSWindow *w;
    NSView *wrapper;
}

@end


@implementation PlayerView

- (BOOL)canBecomeMainWindow { return YES; }
- (BOOL)canBecomeKeyWindow { return YES; }

static void wakeup(void *context) {
    if(context){
        @try {
            NSLog(@"%@",context);
            
            PlayerView *a = (__bridge PlayerView *) context;
            if(a){
                [a readEvents];
            }
        }
        @catch (NSException * e) {
            
        }
        
 
    }
}

- (NSString *) md5:(NSString *) input
{
    const char *cStr = [input UTF8String];
    unsigned char digest[16];
    CC_MD5( cStr, strlen(cStr), digest ); // This is the md5 call
    
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x", digest[i]];
    
    return  output;
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if([vCID isEqualToString:@"LOCALVIDEO"]){
        [[[NSApplication sharedApplication] keyWindow] performClose:self];
    }
    
    [[[NSApplication sharedApplication] keyWindow] orderBack:nil];
    [[[NSApplication sharedApplication] keyWindow] resignKeyWindow];
    [self.view.window makeKeyWindow];
    [self.view.window makeMainWindow];
    
    NSRect rect = [[NSScreen mainScreen] visibleFrame];
    NSNumber *viewHeight = [NSNumber numberWithFloat:rect.size.height];
    NSNumber *viewWidth = [NSNumber numberWithFloat:rect.size.width];
    NSString *res = [NSString stringWithFormat:@"%dx%d",[viewWidth intValue],[viewHeight intValue]];
    [self.view setFrame:rect];
    
    postCommentButton = self.PostCommentButton;
    NSLog(@"Playerview load success");
    self->wrapper = [self view];

    //[self.view.window makeKeyWindow];
    
    isCancelled = false;
    
    queue = dispatch_queue_create("mpv", DISPATCH_QUEUE_SERIAL);

    dispatch_async(queue, ^{
        if([vCID isEqualToString:@"LOCALVIDEO"]){
            if([vUrl length] > 5){
                NSDictionary *VideoInfoJson = [self getVideoInfo:vUrl];
                NSNumber *width = [VideoInfoJson objectForKey:@"width"];
                NSNumber *height = [VideoInfoJson objectForKey:@"height"];
                NSString *commentFile = @"/NotFound";
                if([cmFile length] > 5){
                    commentFile = [self getComments:width :height];
                }
                [self PlayVideo:commentFile :res];
                return;
            }else{
                [self.view.window performClose:self];
            }
            return;
        }
        
        [self.textTip setStringValue:@"正在解析视频地址"];
        
        // Get Sign
        int quality = [self getSettings:@"quality"];

        NSString *param = [NSString stringWithFormat:@"appkey=%@&otype=json&cid=%@&quality=%d%@",APIKey,vCID,quality,APISecret];
        NSString *sign = [self md5:[param stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        
        // Parse Video URL

        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"http:/*[^/]+/video/av(\\d+)(/|/index.html|/index_(\\d+).html)?(\\?|#|$)" options:NSRegularExpressionCaseInsensitive error:nil];
        
        NSTextCheckingResult *match = [regex firstMatchInString:vUrl options:0 range:NSMakeRange(0, [vUrl length])];
        
        NSRange aidRange = [match rangeAtIndex:1];
        
        if(aidRange.length > 0){
            vAID = [vUrl substringWithRange:aidRange];
            NSRange pidRange = [match rangeAtIndex:3];
            if(pidRange.length > 0 ){
                vPID = [vUrl substringWithRange:pidRange];
            }
        }else{
            vAID = @"0";
        }
        
        if(![vPID length]){
            vPID = @"1";
        }
        
        // Get Playback URL
        
        NSURL* URL = [NSURL URLWithString:[NSString stringWithFormat:@"http://interface.bilibili.com/playurl?appkey=%@&otype=json&cid=%@&quality=%d&sign=%@",APIKey,vCID,quality,sign]];
        NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:URL];
        request.HTTPMethod = @"GET";
        request.timeoutInterval = 5;
        
        
        [request addValue:@"Mozilla/5.0 (Windows NT 6.1; WOW64; rv:6.0.2) Gecko/20100101 Firefox/6.0.2 Fengfan/1.0" forHTTPHeaderField:@"User-Agent"];
        
        NSURLResponse * response = nil;
        NSError * error = nil;
        NSData * videoAddressJSONData = [NSURLConnection sendSynchronousRequest:request
                                              returningResponse:&response
                                                          error:&error];
        NSError *jsonError;
        NSMutableDictionary *videoResult = [NSJSONSerialization JSONObjectWithData:videoAddressJSONData options:NSJSONWritingPrettyPrinted error:&jsonError];
        
        NSArray *dUrls = [videoResult objectForKey:@"durl"];

        if([dUrls count] == 0){
            [self.textTip setStringValue:@"视频无法解析"];
            return;
        }
        
        NSString *firstVideo;
        NSArray *BackupUrls;
        
        if([[[[videoResult objectForKey:@"durl"] valueForKey:@"url"] className] isEqualToString:@"__NSCFString"]){
            vUrl = [[videoResult objectForKey:@"durl"] valueForKey:@"url"];
            firstVideo = vUrl;
        }else{
            for (NSDictionary *match in dUrls) {
                if([dUrls count] == 1){
                    vUrl = [match valueForKey:@"url"];
                    firstVideo = vUrl;
                    
                    NSArray *burl = [match valueForKey:@"backup_url"];
                    if([burl count] > 0){
                        BackupUrls = burl;
                    }
                }else{
                    NSString *tmp = [match valueForKey:@"url"];
                    if(!firstVideo){
                        firstVideo = tmp;
                        vUrl = [NSString stringWithFormat:@"%@%@%lu%@%@%@", @"edl://", @"%",(unsigned long)[tmp length], @"%" , tmp ,@";"];
                    }else{
                        vUrl = [NSString stringWithFormat:@"%@%@%lu%@%@%@",   vUrl   , @"%",(unsigned long)[tmp length], @"%" , tmp ,@";"];
                    }
                    
                }
            }
        }

        if(isCancelled){
            NSLog(@"Unloading");
            return;
        }
        
        // ffprobe
        [self.textTip setStringValue:@"正在获取视频信息"];

        int usingBackup = 0;
        
GetInfo:NSDictionary *VideoInfoJson = [self getVideoInfo:firstVideo];

        if([VideoInfoJson count] == 0){
            if(!BackupUrls){
                [self.textTip setStringValue:@"读取视频失败"];
            }else{
                usingBackup++;
                NSString *backupVideoUrl = [BackupUrls objectAtIndex:usingBackup];
                if([backupVideoUrl length] > 0){
                    firstVideo = backupVideoUrl;
                    vUrl = backupVideoUrl;
                    NSLog(@"Timeout! Change to backup url: %@",vUrl);
                    goto GetInfo;
                }else{
                    [self.textTip setStringValue:@"读取视频失败"];
                }
            }
        }
    
        if(isCancelled){
            NSLog(@"Unloading");
            return;
        }
        
        if(!jsonError){
            // Get Comment
            NSNumber *width = [VideoInfoJson objectForKey:@"width"];
            NSNumber *height = [VideoInfoJson objectForKey:@"height"];
            NSString *commentFile = [self getComments:width :height];
            [self PlayVideo:commentFile :res];
        }else{
            [self.textTip setStringValue:@"视频信息读取失败"];
            parsing = false;
            return;
        }
    });
    
}

- (void)PlayVideo:(NSString*) commentFile :(NSString*)res{
    // Start Playing Video
    mpv = mpv_create();
    if (!mpv) {
        NSLog(@"Failed creating context");
        exit(1);
    }
    
    [self.textTip setStringValue:@"正在载入视频"];
    
    int64_t wid = (intptr_t) self->wrapper;
    check_error(mpv_set_option(mpv, "wid", MPV_FORMAT_INT64, &wid));
    
    // Maybe set some options here, like default key bindings.
    // NOTE: Interaction with the window seems to be broken for now.
    check_error(mpv_set_option_string(mpv, "input-default-bindings", "yes"));
    check_error(mpv_set_option_string(mpv, "input-vo-keyboard", "yes"));
    check_error(mpv_set_option_string(mpv, "input-media-keys", "yes"));
    check_error(mpv_set_option_string(mpv, "input-cursor", "yes"));
    
    check_error(mpv_set_option_string(mpv, "osc", "yes"));
    check_error(mpv_set_option_string(mpv, "autofit", [res cStringUsingEncoding:NSUTF8StringEncoding]));
    check_error(mpv_set_option_string(mpv, "script-opts", "osc-layout=bottombar,osc-seekbarstyle=bar"));
    
    check_error(mpv_set_option_string(mpv, "user-agent", [@"Mozilla/5.0 (Windows NT 6.1; WOW64; rv:6.0.2) Gecko/20100101 Firefox/6.0.2 Fengfan/1.0" cStringUsingEncoding:NSUTF8StringEncoding]));
    check_error(mpv_set_option_string(mpv, "framedrop", "vo"));
    check_error(mpv_set_option_string(mpv, "vf", "lavfi=\"fps=fps=60:round=down\""));
    
    check_error(mpv_set_option_string(mpv, "sub-ass", "yes"));
    check_error(mpv_set_option_string(mpv, "sub-file", [commentFile cStringUsingEncoding:NSUTF8StringEncoding]));
    
    // request important errors
    check_error(mpv_request_log_messages(mpv, "warn"));
    
    check_error(mpv_initialize(mpv));
    
    // Register to be woken up whenever mpv generates new events.
    mpv_set_wakeup_callback(mpv, wakeup, (__bridge void *) self);
    
    // Load the indicated file
    if(!isTesting){
        NSLog(@"Video url : %@",vUrl);
    }
    const char *cmd[] = {"loadfile", [vUrl cStringUsingEncoding:NSUTF8StringEncoding], NULL};
    check_error(mpv_command(mpv, cmd));
}

- (NSDictionary *) getVideoInfo:(NSString *)url{

    MediaInfoDLL::MediaInfo MI;
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

- (NSString *) getComments:(NSNumber *)width :(NSNumber *)height {

    NSString *resolution = [NSString stringWithFormat:@"%@x%@",width,height];
    NSLog(@"Video resolution: %@",resolution);
    [self.textTip setStringValue:@"正在读取弹幕"];
    
    
    BOOL LC = [vCID isEqualToString:@"LOCALVIDEO"];
    
    NSString *stringURL = [NSString stringWithFormat:@"http://comment.bilibili.com/%@.xml",vCID];
    if(LC){
        stringURL = cmFile;
    }
    
    NSLog(@"Getting Comments from %@",stringURL);
    
    NSURL  *url = [NSURL URLWithString:stringURL];
    NSData *urlData = [NSData dataWithContentsOfURL:url];
    
    if (urlData or LC)
    {
        NSString  *filePath = [NSString stringWithFormat:@"%@/%@.cminfo.xml", @"/tmp",vCID];
        
        if(LC){
            NSString *correctString = [[NSString alloc] initWithData:urlData encoding:NSUTF8StringEncoding];
            urlData = [correctString dataUsingEncoding:NSUTF8StringEncoding];
        }
        
        [urlData writeToFile:filePath atomically:YES];
        
        NSString *OutFile = [NSString stringWithFormat:@"%@/%@.cminfo.ass", @"/tmp",vCID];
        
        float mq = 6.75*[width doubleValue]/[height doubleValue]-4;
        if(mq < 3.0){
            mq = 3.0;
        }
        if(mq > 8.0){
            mq = 8.0;
        }
        
        danmaku2ass([filePath cStringUsingEncoding:NSUTF8StringEncoding],
                    [OutFile cStringUsingEncoding:NSUTF8StringEncoding],
                    [width intValue],[height intValue],
                    "Heiti SC",(int)[height intValue]/25.1,
                    [[NSString stringWithFormat:@"%.2f",[self getSettings:@"transparency"]] floatValue],
                    mq,5);
        
        NSLog(@"Comment converted to %@",OutFile);
        
        [self applyRegexCommentFilter:OutFile];
        
        return OutFile;
    }else{
        return @"";
    }
}

- (void) applyRegexCommentFilter:(NSString *)filename
{
    [self.textTip setStringValue:@"正在应用屏蔽规则"];
    
    NSString *blocks = [[NSUserDefaults standardUserDefaults] objectForKey:@"blockKeywords"];
    
    if(![blocks length]){
        return;
    }
    
    NSString *blockRegex = [NSString stringWithFormat:@"Dialogue.*\\}.*[%@].*",blocks];
    
    NSError *error = nil;
    NSString *str = [[NSString alloc] initWithContentsOfFile:filename encoding:NSUTF8StringEncoding error:nil];
    
    if(error){
        return;
    }
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:blockRegex options:NSRegularExpressionCaseInsensitive error:&error];
    
    if(error){
        return;
    }
    
    NSString *modifiedString = [regex stringByReplacingMatchesInString:str options:0 range:NSMakeRange(0, [str length]) withTemplate:@""];
    [modifiedString writeToFile:filename atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

- (void) handleEvent:(mpv_event *)event
{
    switch (event->event_id) {
        case MPV_EVENT_SHUTDOWN: {
            mpv_detach_destroy(mpv);
            mpv = NULL;
            NSLog(@"Stopping player");
            break;
        }
            
        case MPV_EVENT_LOG_MESSAGE: {
            struct mpv_event_log_message *msg = (struct mpv_event_log_message *)event->data;
            NSLog(@"[%s] %s: %s", msg->prefix, msg->level, msg->text);
            break;
        }
            
        case MPV_EVENT_VIDEO_RECONFIG: {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSArray *subviews = [self->wrapper subviews];
                if ([subviews count] > 0) {
                    // mpv's events view
                    NSView *eview = [self->wrapper subviews][0];
                    [self->w makeFirstResponder:eview];
                }
            });
            break;
        }
        
        case MPV_EVENT_START_FILE:{
            if([[[NSUserDefaults standardUserDefaults] objectForKey:@"FirstPlayed"] length] < 1){
                [[NSUserDefaults standardUserDefaults]  setObject:@"yes" forKey:@"FirstPlayed"];
                [self.textTip setStringValue:@"正在创建字体缓存"];
                [self.subtip setStringValue:@"首次播放需要最多 2 分钟来建立缓存\n请不要关闭窗口"];
            }else{
                [self.textTip setStringValue:@"正在缓冲"];
            }
            break;
        }
            
        case MPV_EVENT_PLAYBACK_RESTART: {
            self.loadingImage.animates = false;
            isPlaying = YES;
            if(isTesting){
                const char *args[] = {"stop", NULL};
                mpv_command(mpv, args);
                const char *args2[] = {"quit", NULL};
                mpv_command(mpv, args2);
            }
            break;
        }
        
        case MPV_EVENT_END_FILE:{
            [self.textTip setStringValue:@"播放完成"];
            break;
        }
            
        default:
            NSLog(@"Player Event: %s", mpv_event_name(event->event_id));
    }
}

- (void) readEvents
{
    dispatch_async(queue, ^{
        while (mpv) {
            mpv_event *event = mpv_wait_event(mpv, 0);
            if (event->event_id == MPV_EVENT_NONE)
                break;
            [self handleEvent:event];
        }
    });
}

- (float) getSettings:(NSString *) key
{
    NSUserDefaults *settingsController = [NSUserDefaults standardUserDefaults];
    if([key isEqualToString:@"quality"]){
        
        NSString *quality = [settingsController objectForKey:@"quality"];
        if([quality isEqualToString:@"高清"]){
            return 3;
        }else if ([quality isEqualToString:@"标清"]){
            return 2;
        }else if([quality isEqualToString:@"低清"]){
            return 1;
        }else{
            return 4;
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

@end

@interface PlayerWindow : NSWindow <NSWindowDelegate>

-(void)keyDown:(NSEvent*)event;

@end

@implementation PlayerWindow{
    
}

BOOL paused = NO;

-(void)keyDown:(NSEvent*)event
{
    if(!mpv){
        return;
    }
    switch( [event keyCode] ) {
        case 125:{
            [NSSound decreaseSystemVolumeBy:0.05];
            break;
        }
        case 126:{
            [NSSound increaseSystemVolumeBy:0.05];
            break;
        }
        case 124:{
            const char *args[] = {"seek", "5" ,NULL};
            mpv_command(mpv, args);
            break;
        }
        case 123:{
            const char *args[] = {"seek", "-5" ,NULL};
            mpv_command(mpv, args);
            break;
        }
        case 49:{
            if(strcmp(mpv_get_property_string(mpv,"pause"),"no")){
                mpv_set_property_string(mpv,"pause","no");
            }else{
                mpv_set_property_string(mpv,"pause","yes");
            }
            break;
        }
        case 36:{
            [postCommentButton performClick:nil];
            break;
        }
        default:
            NSLog(@"Key pressed: %hu", [event keyCode]);
            break;
    }
}

- (void) mpv_stop
{
    if (mpv) {
        const char *args[] = {"stop", NULL};
        mpv_command(mpv, args);
    }
}

- (void) mpv_quit
{
    if (mpv) {
        const char *args[] = {"quit", NULL};
        mpv_command(mpv, args);
    }
}

- (BOOL)windowShouldClose:(id)sender{
    isCancelled = true;
    [self mpv_stop];
    [self mpv_quit];
    parsing = false;
    return YES;
}

@end