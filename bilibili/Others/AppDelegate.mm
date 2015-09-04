//
//  AppDelegate.m
//  bilibili
//
//  Created by TYPCN on 2015/3/30.
//  Copyleft 2015 TYPCN. All rights reserved.
//

#import "AppDelegate.h"
#include "aria2.hpp"

Browser *browser;

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)applicationWillFinishLaunching:(NSNotification *)notification {
    NSOperatingSystemVersion version = [[NSProcessInfo processInfo] operatingSystemVersion];
    if(version.minorVersion == 11){
//        NSAlert *alert = [[NSAlert alloc] init];
//        [alert setMessageText:@"对不起，由于 OpenGL 问题，软件暂时无法兼容 10.11, 请尝试使用 Xcode7 重新编译 libmpv.dylib"];
//        [alert runModal];
//        return;
    }
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
    aria2::libraryInit();
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
    }
    [s synchronize];
    NSLog(@"AcceptAnalytics=%ld",acceptAnalytics);
    
    browser = (Browser *)[Browser browser];
    browser.windowController = [[CTBrowserWindowController alloc] initWithBrowser:browser];
    [browser addBlankTabInForeground:YES];
    [browser.windowController showWindow:self];
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
        [browser addBlankTabInForeground:YES];
        [browser.windowController showWindow:self];
        
        return YES;
    }
}

- (void)handleURLEvent:(NSAppleEventDescriptor*)event
        withReplyEvent:(NSAppleEventDescriptor*)replyEvent
{
    NSString* url = [[event paramDescriptorForKeyword:keyDirectObject]
                      stringValue];
    url = [url substringFromIndex:5];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"AVNumberUpdate" object:url];
}

- (IBAction)goForum:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://leanclub.org"]];
}
- (IBAction)newTab:(id)sender {
    [browser addBlankTabInForeground:YES];
}
- (IBAction)closeTab:(id)sender {
    [browser closeTab];
}
- (IBAction)switchTab:(id)sender {
    [browser selectNextTab];
}
- (IBAction)prevTab:(id)sender {
    [browser selectPreviousTab];
}


@end