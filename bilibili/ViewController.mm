//
//  ViewController.m
//  bilibili
//
//  Created by TYPCN on 2015/3/30.
//  Copyleft 2015 TYPCN. All rights reserved.
//

#import "ViewController.h"
#import <Sparkle/Sparkle.h>
#import <CommonCrypto/CommonDigest.h>
#import "APIKey.h"

#include "aria2.hpp"

NSString *vUrl;
NSString *vCID;
NSString *userAgent;
NSWindow *currWindow;
NSMutableArray *downloaderObjects;
BOOL parsing = false;
BOOL isTesting;

@implementation ViewController

- (BOOL)canBecomeMainWindow { return YES; }
- (BOOL)canBecomeKeyWindow { return YES; }

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}
- (IBAction)playClick:(id)sender {
    vUrl = [self.urlField stringValue];
    NSLog(@"USER INPUT: %@",vUrl);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view.window setBackgroundColor:NSColor.whiteColor];
    self.view.layer.backgroundColor = CGColorCreateGenericRGB(255, 255, 255, 1.0f);
    currWindow = self.view.window;
    [self.view.window makeKeyWindow];
    NSRect rect = [[NSScreen mainScreen] visibleFrame];
    [self.view setFrame:rect];

    NSArray *TaskList = [[NSUserDefaults standardUserDefaults] arrayForKey:@"DownloadTaskList"];
    downloaderObjects = [TaskList copy];
}

@end

@implementation WebController{
    aria2::Session* session;
    aria2::SessionConfig config;
    bool ariainit;
}

+(NSString*)webScriptNameForSelector:(SEL)sel
{
    if(sel == @selector(checkForUpdates))
        return @"checkForUpdates";
    if(sel == @selector(showPlayGUI))
        return @"showPlayGUI";
    if(sel == @selector(playVideoByCID:))
        return @"playVideoByCID";
    if(sel == @selector(downloadVideoByCID:))
        return @"downloadVideoByCID";
    return nil;
}

+ (BOOL)isSelectorExcludedFromWebScript:(SEL)sel
{
    if(sel == @selector(checkForUpdates))
        return NO;
    if(sel == @selector(showPlayGUI))
        return NO;
    if(sel == @selector(playVideoByCID:))
        return NO;
    if(sel == @selector(downloadVideoByCID:))
        return NO;
    return YES;
}

- (void)checkForUpdates
{
    [[SUUpdater sharedUpdater] checkForUpdates:nil];
}

- (void)showPlayGUI
{
    [webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"$('#bofqi').html('%@');$('head').append('<style>%@</style>');",WebUI,WebCSS]];
}

- (void)playVideoByCID:(NSString *)cid
{
    if(parsing){
        return;
    }
    parsing = true;
    vCID = cid;
    vUrl = webView.mainFrameURL;
    NSLog(@"Video detected ! CID: %@",vCID);
    [self.switchButton performClick:nil];
}


int downloadEventCallback(aria2::Session* session, aria2::DownloadEvent event,
                          aria2::A2Gid gid, void* userData)
{
    switch(event) {
        case aria2::EVENT_ON_DOWNLOAD_COMPLETE:{

            break;
        }
        case aria2::EVENT_ON_DOWNLOAD_ERROR:{
            NSUserNotification *notification = [[NSUserNotification alloc] init];
            notification.title = @"Bilibili Client";
            notification.informativeText = @"下载失败";
            notification.soundName = NSUserNotificationDefaultSoundName;
            [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
            break;
        }
        default:
            return 0;
    }
    return 0;
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

- (void)downloadVideoByCID:(NSString *)cid
{
    if(!downloaderObjects){
        downloaderObjects = [[NSMutableArray alloc] init];
    }
    NSArray *filename = [webView.mainFrameTitle componentsSeparatedByString:@"_"];
    if(!ariainit){
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"注意：下载功能仅供测试，可能有各种 BUG，支持分段视频，默认保存在 Movies 文件夹。\n点击 文件->下载管理 来查看任务"];
        [alert runModal];
        config.downloadEventCallback = downloadEventCallback;
        session = aria2::sessionNew(aria2::KeyVals(), config);
        ariainit = true;
    }
    NSString *path = [NSString stringWithFormat:@"%@%@%@/",NSHomeDirectory(),@"/Movies/Bilibili/",[filename objectAtIndex:0]];
    aria2::changeGlobalOption(session, {{ "dir", [path cStringUsingEncoding:NSUTF8StringEncoding] }});
    aria2::changeGlobalOption(session, {{ "user-agent", "Mozilla/5.0 (Windows NT 6.1; WOW64; rv:6.0.2) Gecko/20100101 Firefox/6.0.2 Fengfan/1.0" }});
    aria2::KeyVals options;

    NSString *param = [NSString stringWithFormat:@"appkey=%@&otype=json&cid=%@&quality=4%@",APIKey,vCID,APISecret];
    NSString *sign = [self md5:[param stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
    NSURL* URL = [NSURL URLWithString:[NSString stringWithFormat:@"http://interface.bilibili.com/playurl?appkey=%@&otype=json&cid=%@&quality=4&sign=%@",APIKey,cid,sign]];
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
        return;
    }
    
    [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:NULL];
    
    NSString *commentUrl = [NSString stringWithFormat:@"http://comment.bilibili.com/%@.xml",cid];
    NSURL  *url = [NSURL URLWithString:commentUrl];
    NSData *data = [NSData dataWithContentsOfURL:url];
    [data writeToFile:[NSString stringWithFormat:@"%@%@.xml",path,cid] atomically:YES];
    
    if([[[[videoResult objectForKey:@"durl"] valueForKey:@"url"] className] isEqualToString:@"__NSCFString"]){
        NSString *tmp = [[videoResult objectForKey:@"durl"] valueForKey:@"url"];
        std::vector<std::string> uris = {[tmp cStringUsingEncoding:NSUTF8StringEncoding]};
        aria2::addUri(session, nullptr, uris, options);
    }else{
        for (NSDictionary *match in dUrls) {
            NSString *tmp = [match valueForKey:@"url"];
            std::vector<std::string> uris = {[tmp cStringUsingEncoding:NSUTF8StringEncoding]};
            aria2::addUri(session, nullptr, uris, options);
        }
    }
    
    NSDictionary *taskData = @{
                               @"name":[filename objectAtIndex:0],
                               @"status":@"正在准备",
                               };
    int index = (int)[downloaderObjects count];
    [downloaderObjects insertObject:taskData atIndex:index];
    
    dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSUserNotification *notification = [[NSUserNotification alloc] init];
        notification.title = @"Bilibili Client";
        notification.informativeText = @"下载已开始，通过 文件->下载管理 来查看进度";
        notification.soundName = NSUserNotificationDefaultSoundName;
        [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];

        for(;;) {
            int rv = aria2::run(session, aria2::RUN_ONCE);
            if(rv != 1) {
                break;
            }
            aria2::GlobalStat gstat = aria2::getGlobalStat(session);
            int allLength = 0;
            int currentLength = 0;
            std::vector<aria2::A2Gid> gids = aria2::getActiveDownload(session);
            for(const auto& gid : gids) {
                aria2::DownloadHandle* dh = aria2::getDownloadHandle(session, gid);
                if(dh) {
                    allLength = allLength + (int)dh->getTotalLength();
                    currentLength = currentLength + (int)dh->getCompletedLength();
                    aria2::deleteDownloadHandle(dh);
                }
            }
            [downloaderObjects removeObjectAtIndex:index];
            NSDictionary *taskData = @{
                                       @"name":[filename objectAtIndex:0],
                                       @"status":[NSString stringWithFormat:@"剩余分段:%d 下载速度:%dKB/s 大小:%d/%dMB",gstat.numActive,gstat.downloadSpeed/1024,currentLength/1024/1024,allLength/1024/1024],
                                       };
            [downloaderObjects insertObject:taskData atIndex:index];
        }
        int rv = aria2::sessionFinal(session);
        NSLog(@"Download success! STATUS: %d",rv);
        
        if(rv == 0){
            NSUserNotification *notification = [[NSUserNotification alloc] init];
            notification.title = @"Bilibili Client";
            notification.informativeText = @"视频与弹幕下载完成";
            notification.soundName = NSUserNotificationDefaultSoundName;
            [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
        }
        
        [downloaderObjects removeObjectAtIndex:index];
        NSDictionary *taskData = @{
                                   @"name":[filename objectAtIndex:0],
                                   @"status":@"下载已完成",
                                   };
        [downloaderObjects insertObject:taskData atIndex:index];
    });
}



- (void)awakeFromNib //当 WebContoller 加载完成后执行的动作
{
    NSError *err;

    [webView setFrameLoadDelegate:self];
    [webView setUIDelegate:self];
    [webView setResourceLoadDelegate:self];

    NSLog(@"Start");
    webView.mainFrameURL = @"http://www.bilibili.com";
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(AVNumberUpdated:) name:@"AVNumberUpdate" object:nil];
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"webpage/inject" ofType:@"js"];
    WebScript = [[NSString alloc] initWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&err];
    if(err){
        [self showError];
    }
    
    path = [[NSBundle mainBundle] pathForResource:@"webpage/webui" ofType:@"html"];
    WebUI = [[NSString alloc] initWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&err];
    if(err){
        [self showError];
    }
    
    path = [[NSBundle mainBundle] pathForResource:@"webpage/webui" ofType:@"css"];
    WebCSS = [[NSString alloc] initWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&err];
    if(err){
        [self showError];
    }
}

- (void)showError
{
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:@"文件读取失败，您可能无法正常使用本软件，请向开发者反馈。"];
    [alert runModal];
}

- (WebView *)webView:(WebView *)sender createWebViewWithRequest:(NSURLRequest *)request
{
    return webView;
}

- (NSURLRequest *)webView:(WebView *)sender
                 resource:(id)identifier
          willSendRequest:(NSURLRequest *)request
         redirectResponse:(NSURLResponse *)redirectResponse
           fromDataSource:(WebDataSource *)dataSource{
    NSString *URL = [request.URL absoluteString];
    NSMutableURLRequest *re = [[NSMutableURLRequest alloc] init];
    re = (NSMutableURLRequest *) request.mutableCopy;
    if([URL containsString:@"google"]){
        // Google ad is blocked in some (china) area, maybe take 30 seconds to wait for timeout
        [re setURL:[NSURL URLWithString:@"http://static.hdslb.com/images/transparent.gif"]];
    }else if([URL containsString:@"qq.com"]){
        // QQ analytics may block more than 10 seconds in some area
        [re setURL:[NSURL URLWithString:@"http://static.hdslb.com/images/transparent.gif"]];
    }else if([URL containsString:@"cnzz.com"]){
        // CNZZ is very slow in other country
        [re setURL:[NSURL URLWithString:@"http://static.hdslb.com/images/transparent.gif"]];
    }else if([URL containsString:@".swf"]){
        // Block Flash
        NSLog(@"Block flash url:%@",URL);
        [re setURL:[NSURL URLWithString:@"http://static.hdslb.com/images/transparent.gif"]];
    }else{
        NSUserDefaults *settingsController = [NSUserDefaults standardUserDefaults];
        NSString *xff = [settingsController objectForKey:@"xff"];
        if([xff length] > 4){
            [re setValue:xff forHTTPHeaderField:@"X-Forwarded-For"];
            [re setValue:xff forHTTPHeaderField:@"Client-IP"];
        }
    }
    return re;
}

- (void)webView:(WebView *)sender didClearWindowObject:(WebScriptObject *)windowScriptObject forFrame:(WebFrame *)frame
{
    [windowScriptObject setValue:self forKeyPath:@"window.external"];
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
    if(isTesting){
        if([webView.mainFrameURL isEqualToString:@"http://www.bilibili.com/ranking"]){
            [webView stringByEvaluatingJavaScriptFromString:@"window.location=$('#rank_list li:first-child .content > a').attr('href')"];
        }else if(![webView.mainFrameURL hasPrefix:@"http://www.bilibili.com/video/av"]){
            webView.mainFrameURL = @"http://www.bilibili.com/ranking";
        }else{
            [webView stringByEvaluatingJavaScriptFromString:@"setTimeout(function(){window.external.playVideoByCID(TYPCN_PLAYER_CID)},2000);"];
        }
    }
    [webView stringByEvaluatingJavaScriptFromString:WebScript];
    userAgent =  [webView stringByEvaluatingJavaScriptFromString:@"navigator.userAgent"];
}

- (void)webView:(WebView *)sender didCommitLoadForFrame:(WebFrame *)frame
{
   
}

- (NSArray *)webView:(WebView *)sender contextMenuItemsForElement:(NSDictionary *)element defaultMenuItems:(NSArray *)defaultMenuItems{
    NSMenuItem *copy = [[NSMenuItem alloc] initWithTitle:@"复制页面地址" action:@selector(CopyLink) keyEquivalent:@""];
    [copy setTarget:self];
    [copy setEnabled:YES];
    NSMenuItem *play = [[NSMenuItem alloc] initWithTitle:@"强制显示播放界面" action:@selector(ShowPlayer) keyEquivalent:@""];
    [play setTarget:self];
    [play setEnabled:YES];
    NSMenuItem *contact = [[NSMenuItem alloc] initWithTitle:@"呼叫程序猿" action:@selector(Contact) keyEquivalent:@""];
    [contact setTarget:self];
    [contact setEnabled:YES];
    NSMutableArray *mutableArray = [[NSMutableArray alloc] init];
    [mutableArray addObjectsFromArray:defaultMenuItems];
    [mutableArray addObject:copy];
    [mutableArray addObject:play];
    [mutableArray addObject:contact];
    return mutableArray;
}

- (void)CopyLink{
    [[NSPasteboard generalPasteboard] clearContents];
    [[NSPasteboard generalPasteboard] setString:webView.mainFrameURL  forType:NSStringPboardType];
}

- (void)ShowPlayer{
    [webView stringByEvaluatingJavaScriptFromString:WebScript];
    userAgent =  [webView stringByEvaluatingJavaScriptFromString:@"navigator.userAgent"];
}

- (void)Contact{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"mailto:typcncom@gmail.com"]];
}

- (IBAction)openAv:(id)sender {
    NSString *avNumber = [sender stringValue];
    if([[sender stringValue] length] > 2 ){
        if ([[avNumber substringToIndex:2] isEqual: @"av"]) {
            avNumber = [avNumber substringFromIndex:2];
        }


        webView.mainFrameURL = [NSString stringWithFormat:@"http://www.bilibili.com/video/av%@",avNumber];
        [sender setStringValue:@""];
    }
}

- (void)AVNumberUpdated:(NSNotification *)notification {
    NSString *url = [notification object];
    if ([[url substringToIndex:6] isEqual: @"http//"]) { //somehow, 传入url的Colon会被移除 暂时没有找到相关的说明，这里统一去掉，在最后添加http://
        url = [url substringFromIndex:6];
    }
    webView.mainFrameURL = [NSString stringWithFormat:@"http://%@", url];
}

@end

@interface PlayerWindowController : NSWindowController

@end

@implementation PlayerWindowController{
    
}


@end