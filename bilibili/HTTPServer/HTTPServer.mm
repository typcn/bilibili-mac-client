//
//  HTTPServer.m
//  bilibili
//
//  Created by TYPCN on 2015/9/7.
//  Copyright (c) 2015 TYPCN. All rights reserved.
//

#import "HTTPServer.h"
#import "Analytics.h"
#import "WebTabView.h"
#import "downloadWrapper.h"
#import <Sparkle/Sparkle.h>
#import <GCDWebServers/GCDWebServer.h>
#import <GCDWebServers/GCDWebServerDataRequest.h>
#import <GCDWebServers/GCDWebServerURLEncodedFormRequest.h>
#import <GCDWebServers/GCDWebServerMultiPartFormRequest.h>
#import <GCDWebServers/GCDWebServerDataResponse.h>

@implementation HTTPServer{
    long acceptAnalytics;
    NSString *cookie;
}

@synthesize playerWindowController;
@synthesize airplayWindowController;

- (void)startHTTPServer{
    NSUserDefaults *s = [NSUserDefaults standardUserDefaults];
    acceptAnalytics = [s integerForKey:@"acceptAnalytics"];
    
    if(!acceptAnalytics || acceptAnalytics == 1 || acceptAnalytics == 2){
        screenView("StartApplication");
    }
    [GCDWebServer setLogLevel:2];
    GCDWebServer* webServer = [[GCDWebServer alloc] init];
    
    
    [webServer addDefaultHandlerForMethod:@"GET"
                             requestClass:[GCDWebServerRequest class]
                             processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {
        
        GCDWebServerDataResponse *rep = [GCDWebServerDataResponse responseWithHTML:@"<html><body><p>Bilibili for mac http service</p></body></html>"];
        [rep setValue:@"*" forAdditionalHeader:@"Access-Control-Allow-Origin"];
        return rep;
                                 
    }];
    
    
    [webServer addHandlerForMethod:@"POST" path:@"/rpc" requestClass:[GCDWebServerURLEncodedFormRequest class] processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {
        NSDictionary *dic = [(GCDWebServerURLEncodedFormRequest*) request arguments];
        
        NSString *action = [dic valueForKey:@"action"];
        NSString *data = [dic valueForKey:@"data"];

        dispatch_async(dispatch_get_main_queue(), ^(void){
            if([action isEqualToString:@"playVideoByCID"]){
                [self playVideoByCID:data];
            }else if([action isEqualToString:@"showAirPlayByCID"]){
                [self showAirPlayByCID:data];
            }else if([action isEqualToString:@"downloadVideoByCID"]){
                [self downloadVideoByCID:data];
            }else if([action isEqualToString:@"checkforUpdate"]){
                [self checkForUpdates];
            }else if([action isEqualToString:@"showNotification"]){
                [self showNotification:data];
            }else if([action isEqualToString:@"setcookie"]){
                cookie = data;
            }
        });
        GCDWebServerDataResponse *rep = [GCDWebServerDataResponse responseWithText:@"ok"];
        [rep setValue:@"*" forAdditionalHeader:@"Access-Control-Allow-Origin"];
        return rep;
    }];
    [NSTimer scheduledTimerWithTimeInterval:20
                                     target:self
                                   selector:@selector(saveCookie)
                                   userInfo:nil
                                    repeats:YES];

    [webServer startWithOptions:@{
                                  @"Port":@23330,
                                  @"BindToLocalhost":@true,
                    } error:nil];
}

- (void)saveCookie{
    if(cookie && [cookie length] > 5){
        [[NSUserDefaults standardUserDefaults] setObject:cookie forKey:@"cookie"];
    }
}

- (void)showAirPlayByCID:(NSString *)cid
{
    vCID = cid;
    if(acceptAnalytics == 1){
        action("video", "play", [vCID cStringUsingEncoding:NSUTF8StringEncoding]);
        screenView("AirPlayView");
    }else if(acceptAnalytics == 2){
        screenView("AirPlayView");
    }else{
        NSLog(@"Analytics disabled ! won't upload.");
    }
    airplayWindowController =[[NSWindowController alloc] initWithWindowNibName:@"AirPlay"];
    [airplayWindowController showWindow:self];
}

- (void)playVideoByCID:(NSString *)cid
{
    if(parsing){
        return;
    }
    WebTabView *tv = (WebTabView *)[browser activeTabContents];
    if(!tv){
        return;
    }
    TWebView *wv = [tv GetTWebView];
    if(!wv){
        return;
    }
    NSArray *fn = [[wv getTitle] componentsSeparatedByString:@"_"];
    NSString *mediaTitle = [fn objectAtIndex:0];
    parsing = true;
    vCID = cid;
    vUrl = [wv getURL];
    if([mediaTitle length] > 0){
        vTitle = [fn objectAtIndex:0];
    }else{
        vTitle = NSLocalizedString(@"未命名", nil);
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:vUrl forKey:@"LastPlay"];
    NSLog(@"Video detected ! CID: %@",vCID);
    if(acceptAnalytics == 1){
        action("video", "play", [vCID cStringUsingEncoding:NSUTF8StringEncoding]);
        screenView("PlayerView");
    }else if(acceptAnalytics == 2){
        screenView("PlayerView");
    }else{
        NSLog(@"Analytics disabled ! won't upload.");
    }
    dispatch_async(dispatch_get_main_queue(), ^(void){
        NSStoryboard *storyBoard = [NSStoryboard storyboardWithName:@"Main" bundle:nil];
        playerWindowController = [storyBoard instantiateControllerWithIdentifier:@"playerWindow"];
        [playerWindowController showWindow:self];
    });
}

- (void)downloadVideoByCID:(NSString *)cid{
    WebTabView *tv = (WebTabView *)[browser activeTabContents];
    if(!tv){
        return;
    }
    id wv = [tv GetWebView];
    if(!wv){
        return;
    }
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[wv subviews][0] animated:YES];
    hud.mode = MBProgressHUDModeIndeterminate;
    hud.labelText = NSLocalizedString(@"正在启动下载引擎", nil);
    hud.removeFromSuperViewOnHide = YES;
    NSLog(@"[Downloader] init");
    if(!DL){
        DL = new Downloader();
    }
    
    if(acceptAnalytics == 1){
        action("video", "download", [cid cStringUsingEncoding:NSUTF8StringEncoding]);
        screenView("PlayerView");
    }else if(acceptAnalytics == 2){
        screenView("PlayerView");
    }else{
        NSLog(@"Analytics disabled ! won't upload.");
    }
    
    TWebView *twv = [tv GetTWebView];
    if(!twv){
        return;
    }
    
    NSLog(@"[Downloader] video name %@",[twv getTitle]);
    NSArray *fn = [[twv getTitle] componentsSeparatedByString:@"_"];
    NSString *filename = [fn objectAtIndex:0];
    
    dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        hud.labelText = NSLocalizedString(@"正在解析视频地址", nil);
        BOOL s = DL->newTask([cid intValue], filename);
        dispatch_async(dispatch_get_main_queue(), ^(void){
            if(s){
                hud.labelText = NSLocalizedString(@"成功开始下载", nil);
            }else{
                hud.labelText = NSLocalizedString(@"下载失败，请点击帮助 - 反馈", nil);
            }
            hud.mode = MBProgressHUDModeText;
            [hud hide:YES afterDelay:3];
            id ct = [browser createTabBasedOn:nil withUrl:@"http://static.tycdn.net/downloadManager/"];
            [browser addTabContents:ct inForeground:YES];
        });
    });
}

- (void)showNotification:(NSString *)content{
    WebTabView *tv = (WebTabView *)[browser activeTabContents];
    if(!tv){
        return;
    }
    id wv = [tv GetWebView];
    if(!wv){
        return;
    }
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[wv subviews][0] animated:YES];
    hud.mode = MBProgressHUDModeText;
    hud.labelText = content;
    hud.removeFromSuperViewOnHide = YES;
    [hud hide:YES afterDelay:3];
}

- (void)checkForUpdates
{
    [[SUUpdater sharedUpdater] checkForUpdates:nil];
    if(acceptAnalytics == 1 || acceptAnalytics == 2){
        action("App","CheckForUpdate","CheckForUpdate");
    }else{
        NSLog(@"Analytics disabled ! won't upload.");
    }
}

@end
