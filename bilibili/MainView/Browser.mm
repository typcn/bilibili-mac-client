//
//  Browser.m
//  bilibili
//
//  Created by TYPCN on 2015/9/3.
//  Copyright (c) 2015 TYPCN. All rights reserved.
//

#import "Browser.h"
#import "WebTabView.h"

NSString *vUrl;
NSString *vCID;
NSString *vTitle;
NSString *userAgent;
NSWindow *currWindow;
NSMutableArray *downloaderObjects;
Downloader* DL;
NSLock *dList = [[NSLock alloc] init];
BOOL parsing = false;

@implementation Browser


// This method is called when a new tab is being created. We need to return a
// new CTTabContents object which will represent the contents of the new tab.
-(CTTabContents*)createBlankTabBasedOn:(CTTabContents*)baseContents {
    CTTabContents *tc;
//    if (NSClassFromString(@"WKWebView")) {
//        tc = [[WKWebTabView alloc] initWithBaseTabContents:baseContents];
//    } else {
        tc = [[WebTabView alloc] initWithBaseTabContents:baseContents];
    //}
    [tc setTitle:@"about:blank"];
    return tc;
}

-(CTTabContents*)createTabBasedOn:(CTTabContents*)baseContents withUrl:(NSString*) url{
    NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    return [self createTabBasedOn:baseContents withRequest:req];
}

-(CTTabContents*)createTabBasedOn:(CTTabContents*)baseContents withRequest:(NSURLRequest*) req{
    CTTabContents *tc = [[WebTabView alloc] initWithRequest:req];
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
