//
//  AppDelegate.m
//  bilibili
//
//  Created by TYPCN on 2015/3/30.
//  Copyleft 2015 TYPCN. All rights reserved.
//

#import "AppDelegate.h"
#import "HTTPServer.h"
#import "Popover.h"
#import "PFAboutWindowController.h"

Browser *browser;

@interface AppDelegate ()

@property PFAboutWindowController *aboutWindowController;

@end

@implementation AppDelegate

@synthesize donatew;

- (void)applicationWillFinishLaunching:(NSNotification *)notification {
//    NSOperatingSystemVersion version = [[NSProcessInfo processInfo] operatingSystemVersion];
//    if(version.minorVersion == 11){
//        NSAlert *alert = [[NSAlert alloc] init];
//        [alert setMessageText:@"对不起，由于 OpenGL 问题，软件暂时无法兼容 10.11, 请尝试使用 Xcode7 重新编译 libmpv.dylib"];
//        [alert runModal];
//        return;
//    }
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
    NSLog(@"AcceptAnalytics=%ld",acceptAnalytics);
    
    browser = (Browser *)[Browser browser];
    browser.windowController = [[CTBrowserWindowController alloc] initWithBrowser:browser];
    NSMutableURLRequest *re = [[NSMutableURLRequest alloc] init];
    [re setURL:[NSURL URLWithString:@"http://www.bilibili.com"]];
    NSString *xff = [s objectForKey:@"xff"];
    if([xff length] > 4){
        [re setValue:xff forHTTPHeaderField:@"X-Forwarded-For"];
        [re setValue:xff forHTTPHeaderField:@"Client-IP"];
    }
    
    [browser addTabContents:[browser createTabBasedOn:nil withRequest:re andConfig:nil] inForeground:YES];
    [browser.windowController showWindow:NSApp];
    sleep(0.2);
    [browser.window makeKeyAndOrderFront:NSApp];
    [browser.window makeMainWindow];
    
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
        return NO;
    }
    else
    {
        NSMutableURLRequest *re = [[NSMutableURLRequest alloc] init];
        [re setURL:[NSURL URLWithString:@"http://www.bilibili.com"]];
        NSUserDefaults *settingsController = [NSUserDefaults standardUserDefaults];
        NSString *xff = [settingsController objectForKey:@"xff"];
        if([xff length] > 4){
            [re setValue:xff forHTTPHeaderField:@"X-Forwarded-For"];
            [re setValue:xff forHTTPHeaderField:@"Client-IP"];
        }
        
        [browser addTabContents:[browser createTabBasedOn:nil withRequest:re andConfig:nil] inForeground:YES];
        [browser.windowController showWindow:self];
        
        return YES;
    }
}

- (void)AVNumberUpdated:(NSNotification *)notification {

}

- (void)handleURLEvent:(NSAppleEventDescriptor*)event
        withReplyEvent:(NSAppleEventDescriptor*)replyEvent
{
    NSString* url = [[event paramDescriptorForKeyword:keyDirectObject]
                      stringValue];
    url = [url substringFromIndex:5];
    if ([[url substringToIndex:6] isEqual: @"http//"]) { //somehow, 传入url的Colon会被移除 暂时没有找到相关的说明，这里统一去掉，在最后添加http://
        url = [url substringFromIndex:6];
    }
    NSMutableURLRequest *re = [[NSMutableURLRequest alloc] init];
    [re setURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://%@", url]]];
    NSUserDefaults *settingsController = [NSUserDefaults standardUserDefaults];
    NSString *xff = [settingsController objectForKey:@"xff"];
    if([xff length] > 4){
        [re setValue:xff forHTTPHeaderField:@"X-Forwarded-For"];
        [re setValue:xff forHTTPHeaderField:@"Client-IP"];
    }

    [browser addTabContents:[browser createTabBasedOn:nil withRequest:re andConfig:nil] inForeground:YES];
    [browser.windowController showWindow:self];
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
        [[NSNotificationCenter defaultCenter] postNotificationName:@"BLChangeURL" object:nil userInfo:nil];
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
    id ct = [browser createTabBasedOn:nil withUrl:@"http://static.tycdn.net/downloadManager/"];
    [browser addTabContents:ct inForeground:YES];
}
- (IBAction)showHelp:(id)sender {
    id ct = [browser createTabBasedOn:nil withUrl:@"http://cdn.eqoe.cn/files/bilibili/faq.html"];
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





- (NSString *) randomStringWithLength: (int) len {
    
    NSString *letters = @"abcdefghijklmnopqrstuvwxyz0123456789";
    NSMutableString *randomString = [NSMutableString stringWithCapacity: len];
    
    for (int i=0; i<len; i++) {
        [randomString appendFormat: @"%C", [letters characterAtIndex: arc4random_uniform([letters length])]];
    }
    
    return randomString;
}


@end