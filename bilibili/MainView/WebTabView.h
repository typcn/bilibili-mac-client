//
//  WebTabView.h
//  bilibili
//
//  Created by TYPCN on 2015/9/3.
//  Copyright (c) 2015 TYPCN. All rights reserved.
//

#import "Browser.h"
#import "Common.hpp"
#import "TWebView.h"

@interface WebTabView : CTTabContents <TWebViewDelegate> {
    TWebView *webView;
}
@property (strong) NSWindowController* playerWindowController;

-(id)initWithRequest:(NSURLRequest *)req andConfig:(id)cfg;
-(id)GetWebView;
-(TWebView *)GetTWebView;

@end
