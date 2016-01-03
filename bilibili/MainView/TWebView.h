//
//  WevViewProvider.h
//  bilibili
//
//  Created by TYPCN on 2015/9/5.
//  Copyright (c) 2016 TYPCN. All rights reserved.
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
@end

#if MAC_OS_X_VERSION < MAC_OS_X_VERSION_10_11

@interface TWebView : NSObject <WebResourceLoadDelegate ,WebFrameLoadDelegate,WebUIDelegate,WKNavigationDelegate, WKUIDelegate>{
    WebView *wv;
    WKWebView *WKwv;
    int webViewType;
}

#else

@interface TWebView : NSObject <WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler>{
    WebView *wv;
    WKWebView *WKwv;
    int webViewType;
}

#endif

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