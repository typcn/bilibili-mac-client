//
//  ToolBar.m
//  bilibili
//
//  Created by TYPCN on 2015/9/4.
//  Copyright (c) 2016 TYPCN. All rights reserved.
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

@implementation BLToolBarEvents{
    time_t lastTabSwitch;
}

- (id)init{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateToolbarURL:) name:@"BLChangeURL" object:nil];
    return self;
}


- (void)finalize {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)updateToolbarURL:(NSNotification*) aNotification{
    lastTabSwitch = time(0);
    [self.URLInputField resignFirstResponder];
    CTTabContents *ct = [browser activeTabContents];
    if(ct) {
        [[browser window] makeFirstResponder:ct.view];
    }
    if(aNotification.object){
        NSString *url = aNotification.object;
        if(url && [url length] > 5){
            [self.URLInputField setStringValue:url];
        }
    }else{
        [NSTimer scheduledTimerWithTimeInterval:0.1
                                         target:self
                                       selector:@selector(delayUpdateURL)
                                       userInfo:nil
                                        repeats:NO];
        
    }
}

- (void)delayUpdateURL{
    WebTabView *tc = (WebTabView *)[browser activeTabContents];
    NSString *url = [[tc GetTWebView] getURL];
    if(url && [url length] > 5) {
        [self.URLInputField setStringValue:url];
    }else{
        [self.URLInputField setStringValue:@"invalid"];
    }
}

- (IBAction)OpenURL:(id)sender {
    [sender resignFirstResponder];
    [NSTimer scheduledTimerWithTimeInterval:0.2
                                     target:self
                                   selector:@selector(delayOpenURL)
                                   userInfo:nil
                                    repeats:NO];
}

- (void)delayOpenURL{
    if(time(0) - lastTabSwitch < 2){
        return;
    }
    CTTabContents *ct = [browser activeTabContents];
    if(ct) {
        [[browser window] makeFirstResponder:ct.view];
    }
    WebTabView *tc = (WebTabView *)[browser activeTabContents];
    id wv = [tc GetTWebView];
    NSString *url = [self.URLInputField stringValue];
    if([url length] < 3){
        return;
    }else if([url isEqualToString:[wv getURL]]){
        return;
    }else if([url containsString:@"http://"] || [url containsString:@"https://"]){
        [wv setURL:url];
    }else{
        [wv setURL:[NSString stringWithFormat:@"http://%@",url]];
    }
}


- (IBAction)goHome:(id)sender {
    WebTabView *tc = (WebTabView *)[browser activeTabContents];
    [[tc GetTWebView] setURL:@"https://www.bilibili.com"];
}
- (IBAction)Refresh:(id)sender {
    WebTabView *tc = (WebTabView *)[browser activeTabContents];
    NSString *u = [[tc GetTWebView] getURL];
    [[tc GetTWebView] setURL:u];
}
- (IBAction)forward:(id)sender {
    WebTabView *tc = (WebTabView *)[browser activeTabContents];
    [[tc GetTWebView] wgoForward];
}
- (IBAction)backward:(id)sender {
    WebTabView *tc = (WebTabView *)[browser activeTabContents];
    [[tc GetTWebView] wgoBack];
}
- (IBAction)menu:(id)sender {
    NSMenu *theMenu = [[NSMenu alloc] initWithTitle:@"Contextual Menu"];
    [theMenu setAutoenablesItems:YES];
    [[theMenu addItemWithTitle:NSLocalizedString(@"复制链接",nil) action:@selector(copyLink) keyEquivalent:@""] setTarget:self];
    [[theMenu addItemWithTitle:NSLocalizedString(@"下载管理",nil) action:@selector(dlMan) keyEquivalent:@""] setTarget:self];
    [[theMenu addItemWithTitle:NSLocalizedString(@"历史记录",nil) action:@selector(history) keyEquivalent:@""] setTarget:self];
    [[theMenu addItemWithTitle:NSLocalizedString(@"发送邮件",nil) action:@selector(contact) keyEquivalent:@""] setTarget:self];
    [[theMenu addItemWithTitle:NSLocalizedString(@"退出",nil) action:@selector(exit) keyEquivalent:@""] setTarget:self];
    [theMenu popUpMenuPositioningItem:nil atLocation:[NSEvent mouseLocation] inView:nil];
}

- (IBAction)universalVideoParse:(id)sender {
    dispatch_async(dispatch_get_main_queue(), ^(void){
        NSURL* URL = [NSURL URLWithString:@"http://localhost:23330/rpc"];
        NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:URL];
        request.HTTPMethod = @"POST";
        [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
        
        WebTabView *tv = (WebTabView *)[browser activeTabContents];
        NSString *pageURL = [[tv GetTWebView] getURL];
        NSString *escapedURL = [pageURL stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLFragmentAllowedCharacterSet]];
        NSString *postdata = [NSString stringWithFormat:@"action=uniplay&data=%@",escapedURL];
        request.HTTPBody = [postdata dataUsingEncoding:NSUTF8StringEncoding];
        NSURLConnection* connection = [NSURLConnection connectionWithRequest:request delegate:nil];
        [connection scheduleInRunLoop:[NSRunLoop mainRunLoop]
                              forMode:NSDefaultRunLoopMode];
        [connection start];
    });
}

- (void)copyLink{
    WebTabView *tv = (WebTabView *)[browser activeTabContents];
    [[NSPasteboard generalPasteboard] clearContents];
    [[NSPasteboard generalPasteboard] setString:[[tv GetTWebView] getURL]  forType:NSStringPboardType];
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[[tv GetWebView] subviews][0] animated:YES];
    hud.mode = MBProgressHUDModeText;
    hud.labelText = NSLocalizedString(@"当前页面地址已经复制到剪贴板", nil);
    hud.removeFromSuperViewOnHide = YES;
    [hud hide:YES afterDelay:3];
}

- (void)history{
    WebTabView *ct = (WebTabView *)[browser createTabBasedOn:nil withUrl:@"http://vp-hub.eqoe.cn/history.html"];
    [browser addTabContents:ct inForeground:YES];
}

- (void)dlMan{
    WebTabView *ct = (WebTabView *)[browser createTabBasedOn:nil withUrl:@"http://static-ssl.tycdn.net/downloadManager/v2/"];
    [browser addTabContents:ct inForeground:YES];
}

- (void)contact{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"mailto:typcncom@gmail.com"]];
}

- (void)exit{
    exit(0);
}

@end
