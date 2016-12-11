//
//  WevViewProvider.m
//  bilibili
//
//  Created by TYPCN on 2015/9/5.
//  Copyright (c) 2016 TYPCN. All rights reserved.
//

#import "TWebView.h"
#import "WebTabView.h"
#import "UserContentController.h"


@implementation TWebView{
    NSUserDefaults *settingsController;
    WKWebViewConfiguration *wvConfig;
}

- (void)dealloc{
    [WKwv removeObserver:self forKeyPath:@"title"];
}

- (TWebView *)initWithRequest:(NSURLRequest *)req andConfig:(id)cfg setDelegate:(id <TWebViewDelegate>)aDelegate{
    self = [super init];

    if (self.delegate != aDelegate) {
        self.delegate = aDelegate;
        settingsController =  [NSUserDefaults standardUserDefaults];
    }
    
    if (NSClassFromString(@"WKWebView")) {
        if(!cfg){
            wvConfig = [[WKWebViewConfiguration  alloc] init];
            wvConfig.userContentController = [UserContentController sharedInstance];
#ifdef DEBUG
            [wvConfig.preferences setValue:@YES forKey:@"developerExtrasEnabled"];
#endif
        }else{
            wvConfig = [cfg copy];
            wvConfig.userContentController = [UserContentController sharedInstance];
        }
        
        webViewType = tWKWebView;
        WKwv = [[WKWebView alloc] initWithFrame:NSZeroRect configuration:wvConfig];
        [WKwv setAutoresizingMask:NSViewMaxYMargin|NSViewMinXMargin|NSViewWidthSizable|NSViewMaxXMargin|NSViewHeightSizable|NSViewMinYMargin];
        [WKwv setNavigationDelegate: self];
        [WKwv setUIDelegate: self];
        [WKwv addObserver:self forKeyPath:@"title" options:NSKeyValueObservingOptionNew context:NULL];
    } else {
        webViewType = tWebView;
        wv = [[WebView alloc] init];
        [wv setAutoresizingMask:NSViewMaxYMargin|NSViewMinXMargin|NSViewWidthSizable|NSViewMaxXMargin|NSViewHeightSizable|NSViewMinYMargin];
        [wv setFrameLoadDelegate:self];
        [wv setUIDelegate:self];
        [wv setResourceLoadDelegate:self];
    
        
    }

    if(req){
        [NSTimer scheduledTimerWithTimeInterval:0.3
                                         target:self
                                       selector:@selector(loadRequest:)
                                       userInfo:req
                                        repeats:NO];
    }


    return self;
}
             
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"title"]){
        if (object == WKwv) {
            [self.delegate onTitleChange:WKwv.title];
        } else {
            [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        }
    }else{
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)loadRequest:(NSTimer*)timer{
    NSURLRequest *req = [timer userInfo];
    if(webViewType == tWKWebView){
        [WKwv loadRequest:req];
    }else{
        wv.mainFrameURL = [req.URL absoluteString];
    }
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

#pragma mark WebView delegate

- (BOOL) webView: (WebView *) webView shouldStartLoadWithRequest: (NSURLRequest *) request
{
    return [self.delegate shouldStartDecidePolicy: request];
}

- (void) webViewDidStartLoad: (WebView *) webView
{
    [self.delegate didStartNavigation];
}

- (void)webView:(WebView *)sender
didReceiveTitle:(NSString *)title
       forFrame:(WebFrame *)frame{
    [self.delegate didCommitNavigation];
}

- (void) webView: (WebView *) webView didFailLoadWithError: (NSError *) error
{
    [self.delegate failLoadOrNavigation: nil withError: error];
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
    [self.delegate finishLoadOrNavigation: nil];
}

- (NSURLRequest *)webView:(WebView *)sender
                 resource:(id)identifier
          willSendRequest:(NSURLRequest *)request
         redirectResponse:(NSURLResponse *)redirectResponse
           fromDataSource:(WebDataSource *)dataSource{
    NSString *URL = [request.URL absoluteString];
    NSMutableURLRequest *re = (NSMutableURLRequest *) request.mutableCopy;
    if([URL containsString:@"googlesyndication"] || [URL containsString:@"analytics.js"]){
        // Google ad is blocked in some (china) area, maybe take 30 seconds to wait for timeout
        [re setURL:[NSURL URLWithString:@"http://static.hdslb.com/images/transparent.gif"]];
    }else if([URL containsString:@"tajs.qq.com"]){
        // QQ analytics may block more than 10 seconds in some area
        [re setURL:[NSURL URLWithString:@"http://static.hdslb.com/images/transparent.gif"]];
    }else if([URL containsString:@"cnzz.com"]){
        // CNZZ is very slow in other country
        [re setURL:[NSURL URLWithString:@"http://static.hdslb.com/images/transparent.gif"]];
    }else if([URL containsString:@"cpro.baidustatic.com"]){
        // Baidu is very slow in other country
        [re setURL:[NSURL URLWithString:@"http://static.hdslb.com/images/transparent.gif"]];
    }else if([URL containsString:@".swf"]){
        // Block Flash
        NSLog(@"Block flash url:%@",URL);
        [re setURL:[NSURL URLWithString:@"http://static.hdslb.com/images/transparent.gif"]];
    }else if([URL containsString:@".eqoe.cn"]){
        [re setValue:@"http://client.typcn.com" forHTTPHeaderField:@"Referer"];
    }else{
        NSString *xff = [settingsController objectForKey:@"xff"];
        if([xff length] > 4){
            [re setValue:xff forHTTPHeaderField:@"X-Forwarded-For"];
            [re setValue:xff forHTTPHeaderField:@"Client-IP"];
        }
    }
    return re;
}

#pragma mark WKWebView delegate

- (void) webView: (WKWebView *) webView decidePolicyForNavigationAction: (WKNavigationAction *) navigationAction decisionHandler: (void (^)(WKNavigationActionPolicy)) decisionHandler
{
    BOOL shouldload = [self.delegate shouldStartDecidePolicy: [navigationAction request]];
    if(shouldload){
        decisionHandler(WKNavigationActionPolicyAllow);
    }else{
        decisionHandler(WKNavigationActionPolicyCancel);
    }
}

// 原本想拦截登录事件来获取 Cookie ，结果发现 B 站 Cookie 没有 HttpOnly ，JS 就可以读取了
//- (void)webView:(WKWebView *)webView
//decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse
//decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler{
//    NSURLResponse *resp = navigationResponse.response;
//    NSString *url = [resp.URL absoluteString];
//    
//    if([url containsString:@"https://account.bilibili.com/login/dologin"]){
//        
//    }else{
//        decisionHandler(WKNavigationResponsePolicyAllow);
//    }
//    
//    NSLog(@"%@",navigationResponse);
//}

- (void) webView: (WKWebView *) webView didStartProvisionalNavigation: (WKNavigation *) navigation
{
    [self.delegate didStartNavigation];
}

- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation{
    [self.delegate didCommitNavigation];
}

- (void) webView:(WKWebView *) webView didFailProvisionalNavigation: (WKNavigation *) navigation withError: (NSError *) error
{
    [self.delegate failLoadOrNavigation:nil withError: error];
}

- (void) webView: (WKWebView *) webView didFailNavigation: (WKNavigation *) navigation withError: (NSError *) error
{
    [self.delegate failLoadOrNavigation:nil withError: error];
}

- (void) webView: (WKWebView *) webView didFinishNavigation: (WKNavigation *) navigation
{
    [self.delegate finishLoadOrNavigation:nil];
}

- (WKWebView *)webView:(WKWebView *)webView
createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration
   forNavigationAction:(WKNavigationAction *)navigationAction
        windowFeatures:(WKWindowFeatures *)windowFeatures{
    WebTabView *ct;
    NSString *xff = [settingsController objectForKey:@"xff"];
    if([xff length] > 4){
        ct = (WebTabView *)[browser createTabBasedOn:nil withRequest:navigationAction.request andConfig:configuration];
    }else{
        ct = (WebTabView *)[browser createTabBasedOn:nil withRequest:nil andConfig:configuration];
    }
    [browser addTabContents:ct inForeground:YES];
    return [ct GetWebView];
}

- (WebView *)webView:(id)sender createWebViewWithRequest:(NSURLRequest *)request
{
    WebTabView *ct = (WebTabView *)[browser createTabBasedOn:nil withRequest:nil andConfig:nil];
    [browser addTabContents:ct inForeground:YES];
    return [ct GetWebView];
}
@end
