//
//  AppDelegate.m
//  bilibili
//
//  Created by TYPCN on 2015/3/30.
//  Copyleft 2016 TYPCN. All rights reserved.
//

#import "AppDelegate.h"
#import "HTTPServer.h"
#import "Popover.h"
#import "PFAboutWindowController.h"
#import "WebTabView.h"
#import "PJTernarySearchTree.h"
#import "PlayerLoader.h"
#import "CrashReport.h"
#import "BrowserHistory.h"

Browser *browser;

@interface AppDelegate ()

@property PFAboutWindowController *aboutWindowController;

@end

@implementation AppDelegate{
    int without_gui;
    int firstInit;
}

@synthesize donatew;
@synthesize crashw;

- (void)applicationWillFinishLaunching:(NSNotification *)notification {
    signal(SIGPIPE, SIG_IGN);
    [[NSAppleEventManager sharedAppleEventManager]
     setEventHandler:self
     andSelector:@selector(handleURLEvent:withReplyEvent:)
     forEventClass:kInternetEventClass
     andEventID:kAEGetURL];
    BOOL fcache = [[NSFileManager defaultManager] fileExistsAtPath:@"/Users/Shared/.fc/" isDirectory:nil];
    NSString *path = [[NSBundle mainBundle] pathForResource:@"gencache" ofType:@"sh"];
    if(!fcache){
        [[NSUserDefaults standardUserDefaults] setObject:@"no" forKey:@"FirstPlayed"];
        NSTask *task = [[NSTask alloc] init];
        task.launchPath = @"/bin/sh";
        task.arguments = @[path];
        [task launch];
        [task waitUntilExit];
        fcache = [[NSFileManager defaultManager] fileExistsAtPath:@"/Users/Shared/.fc/fonts/" isDirectory:nil];
        if(!fcache){
            NSAlert *alert = [[NSAlert alloc] init];
            [alert setMessageText:@"无法创建字体缓存，您可能无法看到任何弹幕，可能的原因：\n1. 您的系统部分文件夹权限错误"
                        "\n2. 您没有将 Bilibili 安装到 Application 文件夹"
                        "\n3. 防火墙等软件阻止了文件复制"
                        "\n4. 由于清理软件或误操作导致系统环境不完整\n"
                        "\n请尝试以下步骤："
                        "\n1. 打开 /Users/Shared 文件夹，新建一个叫 fc 的文件夹"
                        "\n2. 右键 Bilibili.app ，选择显示包内容，将 Contents/Resources/fontconfig 文件夹中的所有内容复制到 fc 文件夹"
                        "\n3. 将 fc 文件夹重命名为 .fc 然后重新打开软件"];
            [alert runModal];
        }
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(switchTab:) name:@"BLSelectNextView" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(prevTab:) name:@"BLSelectPrevView" object:nil];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    bool showdonate = false;
    NSUserDefaults *s = [NSUserDefaults standardUserDefaults];
    NSString *uuid = [s objectForKey:@"UUID"];
    if(!uuid){
        [s setObject:[[NSProcessInfo processInfo] globallyUniqueString] forKey:@"UUID"];
    }
    long acceptAnalytics = [s integerForKey:@"acceptAnalytics"];
    if(!acceptAnalytics){
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"是否接受匿名统计？\n如果接受，则会上传一些基础信息（不包括 IP 地址）\n如果不接受，仅为软件用户量+1 \n如果选择完全禁止，开发者将无法了解到任何信息，软件不会与除 Bilibili 外的任何服务器通讯"];
        
        [alert addButtonWithTitle:@"接受"];
        [alert addButtonWithTitle:@"不接受"];
        [alert addButtonWithTitle:@"完全禁止"];
        long r = [alert runModal];
        if(r == 1000){ // 接受
            [s setInteger:1 forKey:@"acceptAnalytics"];
            acceptAnalytics = 1;
        }else if(r == 1001){// 拒绝
            [s setInteger:2 forKey:@"acceptAnalytics"];
            acceptAnalytics = 2;
        }else if(r == 1002){ //完全禁止
            [s setInteger:3 forKey:@"acceptAnalytics"];
            acceptAnalytics = 3;
        }
    }else{
        showdonate = true; // Prevent multi alerts on software start
    }
    [s synchronize];
    NSLog(@"AcceptAnalytics=%ld WithoutGUI=%d",acceptAnalytics,without_gui);
    if(!without_gui){
        NSArray *unclosed = [[BrowserHistory sharedManager] getUnclosed];
        if(unclosed && [unclosed count] > 0){
            [self openBrowserWithUrl:@"http://_bilimac_newtab.loli.video/unclosed.html"];
        }else{
            [self openBrowserWithUrl:@"https://www.bilibili.com"];
        }
        [browser.window performSelector:@selector(makeMainWindow) withObject:nil afterDelay:0.2];
        [browser.window performSelector:@selector(makeKeyAndOrderFront:) withObject:NSApp afterDelay:0.2];
        [NSApp activateIgnoringOtherApps:YES];
    }
    
    firstInit = 1;
    
    // Start ARIA2
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"startaria" ofType:@"sh"];
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = @"/bin/sh";
    task.arguments = @[path];
    [task launch];
    
    // Start HTTP Server
    [[HTTPServer alloc] startHTTPServer];
    
    if([s objectForKey:@"donate"]){
        showdonate = false;
    }
    
    NSString *hwid = [s objectForKey:@"hwid"];
    if([hwid length] < 4){
        hwid  = [self randomStringWithLength:16];
        [s setObject:hwid forKey:@"hwid"];
    }
    
    
    // Add taskbar item
    
//    Popover *p = [[Popover alloc] init];
//    [p addToStatusBar];
//    [p startMonitor];
    
    if(showdonate){
        [NSTimer scheduledTimerWithTimeInterval:2
                                         target:self
                                       selector: @selector(showDonate)
                                       userInfo:nil
                                        repeats:NO]; // Prevent browser window order back
    }
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^(void){
#ifndef DEBUG
        CrashlyticsKit.delegate = self;
        [Fabric with:@[[Crashlytics class]]];
#endif
        [PJTernarySearchTree sharedTree]; // Preload Shared Tree
    });
}

- (void)application:(NSApplication *)sender openFiles:(NSArray *)filenames
{
    if(!firstInit){
        without_gui = 1;
    }
    [[PlayerLoader sharedInstance] loadVideoWithLocalFiles:filenames];
    NSLog(@"Handle open files: %@",filenames);
}

- (void)showDonate {
    NSStoryboard *storyBoard = [NSStoryboard storyboardWithName:@"Main" bundle:nil];
    donatew = [storyBoard instantiateControllerWithIdentifier:@"donatewindow"];
    [donatew showWindow:self];
    [donatew.window makeKeyAndOrderFront:NSApp];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
    
}
- (IBAction)issues:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/typcn/bilibili-mac-client/issues"]];
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag
{
    if (flag) {
        if(theApplication.mainWindow){
            [theApplication.mainWindow makeKeyAndOrderFront:nil];
            return YES;
        }else if(browser && browser.window && browser.tabCount > 0){
            WebTabView *tc = (WebTabView *)[browser activeTabContents];
            if(!tc){
                [self performBrowserRestart];
            }
            NSString *url = [[tc GetTWebView] getURL];
            if(url && [url length] > 2) {
                // The browser really exists ( not ghost )
                [browser.window makeKeyAndOrderFront:theApplication];
            }else{
                [self performBrowserRestart];
            }
            return YES;
        }else if(!browser || browser.tabCount == 0){
            [self performBrowserRestart];
            return YES;
        }
        return NO;
    }
    else
    {
        [self performBrowserRestart];
        return YES;
    }
}

- (void)performBrowserRestart{
    [browser.window close];
    [browser.windowController close];
    browser.windowController = NULL;
    browser = NULL;
    [self performSelector:@selector(delayedRestart) withObject:nil afterDelay:0.5];
}

- (void)delayedRestart {
    [self openBrowserWithUrl:@"https://www.bilibili.com"];
}

- (void)handleURLEvent:(NSAppleEventDescriptor*)event
        withReplyEvent:(NSAppleEventDescriptor*)replyEvent
{
    NSString* url = [[event paramDescriptorForKeyword:keyDirectObject]
                      stringValue];
    NSLog(@"url: %@",url);
    url = [url substringFromIndex:5];
    if ([[url substringToIndex:6] isEqual: @"http//"]) { //somehow, 传入url的Colon会被移除 暂时没有找到相关的说明，这里统一去掉，在最后添加http://
        url = [url substringFromIndex:6];
    }
    if([url isEqualToString:@"open_without_gui"]){
        if(browser){
            [browser closeWindow];
        }
        without_gui = 1;
        return;
    }
    [self openBrowserWithUrl:[NSString stringWithFormat:@"http://%@", url]];
}

- (void)openBrowserWithUrl:(NSString *)url{
    NSMutableURLRequest *re = [[NSMutableURLRequest alloc] init];
    [re setURL:[NSURL URLWithString:url]];
    NSUserDefaults *settingsController = [NSUserDefaults standardUserDefaults];
    NSString *xff = [settingsController objectForKey:@"xff"];
    if([xff length] > 4){
        [re setValue:xff forHTTPHeaderField:@"X-Forwarded-For"];
        [re setValue:xff forHTTPHeaderField:@"Client-IP"];
    }
    if(!browser){
        browser = (Browser *)[Browser browser];
        browser.windowController = [[CTBrowserWindowController alloc] initWithBrowser:browser];
        without_gui = false;
    }

    
    [browser addTabContents:[browser createTabBasedOn:nil withRequest:re andConfig:nil] inForeground:YES];
    [browser.windowController showWindow:self];
    [browser.window makeKeyAndOrderFront:NSApp];
    
    [browser.window performSelector:@selector(makeMainWindow) withObject:nil afterDelay:100];
}

// Main Menu Events

- (IBAction)goForum:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://leanclub.org"]];
}
- (IBAction)newTab:(id)sender {
    [browser addBlankTabInForeground:YES];
}
- (IBAction)closeTab:(id)sender {
    NSWindow *kwin = [[NSApplication sharedApplication] keyWindow];
    if([[kwin className] isEqualToString:@"CTBrowserWindow"]){
        [browser closeTab];
    }else{
        [kwin performClose:nil];
    }
}
- (IBAction)switchTab:(id)sender {
    [browser selectNextTab];
}
- (IBAction)prevTab:(id)sender {
    [browser selectPreviousTab];
}
- (IBAction)dlManager:(id)sender {
    id ct = [browser createTabBasedOn:nil withUrl:@"http://static-ssl.tycdn.net/downloadManager/v2/"];
    [browser addTabContents:ct inForeground:YES];
}
- (IBAction)showHelp:(id)sender {
    id ct = [browser createTabBasedOn:nil withUrl:@"http://_bilimac_newtab.loli.video/faq.html"];
    [browser addTabContents:ct inForeground:YES];
}

- (IBAction)dlFolder:(id)sender {
    NSString *path = [NSString stringWithFormat:@"%@%@",NSHomeDirectory(),@"/Movies/Bilibili/"];
    [[NSWorkspace sharedWorkspace]openFile:path withApplication:@"Finder"];
}
- (IBAction)aboutView:(id)sender {
    if(!self.aboutWindowController){
        self.aboutWindowController = [[PFAboutWindowController alloc] init];
    }
    [self.aboutWindowController showWindow:nil];
}

- (IBAction)reloadPage:(id)sender {
    WebTabView *tc = (WebTabView *)[browser activeTabContents];
    NSString *u = [[tc GetTWebView] getURL];
    [[tc GetTWebView] setURL:u];
}

- (IBAction)addressBar:(id)sender {
    if([browser window] && [browser window].contentView && [browser window].contentView.subviews){
        NSArray *sv = [browser window].contentView.subviews;
        for(int i = 0;i < sv.count; i++){
            id obj = [sv objectAtIndex:i];
            if(obj && [[obj className] isEqual: @"CTToolbarView"]){ // Find Toolbar
                
                NSArray *tbsv = [obj subviews];
                for(int i = 0;i < tbsv.count; i++){
                    NSTextField *tb_obj = [tbsv objectAtIndex:i];
                    if(tb_obj && [[tb_obj className] isEqual: @"AddressBar"]){ // Find Address Bar

                        [[browser window]
                         performSelector: @selector(makeFirstResponder:) 
                         withObject: tb_obj
                         afterDelay:0.0];
                        
                        [[tb_obj currentEditor] setSelectedRange:NSMakeRange([[tb_obj stringValue] length], 0)];
                        break;
                    }
                }
                
                break;
            }
        }
    }
    
}

- (NSString *) randomStringWithLength: (int) len {
    
    NSString *letters = @"abcdef0123456789";
    NSMutableString *randomString = [NSMutableString stringWithCapacity: len];
    
    for (int i=0; i<len; i++) {
        [randomString appendFormat: @"%C", [letters characterAtIndex: arc4random_uniform((int)[letters length]-1)]];
    }
    
    return randomString;
}



- (BOOL)crashlyticsCanUseBackgroundSessions:(Crashlytics *)crashlytics{
    return YES;
}

- (void)crashlyticsDidDetectReportForLastExecution:(CLSReport *)report completionHandler:(void (^)(BOOL submit))completionHandler{
    dispatch_async(dispatch_get_main_queue(), ^(void){
        completionHandler(YES);
//        NSStoryboard *storyBoard = [NSStoryboard storyboardWithName:@"Main" bundle:nil];
//        crashw = [storyBoard instantiateControllerWithIdentifier:@"crashReportWindow"];
//        [crashw showWindow:self];
//        [crashw.window makeKeyAndOrderFront:NSApp];
//        CrashReport *crv = (CrashReport *)crashw.window.contentViewController;
//        [crv setCallbackHandler:completionHandler andReport:report];
    });
}

@end
