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

#include <stdio.h>
#include <stdlib.h>
#include <sstream>

extern NSString *vUrl;
extern NSString *vCID;
extern NSString *userAgent;
extern BOOL parsing;

mpv_handle *mpv;

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

- (void)viewWillLoad {

}

static void wakeup(void *context) {
    if(context){
        @try {
            PlayerView *a = (__bridge PlayerView *) context;
            if(a){
                [a readEvents];
            }
        }
        @catch (NSException * e) {
            
        }
        

    }
}


- (void)viewDidLoad {
    NSLog(@"Success");
    self->wrapper = [self view];

    [self.view.window makeKeyWindow];
    
    queue = dispatch_queue_create("mpv", DISPATCH_QUEUE_SERIAL);
    dispatch_async(queue, ^{
        
        [self.textTip setStringValue:@"正在解析视频地址"];
        
        // Parse Video URL
        

        NSURL* URL = [NSURL URLWithString:[NSString stringWithFormat:@"http://interface.bilibili.com/playurl?appkey=a&cid=%@&quality=4",vCID]];
        NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:URL];
        request.HTTPMethod = @"GET";
        request.timeoutInterval = 5;
        
        
        [request addValue:userAgent forHTTPHeaderField:@"User-Agent"];
        
        NSURLResponse * response = nil;
        NSError * error = nil;
        NSData * videoAddressXmlData = [NSURLConnection sendSynchronousRequest:request
                                              returningResponse:&response
                                                          error:&error];
        NSString *xml = [[NSString alloc]initWithData:videoAddressXmlData encoding:NSUTF8StringEncoding];
        
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"<durl>.*?<url><!\\[CDATA\\[(.*?)\\]\\]></url>.*?</durl>" options:NSRegularExpressionDotMatchesLineSeparators error:nil];
        NSArray *matches = [regex matchesInString:xml options:0 range:NSMakeRange(0, [xml length])];

        if([matches count] == 0){
            [self.textTip setStringValue:@"视频源不支持"];
            return;
        }
        
        NSString *firstVideo;
        
        for (NSTextCheckingResult *match in matches) {
            NSRange matchRange = [match rangeAtIndex:1];
            if([matches count] == 1){
                vUrl = [xml substringWithRange:matchRange];
                firstVideo = vUrl;
            }else{
                NSString *tmp = [xml substringWithRange:matchRange];
                if(!firstVideo){
                    firstVideo = tmp;
                    vUrl = [NSString stringWithFormat:@"%@%@%lu%@%@%@", @"edl://", @"%",(unsigned long)[tmp length], @"%" , tmp ,@";"];
                }else{
                    vUrl = [NSString stringWithFormat:@"%@%@%lu%@%@%@",   vUrl   , @"%",(unsigned long)[tmp length], @"%" , tmp ,@";"];
                }
                
            }
        }
        
        // ffprobe
        [self.textTip setStringValue:@"正在获取视频信息"];
        NSPipe *pipe = [NSPipe pipe];
        NSFileHandle *file = pipe.fileHandleForReading;
        
        NSTask *task = [[NSTask alloc] init];
        task.launchPath = [[NSBundle mainBundle] pathForResource:@"ffprobe" ofType:@""];
        task.arguments = @[@"-print_format",@"json",@"-loglevel",@"repeat+error",@"-icy",@"0",@"-select_streams",@"v",@"-show_streams",@"-user-agent",@"Mozilla/5.0 (Windows NT 6.1; WOW64; rv:6.0.2) Gecko/20100101 Firefox/6.0.2 Fengfan/1.0",@"--",firstVideo];
        task.standardOutput = pipe;
        
        [task launch];
        
        NSData *data = [file readDataToEndOfFile];
        [file closeFile];
        
        NSError *jsonError;
        NSMutableDictionary *d = [NSJSONSerialization JSONObjectWithData:data options:NSJSONWritingPrettyPrinted error:&jsonError];
        
        if(!jsonError){
            
            NSDictionary *info = [[d objectForKey:@"streams"] objectAtIndex:0];
            NSNumber *width = [info objectForKey:@"width"];
            NSNumber *height = [info objectForKey:@"height"];
            NSString *resolution = [NSString stringWithFormat:@"%@x%@",width,height];
            NSLog(@"Video resolution: %@",resolution);
            
            // Get Comment
            [self.textTip setStringValue:@"正在读取弹幕"];
            
            NSString *stringURL = [NSString stringWithFormat:@"http://comment.bilibili.com/%@.xml",vCID];
            NSURL  *url = [NSURL URLWithString:stringURL];
            NSData *urlData = [NSData dataWithContentsOfURL:url];
            NSString *commentFile;
            if ( urlData )
            {
                NSString  *filePath = [NSString stringWithFormat:@"%@/%@.cminfo.xml", @"/tmp",vCID];
                [urlData writeToFile:filePath atomically:YES];
                
                NSPipe *pipe = [NSPipe pipe];

                NSString *OutFile = [NSString stringWithFormat:@"%@/%@.cminfo.ass", @"/tmp",vCID];
                
                NSString *fontSize = [NSString stringWithFormat:@"%f",(int)[height doubleValue]/21.6];
                
                float mq = 6.75*[width doubleValue]/[height doubleValue]-4;
                if(mq < 3.0){
                    mq = 3.0;
                }
                if(mq > 8.0){
                    mq = 8.0;
                }
                
                NSString *marquee = [NSString stringWithFormat:@"%f",mq];
                NSFileHandle *file = pipe.fileHandleForReading;
                NSTask *task = [[NSTask alloc] init];
                task.launchPath = [[NSBundle mainBundle] pathForResource:@"danmaku2ass/danmaku2ass" ofType:@""];
                task.arguments = @[@"-s",resolution,@"-o",OutFile,@"-fn",@"Heiti SC",@"-a",@"0.8",@"-fs",fontSize,@"-dm",marquee,filePath];
                task.standardOutput = pipe;
                
                [task launch];
                [file readDataToEndOfFile];
                [file closeFile];
                
                commentFile = OutFile;
            }
            
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
            NSLog(@"Video url : %@",vUrl);
            const char *cmd[] = {"loadfile", [vUrl cStringUsingEncoding:NSUTF8StringEncoding], NULL};
            check_error(mpv_command(mpv, cmd));
        }else{
            [self.textTip setStringValue:@"视频信息读取失败"];
            parsing = false;
            return;
        }
    });
    
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
        }
        
        case MPV_EVENT_START_FILE:{
            [self.textTip setStringValue:@"正在缓冲"];
        }
            
        case MPV_EVENT_PLAYBACK_RESTART: {
            double delayInSeconds = 20.0;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                 [self.textTip setStringValue:@"播放完成"];
            });
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

- (void)loadView {
    
    [self viewWillLoad];
    
    [super loadView];
    
    [self viewDidLoad];
    
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowWillClose:) name:NSWindowWillCloseNotification object:self.view.window];
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
    [self mpv_stop];
    [self mpv_quit];
    parsing = false;
    return YES;
}

@end