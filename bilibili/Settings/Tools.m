//
//  Tools.m
//  bilibili
//
//  Created by TYPCN on 2016/2/10.
//  Copyright © 2016 TYPCN. All rights reserved.
//

#import "Tools.h"
#import <WebKit/WebKit.h>

@interface Tools ()

@end

@implementation Tools

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

- (IBAction)clearCache:(id)sender {
    if (NSClassFromString(@"WKWebsiteDataStore")) {
        NSSet *websiteDataTypes = [NSSet setWithArray:@[
                                                        WKWebsiteDataTypeDiskCache,
                                                        WKWebsiteDataTypeMemoryCache
                                                        ]];
        [self removeCacheFor:websiteDataTypes];
    }else{
        [self showYMAlert];
    }

}

- (IBAction)clearLocalData:(id)sender {
    if (NSClassFromString(@"WKWebsiteDataStore")) {
        NSSet *websiteDataTypes = [NSSet setWithArray:@[
                                                        WKWebsiteDataTypeOfflineWebApplicationCache,
                                                        WKWebsiteDataTypeLocalStorage,
                                                        WKWebsiteDataTypeCookies,
                                                        WKWebsiteDataTypeSessionStorage,
                                                        WKWebsiteDataTypeIndexedDBDatabases,
                                                        WKWebsiteDataTypeWebSQLDatabases
                                                        ]];
        [self removeCacheFor:websiteDataTypes];

    }else{
        [self showYMAlert];
    }
}

- (void)removeCacheFor:(NSSet *)types{
    //// All kinds of data
    //NSSet *websiteDataTypes = [WKWebsiteDataStore allWebsiteDataTypes];
    //// Date from
    NSDate *dateFrom = [NSDate dateWithTimeIntervalSince1970:0];
    [[WKWebsiteDataStore defaultDataStore] removeDataOfTypes:types modifiedSince:dateFrom completionHandler:^{
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"清空完成"];
        [alert runModal];
    }];
}

- (IBAction)clearBiliCookie:(id)sender {
    NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (NSHTTPCookie *each in cookieStorage.cookies) {
        if([[each domain] containsString:@".bilibili.com"]){
            [cookieStorage deleteCookie:each];
        }
    }
    [[NSUserDefaults standardUserDefaults] setObject:@"" forKey:@"cookie"];
    dispatch_async(dispatch_get_main_queue(), ^(void){
        NSURL* URL = [NSURL URLWithString:@"http://localhost:23330/rpc"];
        NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:URL];
        request.HTTPMethod = @"POST";
        [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
        NSString *postdata = [NSString stringWithFormat:@"action=setcookie&data= "];
        request.HTTPBody = [postdata dataUsingEncoding:NSUTF8StringEncoding];
        NSURLConnection* connection = [NSURLConnection connectionWithRequest:request delegate:nil];
        [connection scheduleInRunLoop:[NSRunLoop mainRunLoop]
                              forMode:NSDefaultRunLoopMode];
        [connection start];
    });
    
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:@"清空完成"];
    [alert runModal];
}

- (IBAction)clearLocalCookie:(id)sender {
    NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (NSHTTPCookie *each in cookieStorage.cookies) {
        [cookieStorage deleteCookie:each];
    }
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:@"清空完成"];
    [alert runModal];
}

- (IBAction)clearURLCache:(id)sender {
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:@"清空完成"];
    [alert runModal];
}

- (void)showYMAlert{
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:@"对不起，OSX 10.10 不支持该功能"];
    [alert runModal];
}

@end
