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
@optional

@end

@interface TWebView : NSObject <WKNavigationDelegate, WKUIDelegate>{
    WebView *wv;
    WKWebView *WKwv;
    int webViewType;
}

@property (nonatomic, weak) id <TWebViewDelegate> delegate;

- (TWebView *)initWithURL:(NSString *)URL andDelegate:(id <TWebViewDelegate>)aDelegate;
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