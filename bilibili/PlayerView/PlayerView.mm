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
#import "MediaInfoDLL.h"
#import <IOKit/pwr_mgt/IOPMLib.h>

#include "../CommentConvert/danmaku2ass.hpp"
#include <stdio.h>
#include <stdlib.h>
#include <sstream>

#import "Common.hpp"
extern NSString *APIKey;
extern NSString *APISecret;
NSWindow *LastWindow;

mpv_handle *mpv;
dispatch_queue_t queue;
BOOL isCancelled;
BOOL isPlaying;


//IOPMAssertionID assertionID;

static inline void check_error(int status)
{
    if (status < 0) {
        NSLog(@"mpv API error: %s", mpv_error_string(status));
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"Fatal Error\nPlease open console.app and upload logs to GitHub or send email to typcncom@gmail.com"];
        [alert runModal];
    }
}

@interface PlayerView (){
    NSWindow *w;
    NSView *wrapper;
    NSView *PlayerControlView;
    __weak IBOutlet NSView *PlayerView;
    __weak IBOutlet NSView *LoadingView;
    NSTimer *hideCursorTimer;
}

@end


@implementation PlayerView

- (BOOL)canBecomeMainWindow { return YES; }
- (BOOL)canBecomeKeyWindow { return YES; }

static void wakeup(void *context) {
    if(isCancelled){
        return;
    }
    if(context){
        PlayerView *a = (__bridge PlayerView *) context;
        if(a){
            [a readEvents];
        }
    }
}

- (NSString *) md5:(NSString *) input
{
    const char *cStr = [input UTF8String];
    unsigned char digest[16];
    CC_MD5( cStr, (CC_LONG)strlen(cStr), digest ); // This is the md5 call
    
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x", digest[i]];
    
    return  output;
    
}


- (NSString *) randomStringWithLength: (int) len {
    NSString *letters = @"abcdefghijklmnopqrstuvwxyz0123456789";
    NSMutableString *randomString = [NSMutableString stringWithCapacity: len];
    
    for (int i=0; i<len; i++) {
        [randomString appendFormat: @"%C", [letters characterAtIndex: arc4random_uniform([letters length])]];
    }
    
    return randomString;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    LastWindow = [[NSApplication sharedApplication] keyWindow];
    [LastWindow resignKeyWindow];
    [LastWindow miniaturize:self];
    w = self.view.window;
    [w makeKeyAndOrderFront:NSApp];
    [w makeMainWindow];
    
    // Load Player Control View
//    NSArray *tlo;
//    BOOL c = [[NSBundle mainBundle] loadNibNamed:@"PlayerControl" owner:self topLevelObjects:&tlo];
//    if(c){
//        for(int i=0;i<tlo.count;i++){
//            NSString *cname = [tlo[i] className];
//            if([cname isEqualToString:@"PlayerControlView"]){
//                PlayerControlView = tlo[i];
//            }
//        }
//    }

    [self.loadingImage setAnimates:YES];
    [self LoadVideo];
}

- (void)LoadVideo{
    //IOPMAssertionCreateWithName(kIOPMAssertionTypeNoDisplaySleep,
    //                            kIOPMAssertionLevelOn, CFSTR("com.typcn.videoplayback"), &assertionID);
    
    if([vCID isEqualToString:@"LOCALVIDEO"]){
        [[[NSApplication sharedApplication] keyWindow] performClose:self];
    }
    
    
    double Wheight = [[NSUserDefaults standardUserDefaults] doubleForKey:@"playerheight"];
    double Wwidth = [[NSUserDefaults standardUserDefaults] doubleForKey:@"playerwidth"];
    
    NSString *cookie = [[NSUserDefaults standardUserDefaults] objectForKey:@"cookie"];
    
    NSString *res = [NSString stringWithFormat:@"%dx%d",(int)Wwidth,(int)Wheight];
    
    NSLog(@"playerWidth: %f Height: %f",Wwidth,Wheight);
    if(Wwidth < 300 || Wheight < 300){
        NSLog(@"Size set to fillscreen");
        NSRect rect = [[NSScreen mainScreen] visibleFrame];
        NSNumber *viewHeight = [NSNumber numberWithFloat:rect.size.height];
        NSNumber *viewWidth = [NSNumber numberWithFloat:rect.size.width];
        res = [NSString stringWithFormat:@"%dx%d",[viewWidth intValue],[viewHeight intValue]];
        [self.view setFrame:rect];
    }else{
        NSRect frame = [self.view.window frame];
        frame.size = NSMakeSize(Wwidth, Wheight);
        [self.view setFrame:frame];
    }
    
    /* Add Player Control view */
    
//    NSRect rect = PlayerControlView.frame;
//    [PlayerControlView setFrame:NSMakeRect(rect.origin.x,
//                                           rect.origin.y,
//                                           self.view.frame.size.width * 0.8,
//                                           rect.size.height)];
//    [PlayerControlView setFrameOrigin:
//     NSMakePoint(
//                 (NSWidth([self.view bounds]) - NSWidth([PlayerControlView frame])) / 2,
//                 20
//                 )];
//    
//    [self.view setWantsLayer:YES];
//    [PlayerControlView setHidden:YES];
    //[self.view addSubview:PlayerControlView positioned:NSWindowAbove relativeTo:nil];
    
    /* End Adding Player Control */
    
    hideCursorTimer = [NSTimer scheduledTimerWithTimeInterval:0.3 target:self selector:@selector(hideCursor:) userInfo:nil repeats:YES];
    NSLog(@"Playerview load success");
    self->wrapper = PlayerView;
    
    isCancelled = false;
    queue = dispatch_queue_create("mpv", DISPATCH_QUEUE_SERIAL);
    dispatch_async(queue, ^{
        
        int usePluginParser = 0;
        
        NSString *hwid = [[NSUserDefaults standardUserDefaults] objectForKey:@"hwid"];
        if([hwid length] < 4){
            hwid  = [self randomStringWithLength:16];
            [[NSUserDefaults standardUserDefaults] setObject:hwid forKey:@"hwid"];
        }
        
        NSString *baseAPIUrl = @"http://interface.bilibili.com/playurl?platform=android&_device=android&_hwid=%@&_aid=%@&_tid=0&_p=%@&_down=0&cid=%@&quality=%d&otype=json&appkey=%@&type=%@&sign=%@";
        
        if([vCID isEqualToString:@"LOCALVIDEO"]){
            if([vUrl length] > 5){
                NSDictionary *VideoInfoJson = [self getVideoInfo:vUrl];
                NSNumber *width = [VideoInfoJson objectForKey:@"width"];
                NSNumber *height = [VideoInfoJson objectForKey:@"height"];
                NSString *commentFile = @"/NotFound";
                if([cmFile length] > 5){
                    commentFile = [self getComments:width :height];
                }
                if([subFile length] > 5){
                    [self addSubtitle:subFile withCommentFile:commentFile];
                }
                [self PlayVideo:commentFile :res];
            }else{
                dispatch_async(dispatch_get_main_queue(), ^(void){
                    [self.view.window performClose:self];
                });
            }
            return;
        }else if([vUrl containsString:@"live.bilibili"]){
            baseAPIUrl = @"http://live.bilibili.com/api/playurl?platform=android&_appver=406001&_buvid=%@infoc&_device=android&_hwid=%@&_aid=0&_tid=0&_p=%@&_down=0&cid=%@&quality=1&otype=json&appkey=%@&type=mp4&sign=%@";
            vAID = @"LIVE";
            vPID = @"LIVE";
        }else{
            NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\/video\\/av(\\d+)(\\/index.html|\\/index_(\\d+).html)?" options:NSRegularExpressionCaseInsensitive error:nil];
            
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
            NSLog(@"AV: %@, CID: %@, PID: %@",vAID,vCID,vPID);
        }
        
        [self.textTip setStringValue:NSLocalizedString(@"正在解析视频地址", nil)];
        
        // Get Sign
        
        
        int quality = [self getSettings:@"quality"];
        int isMP4 = [self getSettings:@"playMP4"];
        NSString *type = @"flv";
        if(isMP4 == 1){
            type = @"mp4";
        }
    getUrl: NSLog(@"Getting video url");
        
        NSString *param = [NSString stringWithFormat:@"platform=android&_device=android&_hwid=%@&_aid=%@&_tid=0&_p=%@&_down=0&cid=%@&quality=%d&otype=json&appkey=%@&type=%@%@",hwid,vAID,vPID,vCID,quality,APIKey,type,APISecret];
        NSString *uuid = [[NSUUID UUID] UUIDString];
        NSString *rndhwid = [self randomStringWithLength:16];
        
        if([vPID isEqualToString:@"LIVE"]){
            NSLog(@"Generate LIVE Params");
            param = [NSString stringWithFormat:@"platform=android&_appver=406001&_buvid=%@infoc&_device=android&_hwid=%@&_aid=0&_tid=0&_p=%@&_down=0&cid=%@&quality=1&otype=json&appkey=%@&type=mp4&sign=%@",uuid,rndhwid,vCID,vCID,APIKey,APISecret];
        }
        
        NSString *sign = [self md5:[param stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        
        // Get Playback URL
        
        NSString *pbUrl;
        
        if([vPID isEqualToString:@"LIVE"]){
            NSLog(@"Generate LIVE APIUrl");
            pbUrl = [NSString stringWithFormat:baseAPIUrl,uuid,rndhwid,vCID,vCID,APIKey,sign];
        }else{
            pbUrl = [NSString stringWithFormat:baseAPIUrl,hwid,vAID,vPID,vCID,quality,APIKey,type,sign];
        }
        
        NSURL* URL = [NSURL URLWithString:pbUrl];
        NSLog(@"APIURL %@",[URL absoluteString]);
        NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:URL];
        request.HTTPMethod = @"GET";
        request.timeoutInterval = 5;
        
        NSUserDefaults *settingsController = [NSUserDefaults standardUserDefaults];
        NSString *xff = [settingsController objectForKey:@"xff"];
        if([xff length] > 4){
            [request setValue:xff forHTTPHeaderField:@"X-Forwarded-For"];
            [request setValue:xff forHTTPHeaderField:@"Client-IP"];
        }
        [request setValue:cookie forHTTPHeaderField:@"Cookie"];
        [request setValue:@"Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/34.0.1847.116 Safari/537.36" forHTTPHeaderField:@"User-Agent"];
        [request setValue:@"trailers" forHTTPHeaderField:@"TE"];
        
        NSURLResponse * response = nil;
        NSError * error = nil;
        NSData * videoAddressJSONData = [NSURLConnection sendSynchronousRequest:request
                                                              returningResponse:&response
                                                                          error:&error];
        if(error || !videoAddressJSONData){
            NSLog(@"API ERROR:%@",error);
            dispatch_async(dispatch_get_main_queue(), ^{
                NSAlert *alert = [[NSAlert alloc] init];
                [alert setMessageText:NSLocalizedString(@"视频解析出现错误，返回内容为空，可能的原因：\n1. 您的网络连接出现故障\n2. Bilibili API 服务器出现故障\n请尝试以下步骤：\n1. 更换网络连接或重启电脑\n2. 可能触发了频率限制，请更换 IP 地址\n\n如果您确信是软件问题，请点击帮助 -- 反馈", nil)];
                [alert runModal];
            });
            return;
        }

    parseJSON:
        if(usePluginParser){
            NSLog(@"Use plugin parser");
            VP_Plugin *plugin = [[PluginManager sharedInstance] Get:@"bilibili-resolveAddr"];
            if(plugin){
                int intcid = [vCID intValue];
                NSDictionary *o = @{
                                    @"cid": [NSNumber numberWithInt:intcid] ,
                                    @"quality": [NSNumber numberWithInt:quality],
                                    @"isMP4": [NSNumber numberWithInt:isMP4],
                                    @"url": vUrl
                                    };
                NSData * d= [NSJSONSerialization dataWithJSONObject:o options:NSJSONWritingPrettyPrinted error:nil];
                NSString *jsonString = [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
                NSString *vjson = [plugin processEvent:@"bilibili-resolveAddr" :jsonString];
                if(vjson && [vjson length] > 5){
                    videoAddressJSONData = [vjson dataUsingEncoding:NSUTF8StringEncoding];
                    NSLog(@"pluginParse OK");
                }else{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSAlert *alert = [[NSAlert alloc] init];
                        [alert setMessageText:NSLocalizedString(@"视频解析出现错误，且云端动态解析模块也无法解析，可能该版本已失效，请升级到最新版，或重新启动软件再试。", nil)];
                        [alert runModal];
                    });
                }
            }else{
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSAlert *alert = [[NSAlert alloc] init];
                    [alert setMessageText:NSLocalizedString(@"视频解析出现错误，且云端动态解析模块未安装，请升级到最新版，或重新启动软件再试。", nil)];
                    [alert runModal];
                });
                return;
            }
        }
        
        NSError *jsonError;
        NSMutableDictionary *videoResult = [NSJSONSerialization JSONObjectWithData:videoAddressJSONData options:NSJSONWritingPrettyPrinted error:&jsonError];
        
        if(jsonError){
            NSLog(@"JSON ERROR:%@",jsonError);
            dispatch_async(dispatch_get_main_queue(), ^{
                NSAlert *alert = [[NSAlert alloc] init];
                [alert setMessageText:NSLocalizedString(@"视频解析出现错误，JSON 解析失败，可能的原因：\n1. 您的网络被劫持\n2. Bilibili 服务器出现故障\n请尝试以下步骤：\n1. 尝试更换网络\n2. 过一会再试\n\n如果您确信是软件问题，请点击帮助 -- 反馈", nil)];
                [alert runModal];
            });
            return;
        }
        
        NSArray *dUrls = [videoResult objectForKey:@"durl"];
        
        if([dUrls count] == 0){
            if([type isEqualToString:@"mp4"]){
                type = @"flv";
                dispatch_async(dispatch_get_main_queue(), ^{
                [self.textTip setStringValue:NSLocalizedString(@"正在尝试重新解析", nil)];
                });
                goto getUrl;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
            [self.textTip setStringValue:NSLocalizedString(@"视频无法解析", nil)];
            });
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
        
        if([firstVideo isEqualToString:@"http://v.iask.com/v_play_ipad.php?vid=false"]){
            type = @"flv";
            goto getUrl;
        }
        
        if([firstVideo containsString:@"static.hdslb"]){
            usePluginParser = 1;
            goto parseJSON;
        }
        
        if(isCancelled){
            NSLog(@"Unloading");
            return;
        }
        
        [self writeHistory];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.textTip setStringValue:NSLocalizedString(@"正在获取视频信息", nil)];
        });
            
        NSLog(@"FirstVideo:%@",firstVideo);
        
        int usingBackup = 0;
        
        NSLog(@"Start read video info");
    GetInfo:NSDictionary *VideoInfoJson = [self getVideoInfo:firstVideo];
        NSLog(@"Video info got");
        NSNumber *width = [VideoInfoJson objectForKey:@"width"];
        NSNumber *height = [VideoInfoJson objectForKey:@"height"];
        
        if([height intValue] < 100){
            if(!BackupUrls){
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.textTip setStringValue:NSLocalizedString(@"读取视频失败，可能视频源已失效", nil)];
                });
            }else{
                usingBackup++;
                NSString *backupVideoUrl = [BackupUrls objectAtIndex:usingBackup];
                if([backupVideoUrl length] > 0){
                    firstVideo = backupVideoUrl;
                    vUrl = backupVideoUrl;
                    NSLog(@"Timeout! Change to backup url: %@",vUrl);
                    goto GetInfo;
                }else{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.textTip setStringValue:NSLocalizedString(@"读取视频失败，视频服务器故障", nil)];
                    });
                }
            }
        }
        
        NSString *fvHost = [[NSURL URLWithString:firstVideo] host];
        if([fvHost length] > 0){
            vTitle = [NSString stringWithFormat:NSLocalizedString(@"%@ - 服务器: %@", nil),vTitle,fvHost];
        }
        
        if(isCancelled){
            NSLog(@"Unloading");
            return;
        }
        
        if(!jsonError){
            // Get Comment
            if([vUrl containsString:@"live_"]){
                [self PlayVideo:@"" :res];
            }else{
                NSString *commentFile = [self getComments:width :height];
                [self PlayVideo:commentFile :res];
            }
            
        }else{
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.textTip setStringValue:NSLocalizedString(@"视频信息读取失败", nil)];
            });
            
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
    [self.textTip setStringValue:NSLocalizedString(@"正在载入视频", nil)];
    
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
    check_error(mpv_set_option_string(mpv, "script-opts", "osc-layout=box,osc-seekbarstyle=bar"));
    check_error(mpv_set_option_string(mpv, "user-agent", [@"Mozilla/5.0 (Windows NT 6.1; WOW64; rv:6.0.2) Gecko/20100101 Firefox/6.0.2 Fengfan/1.0" cStringUsingEncoding:NSUTF8StringEncoding]));
    check_error(mpv_set_option_string(mpv, "framedrop", "vo"));
    check_error(mpv_set_option_string(mpv, "hr-seek", "yes"));
    //check_error(mpv_set_option_string(mpv, "keep-open", "yes"));
    
    int disableKeepAspect = [self getSettings:@"disableKeepAspect"];
    if(disableKeepAspect == 1){
        check_error(mpv_set_option_string(mpv, "keepaspect", "no"));
    }
    if(![vCID isEqualToString:@"LOCALVIDEO"]){
        check_error(mpv_set_option_string(mpv, "force-media-title", [vTitle cStringUsingEncoding:NSUTF8StringEncoding]));
    }
    
    int enableHW = [self getSettings:@"enableHW"];
    if(enableHW){
        check_error(mpv_set_option_string(mpv, "hwdec", "videotoolbox"));
        check_error(mpv_set_option_string(mpv, "sub-fps", "60"));
        check_error(mpv_set_option_string(mpv, "display-fps", "60"));
        check_error(mpv_set_option_string(mpv, "demuxer-rawvideo-fps", "60"));
    }else{
        check_error(mpv_set_option_string(mpv, "vf", "lavfi=\"fps=fps=60:round=down\""));
    }
    
    bool loadComment = true;
    if(![vUrl containsString:@"live_"]){
        
    }else{
        loadComment = false;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.showLiveChat performClick:nil];
        });
    }
    
    if([commentFile isEqualToString:@"/NotFound"]){
        loadComment = false;
    }
    
    if(loadComment){
        check_error(mpv_set_option_string(mpv, "sub-ass", "yes"));
        check_error(mpv_set_option_string(mpv, "sub-file", [commentFile cStringUsingEncoding:NSUTF8StringEncoding]));
    }
    
    // request important errors
    check_error(mpv_request_log_messages(mpv, "warn"));
    
    check_error(mpv_initialize(mpv));
    
    // Register to be woken up whenever mpv generates new events.
    mpv_set_wakeup_callback(mpv, wakeup, (__bridge void *) self);
    
    // Load the indicated file
    const char *cmd[] = {"loadfile", [vUrl cStringUsingEncoding:NSUTF8StringEncoding], NULL};
    check_error(mpv_command(mpv, cmd));
}

- (NSDictionary *) getVideoInfo:(NSString *)url{

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

- (void) writeHistory{
    NSURL* URL = [NSURL URLWithString:[NSString stringWithFormat:@"http://interface.bilibili.com/player?id=cid:%@&aid=%@",vCID,vAID]];
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:URL];
    request.HTTPMethod = @"GET";
    request.timeoutInterval = 5;
    
    NSUserDefaults *settingsController = [NSUserDefaults standardUserDefaults];
    long isDisabled = [settingsController integerForKey:@"disableWritePlayHistory"];
    if(isDisabled){
        return;
    }
    NSString *xff = [settingsController objectForKey:@"xff"];
    NSString *cookie = [settingsController objectForKey:@"cookie"];
    if([xff length] > 4){
        [request setValue:xff forHTTPHeaderField:@"X-Forwarded-For"];
        [request setValue:xff forHTTPHeaderField:@"Client-IP"];
    }
    [request setValue:cookie forHTTPHeaderField:@"Cookie"];
    [request setValue:@"Mozilla/5.0 (Windows NT 6.1; WOW64; rv:6.0.2) Gecko/20100101 Firefox/6.0.2 Fengfan/1.0" forHTTPHeaderField:@"User-Agent"];
    NSURLConnection* connection = [NSURLConnection connectionWithRequest:request delegate:nil];
    [connection start];
}

- (NSString *) getComments:(NSNumber *)width :(NSNumber *)height {

    NSString *resolution = [NSString stringWithFormat:@"%@x%@",width,height];
    NSLog(@"Video resolution: %@",resolution);
    [self.textTip setStringValue:NSLocalizedString(@"正在读取弹幕", nil)];
    
    
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
        NSString *fontName = [[NSUserDefaults standardUserDefaults] objectForKey:@"fontName"];
        if(!fontName || [fontName length] < 1){
            fontName = @"STHeiti";
        }
        
        NSString  *filePath = [NSString stringWithFormat:@"%@%@.cminfo.xml", NSTemporaryDirectory(),vCID];
        
        if(LC){
            NSString *correctString = [[NSString alloc] initWithData:urlData encoding:NSUTF8StringEncoding];
            urlData = [correctString dataUsingEncoding:NSUTF8StringEncoding];
        }
        
        [urlData writeToFile:filePath atomically:YES];
        
        NSString *OutFile = [NSString stringWithFormat:@"%@%@.cminfo.ass", NSTemporaryDirectory(),vCID];
        
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
        
        bilibiliParser *p = new bilibiliParser;
        
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
        
        p->SetFile([filePath cStringUsingEncoding:NSUTF8StringEncoding], [OutFile cStringUsingEncoding:NSUTF8StringEncoding]);
        p->SetRes([width intValue], [height intValue]);
        p->SetFont([fontName cStringUsingEncoding:NSUTF8StringEncoding], (int)[height intValue]/fontsize);
        p->SetDuration(mq,5);
        p->SetAlpha([[NSString stringWithFormat:@"%.2f",[self getSettings:@"transparency"]] floatValue]);
        p->Convert(disableBottom);
        
        NSLog(@"Comment converted to %@",OutFile);
        
        
        
        return OutFile;
    }else{
        return @"";
    }
}

- (void) addSubtitle:(NSString *)filename withCommentFile:(NSString *)comment
{
    [self.textTip setStringValue:NSLocalizedString(@"正在合并弹幕字幕", nil)];
    
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
                [PlayerControlView setHidden:NO];
            });
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
            isPlaying = YES;
            break;
        }
        
        case MPV_EVENT_END_FILE:{
            isPlaying = NO;
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
            isPlaying = YES;
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
            if(!event)
                break;
            if (event->event_id == MPV_EVENT_NONE)
                break;
            if(isCancelled)
                break;
            [self handleEvent:event];
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

- (void)hideCursor:(id)sender {
    if(mpv) {
        if (CGEventSourceSecondsSinceLastEventType(kCGEventSourceStateCombinedSessionState, kCGEventMouseMoved) >= 1) {
            [NSCursor setHiddenUntilMouseMoves:YES];
        }
    }
}

- (void)viewWillDisappear {
    [hideCursorTimer invalidate];
    hideCursorTimer = nil;
}

@end

@implementation PlayerWindow{
    
}

@synthesize postCommentWindowC;

BOOL paused = NO;
BOOL hide = NO;
BOOL obServer = NO;
BOOL isFirstCall = YES;
BOOL shiftKeyPressed = NO;

- (NSArray *)customWindowsToEnterFullScreenForWindow:(NSWindow *)window{
    return nil;
}

- (void)window:(NSWindow *)window
startCustomAnimationToEnterFullScreenWithDuration:(NSTimeInterval)duration{
    
}

- (NSSize)windowWillResize:(NSWindow *)sender
                    toSize:(NSSize)frameSize{
    if(!obServer){
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidResize:) name:NSWindowDidResizeNotification object:self];
        obServer = YES;
    }else{
        if(mpv){
            dispatch_async(queue, ^{
                if(strcmp(mpv_get_property_string(mpv,"pause"),"yes")){
                    mpv_set_property_string(mpv,"pause","yes");
                }
            });
        }
    }
    // Save window size
    [[NSUserDefaults standardUserDefaults] setDouble:frameSize.width forKey:@"playerwidth"];
    [[NSUserDefaults standardUserDefaults] setDouble:frameSize.height forKey:@"playerheight"];
    
    return frameSize;
}
- (void)windowDidResize:(NSNotification *)notification{
    [self performSelector:@selector(Continue) withObject:nil afterDelay:1.0];
}

- (void)Continue{
    if(mpv && !isFirstCall){
        dispatch_async(queue, ^{
            if(strcmp(mpv_get_property_string(mpv,"pause"),"no")){
                mpv_set_property_string(mpv,"pause","no");
            }
        });
    }else{
        isFirstCall = NO;
    }
}

- (void)flagsChanged:(NSEvent *) event {
    shiftKeyPressed = ([event modifierFlags] & NSShiftKeyMask) != 0;
}

-(void)keyDown:(NSEvent*)event
{
    if(!mpv){
        return;
    }
    switch( [event keyCode] ) {
        case 125:{ // ⬇️
            [NSSound decreaseSystemVolumeBy:0.05];
            break;
        }
        case 126:{ // ⬆️
            [NSSound increaseSystemVolumeBy:0.05];
            break;
        }
        case 124:{ // 👉
            dispatch_async(queue, ^{
                const char *args[] = {"seek", shiftKeyPressed?"1":"5" ,NULL};
                mpv_command(mpv, args);
            });
            break;
        }
        case 123:{ // 👈
            dispatch_async(queue, ^{
                const char *args[] = {"seek", shiftKeyPressed?"-1":"-5" ,NULL};
                mpv_command(mpv, args);
            });
            break;
        }
        case 49:{ // Space
            dispatch_async(queue, ^{
                if(strcmp(mpv_get_property_string(mpv,"pause"),"no")){
                    mpv_set_property_string(mpv,"pause","no");
                }else{
                    mpv_set_property_string(mpv,"pause","yes");
                 }
            });
            break;
        }
        case 36:{ // Enter
            if(isPlaying){
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
        case 7:{ // X key to loop
            dispatch_async(queue, ^{
                mpv_set_option_string(mpv, "loop", "inf");
            });
            break;
        }
        case 3:{ // Command+F key to toggle fullscreen
            NSUInteger flags = [[NSApp currentEvent] modifierFlags];
            if ((flags & NSCommandKeyMask)) {
                [self toggleFullScreen:self];
            }
            
            break;
        }
        default: // Unknow
            NSLog(@"Key pressed: %hu", [event keyCode]);
            break;
    }
}

- (void) mpv_stop
{
    if (mpv) {
        dispatch_async(queue, ^{
            const char *args[] = {"stop", NULL};
            mpv_command(mpv, args);
        });
    }
}

- (void) mpv_quit
{
    if (mpv) {
        dispatch_async(queue, ^{
            const char *args[] = {"quit", NULL};
            mpv_command(mpv, args);
        });
    }
}

- (BOOL)windowShouldClose:(id)sender{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"LastPlay"];
    NSLog(@"Removing lastplay url");
    isPlaying = NO;
//    if(assertionID){
//        IOPMAssertionRelease(assertionID);
//    }
    isCancelled = true;
    if(obServer){
        [[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidResizeNotification object:self];
        obServer = NO;
    }
    dispatch_async(queue, ^{
        if(mpv){
            mpv_set_wakeup_callback(mpv, NULL,NULL);
        }
    });
    dispatch_async(dispatch_get_main_queue(), ^{
        [self mpv_stop];
        [self mpv_quit];
        [postCommentWindowC close];
        if([browser tabCount] > 0){
            [LastWindow makeKeyAndOrderFront:nil];
        }
    });
    parsing = false;
    return YES;
}

@end