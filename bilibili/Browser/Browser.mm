//
//  Browser.m
//  bilibili
//
//  Created by TYPCN on 2015/9/3.
//  Copyright (c) 2016 TYPCN. All rights reserved.
//

#import "Browser.h"
#import "WebTabView.h"


NSString *userAgent = @"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_4) AppleWebKit/601.5.17 (KHTML, like Gecko) Version/9.1 Safari/601.5.17";
Downloader* DL;

@implementation Browser


// This method is called when a new tab is being created. We need to return a
// new CTTabContents object which will represent the contents of the new tab.
-(CTTabContents*)createBlankTabBasedOn:(CTTabContents*)baseContents {
    CTTabContents *tc =  [[WebTabView alloc] initWithBaseTabContents:baseContents];
    [tc setTitle:@"about:blank"];
    return tc;
}

-(CTTabContents*)createTabBasedOn:(CTTabContents*)baseContents withUrl:(NSString*) url{
    NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    return [self createTabBasedOn:baseContents withRequest:req andConfig:nil];
}

-(CTTabContents*)createTabBasedOn:(CTTabContents*)baseContents withRequest:(NSURLRequest*) req andConfig:(id)cfg{
    NSMutableURLRequest *re = [[NSMutableURLRequest alloc] init];
    re = (NSMutableURLRequest *) req.mutableCopy;
    NSUserDefaults *settingsController = [NSUserDefaults standardUserDefaults];
    NSString *xff = [settingsController objectForKey:@"xff"];
    if([xff length] > 4){
        [re setValue:xff forHTTPHeaderField:@"X-Forwarded-For"];
        [re setValue:xff forHTTPHeaderField:@"Client-IP"];
    }
    
    CTTabContents *tc = [[WebTabView alloc] initWithRequest:re andConfig:cfg];
    [tc setTitle:@"Loading"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"BLChangeURL" object:[req.URL absoluteString] userInfo:nil];
    return tc;
}

-(void)selectNextTab{
    [super selectNextTab];
    WebTabView *tv = (WebTabView *)[browser activeTabContents];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"BLChangeURL" object:[[tv GetTWebView] getURL]];
}

-(void)selectPreviousTab{
    [super selectPreviousTab];
    WebTabView *tv = (WebTabView *)[browser activeTabContents];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"BLChangeURL" object:[[tv GetTWebView] getURL]];
}

//
//-(CTTabContents*)createWKTabBasedOn:(CTTabContents*)baseContents withUrl:(NSString*) url{
//    [[NSNotificationCenter defaultCenter] postNotificationName:@"BLChangeURL" object:url userInfo:nil];
//    CTTabContents *tc = [[WKWebTabView alloc] initWithURL:url];
//    [tc setTitle:@"Loading"];
//    return tc;
//}

@end
