//
//  WebTabView.m
//  bilibili
//
//  Created by TYPCN on 2015/9/3.
//  Copyright (c) 2015 TYPCN. All rights reserved.
//

#import "WebTabView.h"
#import <Sparkle/Sparkle.h>
#import "downloadWrapper.h"
#import "Analytics.h"
#import "ToolBar.h"

@implementation WebTabView {
    NSString* WebScript;
    NSString* WebUI;
    NSString* WebCSS;
    bool ariainit;
    long acceptAnalytics;
}
@synthesize playerWindowController;

-(id)initWithBaseTabContents:(CTTabContents*)baseContents {
    if (!(self = [super initWithBaseTabContents:baseContents])) return nil;
    
    double height = [[NSUserDefaults standardUserDefaults] doubleForKey:@"webheight"];
    double width = [[NSUserDefaults standardUserDefaults] doubleForKey:@"webwidth"];
    NSLog(@"lastWidth: %f Height: %f",width,height);
    if(width < 300 || height < 300){
        NSRect rect = [[NSScreen mainScreen] visibleFrame];
        [self.view setFrame:rect];
    }else{
        NSRect frame = [self.view.window frame];
        frame.size = NSMakeSize(width, height);
        [self.view setFrame:frame];
    }
    
    return [self initWithURL:@"http://www.bilibili.com"];
}

-(id)initWithURL:(NSString *)url{
    webView = [[WebView alloc] initWithFrame:NSZeroRect];
    [webView setAutoresizingMask:NSViewMaxYMargin|NSViewMinXMargin|NSViewWidthSizable|NSViewMaxXMargin|NSViewHeightSizable|NSViewMinYMargin];
    [self loadStartupScripts];
    [self setIsWaitingForResponse:YES];
    webView.mainFrameURL = url;
    NSScrollView *sv = [[NSScrollView alloc] initWithFrame:NSZeroRect];
    [sv setDocumentView:webView];
    [sv setHasVerticalScroller:NO];
    self.view = sv;
    return self;
}

-(WebView *)GetWebView{
    return webView;
}

-(void)viewFrameDidChange:(NSRect)newFrame {
    // We need to recalculate the frame of the NSTextView when the frame changes.
    // This happens when a tab is created and when it's moved between windows.
    [super viewFrameDidChange:newFrame];
    NSClipView* clipView = [[view_ subviews] objectAtIndex:0];
    NSTextView* tv = [[clipView subviews] objectAtIndex:0];
    NSRect frame = NSZeroRect;
    frame.size = [(NSScrollView*)(view_) contentSize];
    [[NSUserDefaults standardUserDefaults] setDouble:frame.size.width forKey:@"webwidth"];
    [[NSUserDefaults standardUserDefaults] setDouble:frame.size.height forKey:@"webheight"];
    [tv setFrame:frame];
}

- (NSString *)windowNibName {
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return nil;
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

- (void)loadStartupScripts
{
    NSError *err;
    
    [webView setFrameLoadDelegate:self];
    [webView setUIDelegate:self];
    [webView setResourceLoadDelegate:self];
    
    NSUserDefaults *s = [NSUserDefaults standardUserDefaults];
    acceptAnalytics = [s integerForKey:@"acceptAnalytics"];
    
    if(!acceptAnalytics || acceptAnalytics == 1 || acceptAnalytics == 2){
        screenView("NewTab");
    }
    NSLog(@"Start");
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
    if(sel == @selector(showNotification:))
        return @"showNotification";
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
    if(sel == @selector(showNotification:))
        return NO;
    return YES;
}

- (void)showNotification:(NSString *)content{
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = MBProgressHUDModeText;
    hud.labelText = content;
    hud.removeFromSuperViewOnHide = YES;
    [hud hide:YES afterDelay:3];
}

- (void)checkForUpdates
{
    [[SUUpdater sharedUpdater] checkForUpdates:nil];
    if(acceptAnalytics == 1 || acceptAnalytics == 2){
        action("App","CheckForUpdate","CheckForUpdate");
    }else{
        NSLog(@"Analytics disabled ! won't upload.");
    }
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
    NSArray *fn = [webView.mainFrameTitle componentsSeparatedByString:@"_"];
    NSString *mediaTitle = [fn objectAtIndex:0];
    parsing = true;
    vCID = cid;
    vUrl = webView.mainFrameURL;
    if([mediaTitle length] > 0){
        vTitle = [fn objectAtIndex:0];
    }else{
        vTitle = NSLocalizedString(@"未命名", nil);
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:vUrl forKey:@"LastPlay"];
    NSLog(@"Video detected ! CID: %@",vCID);
    if(acceptAnalytics == 1){
        action("video", "play", [vCID cStringUsingEncoding:NSUTF8StringEncoding]);
        screenView("PlayerView");
    }else if(acceptAnalytics == 2){
        screenView("PlayerView");
    }else{
        NSLog(@"Analytics disabled ! won't upload.");
    }
    dispatch_async(dispatch_get_main_queue(), ^(void){
        NSStoryboard *storyBoard = [NSStoryboard storyboardWithName:@"Main" bundle:nil];
        playerWindowController = [storyBoard instantiateControllerWithIdentifier:@"playerWindow"];
        [playerWindowController showWindow:self];
    });
}
- (void)downloadVideoByCID:(NSString *)cid
{
    if(!downloaderObjects){
        downloaderObjects = [[NSMutableArray alloc] init];
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:NSLocalizedString(@"注意：下载功能仅供测试，可能有各种 BUG，支持分段视频，默认保存在 Movies 文件夹。\n点击 文件->下载管理 来查看任务", nil)];
        [alert runModal];
    }
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = MBProgressHUDModeIndeterminate;
    hud.labelText = NSLocalizedString(@"正在启动下载引擎", nil);
    hud.removeFromSuperViewOnHide = YES;
    
    if(!DL){
        DL = new Downloader();
    }
    
    if(acceptAnalytics == 1){
        action("video", "download", [cid cStringUsingEncoding:NSUTF8StringEncoding]);
        screenView("PlayerView");
    }else if(acceptAnalytics == 2){
        screenView("PlayerView");
    }else{
        NSLog(@"Analytics disabled ! won't upload.");
    }
    
    NSArray *fn = [webView.mainFrameTitle componentsSeparatedByString:@"_"];
    NSString *filename = [fn objectAtIndex:0];
    
    dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSDictionary *taskData = @{
                                   @"name":filename,
                                   @"status":NSLocalizedString(@"正在等待", nil),
                                   @"cid":cid,
                                   };
        [dList lock];
        int index = (int)[downloaderObjects count];
        [downloaderObjects insertObject:taskData atIndex:index];
        [dList unlock];
        DL->init();
        hud.labelText = NSLocalizedString(@"正在解析视频地址", nil);
        DL->newTask([cid intValue], filename);
        hud.labelText = NSLocalizedString(@"成功开始下载", nil);
        dispatch_async(dispatch_get_main_queue(), ^(void){
            hud.mode = MBProgressHUDModeText;
            [hud hide:YES afterDelay:3];
        });
        
        DL->runDownload(index, filename);
    });
}


- (void)showError
{
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:NSLocalizedString(@"文件读取失败，您可能无法正常使用本软件，请向开发者反馈。", nil)];
    [alert runModal];
}

- (WebView *)webView:(WebView *)sender createWebViewWithRequest:(NSURLRequest *)request
{
    WebTabView *tv = (WebTabView *)[browser createTabBasedOn:nil withUrl:[request.URL absoluteString]];
    [browser addTabContents:tv inForeground:YES];
    return [tv GetWebView];
}

- (NSURLRequest *)webView:(WebView *)sender
                 resource:(id)identifier
          willSendRequest:(NSURLRequest *)request
         redirectResponse:(NSURLResponse *)redirectResponse
           fromDataSource:(WebDataSource *)dataSource{
    NSString *URL = [request.URL absoluteString];
    NSMutableURLRequest *re = [[NSMutableURLRequest alloc] init];
    re = (NSMutableURLRequest *) request.mutableCopy;
    if([URL containsString:@"googlesyndication"] || [URL containsString:@"analytics.js"]){
        // Google ad is blocked in some (china) area, maybe take 30 seconds to wait for timeout
        [re setURL:[NSURL URLWithString:@"http://static.hdslb.com/images/transparent.gif"]];
    }else if([URL containsString:@"tajs.qq.com"]){
        // QQ analytics may block more than 10 seconds in some area
        [re setURL:[NSURL URLWithString:@"http://static.hdslb.com/images/transparent.gif"]];
    }else if([URL containsString:@"cnzz.com"]){
        // CNZZ is very slow in other country
        [re setURL:[NSURL URLWithString:@"http://static.hdslb.com/images/transparent.gif"]];
    }else if([URL containsString:@"cpro.baidustatic.com"]){
        // Baidu is very slow in other country
        [re setURL:[NSURL URLWithString:@"http://static.hdslb.com/images/transparent.gif"]];
    }else if([URL containsString:@".swf"]){
        // Block Flash
        NSLog(@"Block flash url:%@",URL);
        [re setURL:[NSURL URLWithString:@"http://static.hdslb.com/images/transparent.gif"]];
    }else if([URL containsString:@".eqoe.cn"]){
        [re setValue:@"http://client.typcn.com" forHTTPHeaderField:@"Referer"];
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
    [webView stringByEvaluatingJavaScriptFromString:WebScript];
    userAgent =  [webView stringByEvaluatingJavaScriptFromString:@"navigator.userAgent"];
    [self setIsLoading:NO];
}

- (void)webView:(WebView *)sender
didReceiveTitle:(NSString *)title
       forFrame:(WebFrame *)frame{
    [self setTitle:title];
    [self setIsWaitingForResponse:NO];
    [self setIsLoading:YES];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"BLChangeURL" object:webView.mainFrameURL userInfo:nil];
    userAgent =  [webView stringByEvaluatingJavaScriptFromString:@"navigator.userAgent"];
    [webView stringByEvaluatingJavaScriptFromString:WebScript];
    
    if(acceptAnalytics == 1 || acceptAnalytics == 2){
        screenView("WebView");
    }else{
        NSLog(@"Analytics disabled ! won't upload.");
    }
    NSString *lastPlay = [[NSUserDefaults standardUserDefaults] objectForKey:@"LastPlay"];
    if([lastPlay length] > 1){
        webView.mainFrameURL = lastPlay;
        NSLog(@"Opening last play url %@",lastPlay);
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"LastPlay"];
    }
}

- (void)webView:(WebView *)sender
didStartProvisionalLoadForFrame:(WebFrame *)frame{
    //    [webView stringByEvaluatingJavaScriptFromString:WebScript];
    //    userAgent =  [webView stringByEvaluatingJavaScriptFromString:@"navigator.userAgent"];
}

- (void)webView:(WebView *)sender didCommitLoadForFrame:(WebFrame *)frame
{
    
}

- (NSArray *)webView:(WebView *)sender contextMenuItemsForElement:(NSDictionary *)element defaultMenuItems:(NSArray *)defaultMenuItems{
    NSMenuItem *copy = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"复制页面地址", nil) action:@selector(CopyLink:) keyEquivalent:@""];
    [copy setTarget:self];
    [copy setEnabled:YES];
    NSMenuItem *play = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"强制显示播放界面", nil) action:@selector(ShowPlayer) keyEquivalent:@""];
    [play setTarget:self];
    [play setEnabled:YES];
    NSMenuItem *contact = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"呼叫程序猿", nil) action:@selector(Contact) keyEquivalent:@""];
    [contact setTarget:self];
    [contact setEnabled:YES];
    NSMutableArray *mutableArray = [[NSMutableArray alloc] init];
    [mutableArray addObjectsFromArray:defaultMenuItems];
    [mutableArray addObject:copy];
    [mutableArray addObject:play];
    [mutableArray addObject:contact];
    return mutableArray;
}

- (IBAction)CopyLink:(id)sender {
    [[NSPasteboard generalPasteboard] clearContents];
    [[NSPasteboard generalPasteboard] setString:webView.mainFrameURL  forType:NSStringPboardType];
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = MBProgressHUDModeText;
    hud.labelText = NSLocalizedString(@"当前页面地址已经复制到剪贴板", nil);
    hud.removeFromSuperViewOnHide = YES;
    [hud hide:YES afterDelay:3];
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
