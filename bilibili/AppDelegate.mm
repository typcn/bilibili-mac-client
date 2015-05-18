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


@end