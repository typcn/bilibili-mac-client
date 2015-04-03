//
//  ViewController.m
//  bilibili
//
//  Created by TYPCN on 2015/3/30.
//  Copyleft 2015 TYPCN. All rights reserved.
//

#import "ViewController.h"
#import <Sparkle/Sparkle.h>

@import AppKit;

NSString *vUrl;
NSString *vCID;
NSString *userAgent;
NSWindow *currWindow;
BOOL parsing = false;

@implementation ViewController

- (BOOL)canBecomeMainWindow { return YES; }
- (BOOL)canBecomeKeyWindow { return YES; }

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}
- (IBAction)playClick:(id)sender {
    vUrl = [self.urlField stringValue];
    NSLog(@"USER INPUT: %@",vUrl);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view.window setBackgroundColor:NSColor.whiteColor];
    self.view.layer.backgroundColor = CGColorCreateGenericRGB(255, 255, 255, 1.0f);
    currWindow = self.view.window;
    [self.view.window makeKeyWindow];
    NSRect rect = [[NSScreen mainScreen] visibleFrame];
    [self.view setFrame:rect];
    
//    NSArray *cookieJar = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[NSURL URLWithString:@"http://interface.bilibili.com"]];
//    NSLog(@"%@",cookieJar);
}

@end

@implementation WebController


+(NSString*)webScriptNameForSelector:(SEL)sel
{
    if(sel == @selector(checkForUpdates))
        return @"checkForUpdates";
    return nil;
}

+ (BOOL)isSelectorExcludedFromWebScript:(SEL)sel
{
    if(sel == @selector(checkForUpdates))//JS对应的本地函数
        return NO;
    return YES; //返回 YES 表示函数被排除，不会在网页上注册
}

- (void)checkForUpdates
{
    [[SUUpdater sharedUpdater] checkForUpdates:nil];
}

- (void)awakeFromNib //当 WebContoller 加载完成后执行的动作
{
    [webView setFrameLoadDelegate:self];
    [webView setUIDelegate:self];
    [webView setFrameLoadDelegate:self];
    NSLog(@"Start");
    webView.mainFrameURL = @"http://www.bilibili.com";
}

- (WebView *)webView:(WebView *)sender createWebViewWithRequest:(NSURLRequest *)request
{
    return webView;
}

- (void)webView:(WebView *)sender decidePolicyForNavigationAction:(NSDictionary *)actionInformation request:(NSURLRequest *)request frame:(WebFrame *)frame decisionListener:(id<WebPolicyDecisionListener>)listener {
    
    webView.mainFrameURL = [actionInformation objectForKey:WebActionOriginalURLKey];
}

- (void)webView:(WebView *)webView decidePolicyForMIMEType:(NSString *)type request:(NSURLRequest *)request frame:(WebFrame *)frame
    decisionListener:(id<WebPolicyDecisionListener>)listener {
    if([type isEqualToString:@"application/x-shockwave-flash"]){
        [request webPlugInDestroy];
    }else{
        return;
    }
    
}

- (void)webView:(WebView *)sender didClearWindowObject:(WebScriptObject *)windowScriptObject forFrame:(WebFrame *)frame
{
     [windowScriptObject setValue:self forKeyPath:@"window.external"];
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
    if(parsing){
        return;
    }
    
    parsing = true;
    
    [webView stringByEvaluatingJavaScriptFromString:@"$(\".i-link[href='http://app.bilibili.com']\").html('检查更新').attr('href','javascript:window.external.checkForUpdates()');"];
    
    NSString *isLogged = [webView stringByEvaluatingJavaScriptFromString:@"$('.i_face').attr('src')"];
    
    if([isLogged length] < 5){
        [webView stringByEvaluatingJavaScriptFromString:@"$('.login').css('width',30).html('点击登陆客户端以便发送弹幕');"];
    }
    
    NSString *flashvars =  [webView stringByEvaluatingJavaScriptFromString:@"               \
                            $('object').attr('type','application/x-typcn-flashblock');      \
                                                                                            \
                            setTimeout(function(){                                          \
                                $('#bofqi').html('<center>正在召唤本地播放器</center>')        \
                            },3000);                                                        \
                                                                                            \
                            $('.close-btn-wrp').parent().remove();$('.float-pmt').remove(); \
                            var fv = $(\"param[name='flashvars']\").val();                  \
                            if(!fv){                                                        \
                                fv=$('#bofqi iframe').attr('src');                          \
                            }                                                               \
                            if(!fv){                                                        \
                                fv=$('embed').attr('flashvars');                            \
                            }                                                               \
                            fv                                                              \
                            "];

    userAgent =  [webView stringByEvaluatingJavaScriptFromString:@"navigator.userAgent"];

    

    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"cid=(\\d+)&" options:NSRegularExpressionCaseInsensitive error:nil];

    NSTextCheckingResult *match = [regex firstMatchInString:flashvars options:0 range:NSMakeRange(0, [flashvars length])];
    
    NSRange cidrange = [match rangeAtIndex:1];
    
    if(cidrange.length > 0){
        NSString *CID = [flashvars substringWithRange:cidrange];
        vCID = CID;
        vUrl = webView.mainFrameURL;
        NSLog(@"Video detected ! CID: %@",CID);
        [self.switchButton performClick:nil];
        
    }else{
        NSLog(@"Not video url. flashvar: %@",flashvars);
        parsing = false;
    }

}
- (IBAction)openAv:(id)sender {
    NSString *avNumber = [sender stringValue];
    if([[sender stringValue] length] > 0 ){
        if ([[avNumber substringToIndex:2] isEqual: @"av"]) {
            avNumber = [avNumber substringFromIndex:2];
        }
        
        webView.mainFrameURL = [NSString stringWithFormat:@"http://www.bilibili.com/video/av%@",avNumber];
        [sender setStringValue:@""];
    }
}

@end

@interface PlayerWindowController : NSWindowController

@end

@implementation PlayerWindowController{
    
}


@end