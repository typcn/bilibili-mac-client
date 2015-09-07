//
//  WevViewProvider.h
//  bilibili
//
//  Created by TYPCN on 2015/9/5.
//  Copyright (c) 2015 TYPCN. All rights reserved.
//

#import "Browser.h"
#import "Common.hpp"

#define tWKWebView 1
#define tWebView 0

@protocol TWebViewDelegate <NSObject>
- (BOOL) shouldStartDecidePolicy: (NSURLRequest *) request;
- (void) didStartNavigation;
- (void) didCommitNavigation;
- (void) failLoadOrNavigation: (NSURLRequest *) request withError: (NSError *) error;
- (void) finishLoadOrNavigation: (NSURLRequest *) request;
- (void) onTitleChange:(NSString *)str;
- (void) invokeJSEvent:(NSString *)action withData:(NSString *)data;
@end

@interface TWebView : NSObject <WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler>{
    WebView *wv;
    WKWebView *WKwv;
    int webViewType;
}

@property (nonatomic, weak) id <TWebViewDelegate> delegate;

- (TWebView *)initWithRequest:(NSURLRequest *)req andConfig:(id)cfg setDelegate:(id <TWebViewDelegate>)aDelegate;
- (void)addToView:(NSScrollView *)view;
- (void)setFrameSize:(NSRect)newFrame;
- (id)GetWebView;

- (void)setURL:(NSString *)url;
- (NSString *)getURL;
- (NSString *)getTitle;
- (void)runJavascript:(NSString *)str;

- (void)wgoForward;
- (void)wgoBack;

@end