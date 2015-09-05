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

@interface TWebView : NSObject{
    WebView *wv;
    WKWebView *WKwv;
    int webViewType;
}

- (TWebView *)initWithURL:(NSString *)URL;
- (void)addToView:(NSScrollView *)view;
- (void)setFrameSize:(NSRect)newFrame;


- (void)setURL:(NSString *)url;
- (NSString *)getURL;
- (NSString *)getTitle;
- (void)runJavascript:(NSString *)str;

@end
