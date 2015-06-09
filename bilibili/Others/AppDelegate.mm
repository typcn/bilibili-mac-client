//
//  AppDelegate.m
//  bilibili
//
//  Created by TYPCN on 2015/3/30.
//  Copyleft 2015 TYPCN. All rights reserved.
//

#import "AppDelegate.h"
#include "aria2.hpp"

@interface AppDelegate ()

@end

@implementation AppDelegate

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
    }
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
        NSApplicationMain(0,NULL);
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

@end