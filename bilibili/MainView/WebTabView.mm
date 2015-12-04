//
//  WebTabView.m
//  bilibili
//
//  Created by TYPCN on 2015/9/3.
//  Copyright (c) 2015 TYPCN. All rights reserved.
//

#import "WebTabView.h"
#import "ToolBar.h"
#import "Analytics.h"

@implementation WebTabView {
    PluginManager *pm;
    NSString* WebScript;
    NSString* errHTML;
    NSView* HudView;
    bool ariainit;
    long acceptAnalytics;
}

-(id)initWithBaseTabContents:(CTTabContents*)baseContents {
    if (!(self = [super initWithBaseTabContents:baseContents])) return nil;
    NSURL *u = [NSURL URLWithString:@"http://vp-hub.eqoe.cn"];
    
    return [self initWithRequest:[NSURLRequest requestWithURL:u] andConfig:nil];
}

-(id)initWithRequest:(NSURLRequest *)req andConfig:(id)cfg{
    webView = [[TWebView alloc] initWithRequest:req andConfig:cfg setDelegate:self];
    [self loadStartupScripts];
    [self setIsWaitingForResponse:YES];
    NSScrollView *sv = [[NSScrollView alloc] initWithFrame:NSZeroRect];
    [sv setHasVerticalScroller:NO];
    [webView addToView:sv];
    self.view = sv;
    pm = [PluginManager sharedInstance];
    return self;
}

-(void)viewFrameDidChange:(NSRect)newFrame {
    [super viewFrameDidChange:newFrame];
    NSRect frame = NSZeroRect;
    frame.size = [(NSScrollView*)(view_) contentSize];
    [webView setFrameSize:frame];
    HudView = [[webView GetWebView] subviews][0];
    dispatch_async(dispatch_get_global_queue(0, 0), ^(void){
        [[NSUserDefaults standardUserDefaults] setDouble:frame.size.width forKey:@"webwidth"];
        [[NSUserDefaults standardUserDefaults] setDouble:frame.size.height forKey:@"webheight"];
        pm = [PluginManager sharedInstance];
    });
}

-(id)GetWebView{
    return [webView GetWebView];
}

-(TWebView *)GetTWebView{
    return webView;
}


- (void)loadStartupScripts
{
    NSError *err;
    
    
    
    NSUserDefaults *s = [NSUserDefaults standardUserDefaults];
    acceptAnalytics = [s integerForKey:@"acceptAnalytics"];
    
    if(!acceptAnalytics || acceptAnalytics == 1 || acceptAnalytics == 2){
        screenView("NewTab");
    }

    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"webpage/inject" ofType:@"js"];
    WebScript = [[NSString alloc] initWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&err];
    if(err){
        [self showError];
    }
    
    path = [[NSBundle mainBundle] pathForResource:@"webpage/webui" ofType:@"html"];
    NSString* WebUI = [[NSString alloc] initWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&err];
    if(err){
        [self showError];
    }
    WebUI = [WebUI stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"];
    WebUI = [WebUI stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
    WebScript = [WebScript stringByReplacingOccurrencesOfString:@"INJ_HTML" withString:WebUI];
    
    path = [[NSBundle mainBundle] pathForResource:@"webpage/error" ofType:@"html"];
    errHTML = [[NSString alloc] initWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&err];
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController {
    [super windowControllerDidLoadNib:aController];
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError {
    // Insert code here to write your document to data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning nil.
    // You can also choose to override -fileWrapperOfType:error:, -writeToURL:ofType:error:, or -writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
    if (outError) {
        *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:nil];
    }
    return nil;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {
    // Insert code here to read your document from the given data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning NO.
    // You can also choose to override -readFromFileWrapper:ofType:error: or -readFromURL:ofType:error: instead.
    // If you override either of these, you should also override -isEntireFileLoaded to return NO if the contents are lazily loaded.
    if (outError) {
        *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:nil];
    }
    return NO;
}

+ (BOOL)autosavesInPlace {
    return YES;
}

- (BOOL) shouldStartDecidePolicy: (NSURLRequest *) request
{
    NSString *url = [request.URL absoluteString];
    if([url containsString:@"about:blank"]){
        return NO;
    }
    return YES;
}

- (void) didStartNavigation
{
    //NSLog(@"start load");
}

- (NSString *)decideScriptInject{
    NSURL *url = [NSURL URLWithString:[webView getURL]];
    NSString *host = [url host];
    if(!host){
        return NULL;
    }
    if([host containsString:@".bilibili.com"] || [host containsString:@"mimi"]){
        return WebScript;
    }else{
        return [pm javascriptForDomain:host];
    }
    return NULL;
}

- (void) didCommitNavigation{
    [self setTitle:[webView getTitle]];
    [self setIsWaitingForResponse:NO];
    [self setIsLoading:YES];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"BLChangeURL" object:[webView getURL]];
    [webView runJavascript:[self decideScriptInject]];
    
    if(acceptAnalytics == 1 || acceptAnalytics == 2){
        screenView("WebView");
    }else{
        NSLog(@"Analytics disabled ! won't upload.");
    }
    NSString *lastPlay = [[NSUserDefaults standardUserDefaults] objectForKey:@"LastPlay"];
    if([lastPlay length] > 1){
        [webView setURL:lastPlay];
        NSLog(@"Opening last play url %@",lastPlay);
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"LastPlay"];
    }
}

- (void) failLoadOrNavigation: (NSURLRequest *) request withError: (NSError *) error
{
    NSLog(@"Request load failed: %@ Error: %@", request, error);
    
    if(error.code > -1000){
        return;
    }
    
    [self setIsCrashed:YES];
    
    NSString *errDetail = [errHTML stringByReplacingOccurrencesOfString:@"{{errCode}}" withString:[@(error.code) stringValue]];
    
    errDetail = [errDetail stringByReplacingOccurrencesOfString:@"{{debugInfo}}" withString:error.description];
    
    NSString *key = [NSString stringWithFormat:@"Err%ld",(long)error.code];
    NSString *desc = NSLocalizedStringFromTableInBundle(key,@"NetErr",[NSBundle mainBundle], nil);
    errDetail = [errDetail stringByReplacingOccurrencesOfString:@"{{errDetail}}" withString:desc];

    errDetail = [errDetail stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"];
    errDetail = [errDetail stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
    
    [webView runJavascript:[NSString stringWithFormat:@"document.getElementsByTagName('html')[0].innerHTML='%@'",errDetail]];
}

- (void) finishLoadOrNavigation: (NSURLRequest *) request
{
    [self setIsLoading:NO];
    [self setTitle:[webView getTitle]];
}

- (void)onTitleChange:(NSString *)str{
    [self setTitle:str];
    [webView runJavascript:[self decideScriptInject]];
}

- (void)showError
{
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:NSLocalizedString(@"文件读取失败，您可能无法正常使用本软件，请向开发者反馈。", nil)];
    [alert runModal];
}

@end
