//
//  ViewController.m
//  bilibili
//
//  Created by TYPCN on 2015/3/30.
//  Copyleft 2015 TYPCN. All rights reserved.
//

#import "ViewController.h"
#import <Sparkle/Sparkle.h>

@import AppKit;

NSString *vUrl;
NSString *vCID;
NSString *userAgent;
NSWindow *currWindow;
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
}

@end

@implementation WebController


+(NSString*)webScriptNameForSelector:(SEL)sel
{
    if(sel == @selector(checkForUpdates))
        return @"checkForUpdates";
    if(sel == @selector(showPlayGUI))
        return @"showPlayGUI";
    if(sel == @selector(playVideoByCID:))
        return @"playVideoByCID";
    return nil;
}

+ (BOOL)isSelectorExcludedFromWebScript:(SEL)sel
{
    if(sel == @selector(checkForUpdates))//JS对应的本地函数
        return NO;
    if(sel == @selector(showPlayGUI))//JS对应的本地函数
        return NO;
    if(sel == @selector(playVideoByCID:))//JS对应的本地函数
        return NO;
    return YES; //返回 YES 表示函数被排除，不会在网页上注册
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
        }
    }
    [webView stringByEvaluatingJavaScriptFromString:WebScript];
    userAgent =  [webView stringByEvaluatingJavaScriptFromString:@"navigator.userAgent"];
}

- (void)webView:(WebView *)sender didCommitLoadForFrame:(WebFrame *)frame
{
   
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