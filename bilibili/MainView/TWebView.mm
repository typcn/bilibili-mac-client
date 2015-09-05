//
//  WevViewProvider.m
//  bilibili
//
//  Created by TYPCN on 2015/9/5.
//  Copyright (c) 2015 TYPCN. All rights reserved.
//

// 为啥要这样而不是做 provider 类然后继承呢？其实主要是懒。。。加到原来的类就太乱了，不过先 make it works ， Clean 之后再说

#import "TWebView.h"
#import "WebTabView.h"

@implementation TWebView

- (TWebView *)initWithURL:(NSString *)URL andDelegate:(id <TWebViewDelegate>)aDelegate{
    if (self.delegate != aDelegate) {
        self.delegate = aDelegate;
    }
    if (NSClassFromString(@"WKWebView")) {
        webViewType = tWKWebView;
        WKwv = [[WKWebView alloc] init];
        [WKwv setAutoresizingMask:NSViewMaxYMargin|NSViewMinXMargin|NSViewWidthSizable|NSViewMaxXMargin|NSViewHeightSizable|NSViewMinYMargin];
        [WKwv setNavigationDelegate: self];
        [WKwv setUIDelegate: self];
    } else {
        webViewType = tWebView;
        wv = [[WebView alloc] init];
        [wv setAutoresizingMask:NSViewMaxYMargin|NSViewMinXMargin|NSViewWidthSizable|NSViewMaxXMargin|NSViewHeightSizable|NSViewMinYMargin];
        [wv setFrameLoadDelegate:self];
        [wv setUIDelegate:self];
        [wv setResourceLoadDelegate:self];
    }
    
    
    return self;
}

- (id)GetWebView{
    if(webViewType == tWKWebView){
        return WKwv;
    }else{
        return wv;
    }
}

- (void)addToView:(NSScrollView *)view{
    if(webViewType == tWKWebView){
        [view setDocumentView:WKwv];
    }else{
        [view setDocumentView:wv];
    }
}

- (void)setFrameSize:(NSRect)newFrame{
    if(webViewType == tWKWebView){
        [WKwv setFrame:newFrame];
    }else{
        [wv setFrame:newFrame];
    }
}

- (void)setURL:(NSString *)url {
    if(webViewType == tWKWebView){
        NSMutableURLRequest *re = [[NSMutableURLRequest alloc] init];
        [re setURL:[NSURL URLWithString:url]];
        NSUserDefaults *settingsController = [NSUserDefaults standardUserDefaults];
        NSString *xff = [settingsController objectForKey:@"xff"];
        if([xff length] > 4){
            [re setValue:xff forHTTPHeaderField:@"X-Forwarded-For"];
            [re setValue:xff forHTTPHeaderField:@"Client-IP"];
        }
        [WKwv loadRequest:re];
    }else{
        wv.mainFrameURL = url;
    }
}

- (NSString *)getURL{
    if(webViewType == tWKWebView){
        return [WKwv.URL absoluteString];
    }else{
        return wv.mainFrameURL;
    }
}

- (NSString *)getTitle{
    if(webViewType == tWKWebView){
        return WKwv.title;
    }else{
        return wv.mainFrameTitle;
    }
}

- (void)runJavascript:(NSString *)str{
    if(webViewType == tWKWebView){
        [WKwv evaluateJavaScript:str completionHandler:nil];
    }else{
        [wv stringByEvaluatingJavaScriptFromString:str];
    }
}

- (void)wgoForward{
    if(webViewType == tWKWebView){
        [WKwv goForward];
    }else{
        [wv goForward];
    }
}

- (void)wgoBack{
    if(webViewType == tWKWebView){
        [WKwv goBack];
    }else{
        [wv goBack];
    }
}

#pragma mark delegate events


- (BOOL) shouldStartDecidePolicy: (NSURLRequest *) request
{
    NSLog(@"should load , %@",request);
    return YES;
}

- (void) didStartNavigation
{
    NSLog(@"start load");
}

- (void) failLoadOrNavigation: (NSURLRequest *) request withError: (NSError *) error
{
    NSLog(@"load failed");
}

- (void) finishLoadOrNavigation: (NSURLRequest *) request
{
    NSLog(@"load finish");
}

#pragma mark WebView delegate

- (BOOL) webView: (WebView *) webView shouldStartLoadWithRequest: (NSURLRequest *) request
{
    return [self shouldStartDecidePolicy: request];
}

- (void) webViewDidStartLoad: (WebView *) webView
{
    [self didStartNavigation];
}

- (void) webView: (WebView *) webView didFailLoadWithError: (NSError *) error
{
    [self failLoadOrNavigation: nil withError: error];
}

- (void) webViewDidFinishLoad: (WebView *) webView
{
    [self finishLoadOrNavigation: nil];
}

#pragma mark WKWebView delegate

- (void) webView: (WKWebView *) webView decidePolicyForNavigationAction: (WKNavigationAction *) navigationAction decisionHandler: (void (^)(WKNavigationActionPolicy)) decisionHandler
{
    BOOL shouldload = [self shouldStartDecidePolicy: [navigationAction request]];
    if(shouldload){
        decisionHandler(WKNavigationActionPolicyAllow);
    }else{
        decisionHandler(WKNavigationActionPolicyCancel);
    }
}

- (void) webView: (WKWebView *) webView didStartProvisionalNavigation: (WKNavigation *) navigation
{
    [self didStartNavigation];
}

- (void) webView:(WKWebView *) webView didFailProvisionalNavigation: (WKNavigation *) navigation withError: (NSError *) error
{
    [self failLoadOrNavigation:nil withError: error];
}

- (void) webView: (WKWebView *) webView didFailNavigation: (WKNavigation *) navigation withError: (NSError *) error
{
    [self failLoadOrNavigation:nil withError: error];
}

- (void) webView: (WKWebView *) webView didFinishNavigation: (WKNavigation *) navigation
{
    [self finishLoadOrNavigation:nil];
}

- (WKWebView *)webView:(WKWebView *)webView
createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration
   forNavigationAction:(WKNavigationAction *)navigationAction
        windowFeatures:(WKWindowFeatures *)windowFeatures{
    NSString *url = [[navigationAction.request URL] absoluteString];
    WebTabView *ct = (WebTabView *)[browser createTabBasedOn:nil withUrl:url];
    [browser addTabContents:ct inForeground:YES];
    return [ct GetWebView];
}

- (WebView *)webView:(id)sender createWebViewWithRequest:(NSURLRequest *)request
{
    WebTabView *ct = (WebTabView *)[browser createTabBasedOn:nil withUrl:[request.URL absoluteString]];
    [browser addTabContents:ct inForeground:YES];
    return [ct GetWebView];
}
@end
