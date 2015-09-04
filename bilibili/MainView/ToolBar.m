//
//  ToolBar.m
//  bilibili
//
//  Created by TYPCN on 2015/9/4.
//  Copyright (c) 2015 TYPCN. All rights reserved.
//

#import "ToolBar.h"
#import "Common.hpp"
#import "WebTabView.h"

@interface BLToolBar ()


@end

@implementation BLToolBar

- (void)viewDidLoad {
    [super viewDidLoad];
}


@end


@interface BLToolBarEvents ()

@property (weak) IBOutlet NSTextField *URLInputField;

@end

@implementation BLToolBarEvents

- (void)setToolbarURL:(NSString *)url{
    [self.URLInputField setStringValue:url];
}

- (IBAction)goHome:(id)sender {
    WebTabView *tc = (WebTabView *)[browser activeTabContents];
    WebView *wv = [tc GetWebView];
    wv.mainFrameURL = @"http://www.bilibili.com";
    NSLog(@"home");
}
- (IBAction)Refresh:(id)sender {
    WebTabView *tc = (WebTabView *)[browser activeTabContents];
    WebView *wv = [tc GetWebView];
    wv.mainFrameURL = wv.mainFrameURL;
}
- (IBAction)forward:(id)sender {
    WebTabView *tc = (WebTabView *)[browser activeTabContents];
    WebView *wv = [tc GetWebView];
    [wv goForward];
}
- (IBAction)backward:(id)sender {
    WebTabView *tc = (WebTabView *)[browser activeTabContents];
    WebView *wv = [tc GetWebView];
    [wv goBack];
}
- (IBAction)menu:(id)sender {
    WebTabView *tc = (WebTabView *)[browser activeTabContents];
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:tc.view animated:YES];
    hud.mode = MBProgressHUDModeText;
    hud.labelText = @"暂未完成";
    hud.removeFromSuperViewOnHide = YES;
    [hud hide:YES afterDelay:3];
}

@end