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
#import "PreloadManager.h"

#import <Sparkle/Sparkle.h>
#import <GCDWebServers/GCDWebServer.h>
#import <GCDWebServers/GCDWebServerDataRequest.h>
#import <GCDWebServers/GCDWebServerURLEncodedFormRequest.h>
#import <GCDWebServers/GCDWebServerMultiPartFormRequest.h>
#import <GCDWebServers/GCDWebServerDataResponse.h>

#import <QuartzCore/CoreImage.h>

int forceIPFake;

@implementation HTTPServer{
    long acceptAnalytics;
    NSString *cookie;
    BrowserExtInterface *browserEIF;
}

@synthesize playerWindowController;
@synthesize airplayWindowController;
@synthesize settingsWindowController;

- (void)startHTTPServer{
    NSUserDefaults *s = [NSUserDefaults standardUserDefaults];
    acceptAnalytics = [s integerForKey:@"acceptAnalytics"];
    
    if(!acceptAnalytics || acceptAnalytics == 1 || acceptAnalytics == 2){
        screenView("StartApplication");
    }
    
    browserEIF = [[BrowserExtInterface alloc] init];
    
    [GCDWebServer setLogLevel:2];
    GCDWebServer* webServer = [[GCDWebServer alloc] init];
    
    // Default handler
    
    [webServer addDefaultHandlerForMethod:@"GET"
                             requestClass:[GCDWebServerRequest class]
                             processBlock:^
     GCDWebServerResponse *(GCDWebServerRequest* request) {
        id plistinfo = [[NSBundle mainBundle] infoDictionary];
        NSDictionary *dic = @{
                               @"name":@"bilibili for mac http service",
                               @"version":[plistinfo objectForKey:@"CFBundleShortVersionString"],
                               @"build":[plistinfo objectForKey:@"CFBundleVersion"]
                               };
        GCDWebServerDataResponse *rep = [GCDWebServerDataResponse responseWithJSONObject:dic];
        [rep setValue:@"*" forAdditionalHeader:@"Access-Control-Allow-Origin"];
        return rep;
    }];
    
    [webServer addDefaultHandlerForMethod:@"OPTIONS"
                             requestClass:[GCDWebServerRequest class]
                             processBlock:^
     GCDWebServerResponse *(GCDWebServerRequest* request) {
         GCDWebServerDataResponse *rep = [GCDWebServerDataResponse responseWithStatusCode:200];
         
         NSString *origin = [request headers][@"origin"];
         if(!origin){
             origin = @"*";
         }
         NSString *corh = [request headers][@"access-control-request-headers"];
         if(corh){
             [rep setValue:corh forAdditionalHeader:@"Access-Control-Allow-Headers"];
         }
         [rep setValue:@"GET, POST" forAdditionalHeader:@"Access-Control-Allow-Methods"];
         [rep setValue:origin forAdditionalHeader:@"Access-Control-Allow-Origin"];
         return rep;
     }];
    
    // Static files

    NSString *webPath = [NSString stringWithFormat:@"%@/webpage/",[[NSBundle mainBundle] resourcePath]];
    [webServer addGETHandlerForBasePath:@"/static/" directoryPath:webPath indexFilename:nil cacheAge:3600 allowRangeRequests:false];
    
    
    NSString *tmpPath = [NSString stringWithFormat:@"%@/bilimac_http_serv/",NSTemporaryDirectory()];
    [webServer addGETHandlerForBasePath:@"/temp_content/" directoryPath:tmpPath indexFilename:nil cacheAge:3600 allowRangeRequests:true];
    
    [[NSFileManager defaultManager] createDirectoryAtPath:tmpPath
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:nil];
    
    // Blur image
    
    [webServer addHandlerForMethod:@"GET" pathRegex:@"/blur/.*"
                             requestClass:[GCDWebServerRequest class]
                        asyncProcessBlock:^
     (GCDWebServerRequest* request, GCDWebServerCompletionBlock completionBlock) {
         NSString *imgurl = [[request.URL path] stringByReplacingOccurrencesOfString:@"/blur/" withString:@""];
         NSLog(@"blur : %@",imgurl);
         dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
             NSData *img = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:imgurl]];
             if(!img){
                 completionBlock([GCDWebServerDataResponse responseWithStatusCode:500]);
                 return;
             }
             CIImage *imageToBlur = [CIImage imageWithData:img];
             if(!imageToBlur){
                 completionBlock([GCDWebServerDataResponse responseWithStatusCode:500]);
                 return;
             }
             CIFilter *filter = [CIFilter filterWithName: @"CIGaussianBlur"];
             [filter setValue:imageToBlur forKey:kCIInputImageKey];
             [filter setValue:[NSNumber numberWithFloat: 10] forKey: @"inputRadius"];
             CIImage *output = [filter valueForKey:kCIOutputImageKey];
             NSBitmapImageRep* rep = [[NSBitmapImageRep alloc] initWithCIImage:output];
             NSData* PNGData = [rep representationUsingType:NSPNGFileType properties:@{}];
             GCDWebServerDataResponse* response = [GCDWebServerDataResponse responseWithData:PNGData contentType:@"image/png"];
             [response setCacheControlMaxAge:3600];
             completionBlock(response);
         });
    }];
    
    // Action calling from web page
    
    [webServer addHandlerForMethod:@"POST" path:@"/rpc"
                      requestClass:[GCDWebServerURLEncodedFormRequest class]
                      processBlock:^
     GCDWebServerResponse *(GCDWebServerRequest* request) {
         
        NSDictionary *dic = [(GCDWebServerURLEncodedFormRequest*) request arguments];
        
        NSString *action = [dic valueForKey:@"action"];
        NSString *data = [dic valueForKey:@"data"];

        dispatch_async(dispatch_get_main_queue(), ^(void){
            if([action isEqualToString:@"playVideoByCID"]){
                NSArray *arr = [data componentsSeparatedByString:@"|"];
                if([arr count] == 1){
                    [self playVideoByCID:data withPage:nil title:nil];
                }else if([arr count] > 2){
                    [self playVideoByCID:arr[0] withPage:arr[1] title:arr[2]];
                }
                if([arr count] == 4){
                    forceIPFake = [arr[3] intValue];
                }
            }else if([action isEqualToString:@"preloadComment"]){
                [[PreloadManager sharedInstance] preloadComment:data];
            }else if([action isEqualToString:@"showAirPlayByCID"]){
                NSArray *arr = [data componentsSeparatedByString:@"|"];
                if([arr count] == 1){
                    [self showAirPlayByCID:data withPage:nil title:nil];
                }else if([arr count] > 2){
                    [self showAirPlayByCID:arr[0] withPage:arr[1] title:arr[2]];
                }
                
            }else if([action isEqualToString:@"downloadVideoByCID"]){
                NSArray *arr = [data componentsSeparatedByString:@"|"];
                if([arr count] == 1){
                    [self downloadVideoByCID:data withPage:nil title:nil];
                }else if([arr count] > 2){
                    [self downloadVideoByCID:arr[0] withPage:arr[1] title:arr[2]];
                }
            }else if([action isEqualToString:@"downloadComment"]){
                NSArray *arr = [data componentsSeparatedByString:@"|"];
                if([arr count] == 3){
                    [self downloadComment:arr[0] title:arr[2]];
                }
            }else if([action isEqualToString:@"checkforUpdate"]){
                [self checkForUpdates];
                [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
            }else if([action isEqualToString:@"showNotification"]){
                [self showNotification:data];
            }else if([action isEqualToString:@"showSettings"]){
                NSStoryboard *storyBoard = [NSStoryboard storyboardWithName:@"Main" bundle:nil];
                settingsWindowController = [storyBoard instantiateControllerWithIdentifier:@"prefWindow"];
                [settingsWindowController showWindow:self];
            }else if([action isEqualToString:@"installPlugIn"]){
                [self installPlugIn:data];
            }else if([action isEqualToString:@"updatePlugIn"]){
                [self installPlugIn:data];
            }else if([action isEqualToString:@"setcookie"]){
                cookie = data;
            }else if([action isEqualToString:@"goURL"]){
                WebTabView *tv = (WebTabView *)[browser activeTabContents];
                if(!tv){
                    return;
                }
                TWebView *twv = [tv GetTWebView];
                if(!twv){
                    return;
                }
                NSLog(@"GoURL: %@",data);
                [twv setURL:data];
            }else if([action isEqualToString:@"setVUrl"]){
                vUrl = data;
            }
        });
        GCDWebServerDataResponse *rep = [GCDWebServerDataResponse responseWithText:@"ok"];
        [rep setValue:@"*" forAdditionalHeader:@"Access-Control-Allow-Origin"];
        return rep;
    }];
    
    // Plugin Call
    
    [webServer addHandlerForMethod:@"POST" path:@"/pluginCall"
                      requestClass:[GCDWebServerDataRequest class]
                      processBlock:^
     GCDWebServerResponse *(GCDWebServerRequest* request) {
         
         NSDictionary *dic = [(GCDWebServerDataRequest*) request jsonObject];
         NSString *action = [dic valueForKey:@"action"];
         NSString *data = [dic valueForKey:@"data"];
         NSLog(@"Plugin call %@",action);
         VP_Plugin *plugin = [[PluginManager sharedInstance] Get:action];
         if(!plugin){
             return nil;
         }
         if([data isEqualToString:@"showSettings"]){
             [plugin openSettings];
             return nil;
         }
         bool canHandle = [plugin canHandleEvent:action];
         
         GCDWebServerDataResponse *rep = [GCDWebServerDataResponse responseWithText:@"done"];
         if(!canHandle){
             [rep setStatusCode:500];
         }else{
             NSString *url = [plugin processEvent:action :data];
             if(url && [url length] > 5){
                 [self playVideoByUrl:url];
             }else{
                 [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
             }
         }
         
         [rep setValue:@"*" forAdditionalHeader:@"Access-Control-Allow-Origin"];
         return rep;
     }];
    
    // Interactive interface
    
    [webServer addHandlerForMethod:@"POST" path:@"/interactive"
                      requestClass:[GCDWebServerURLEncodedFormRequest class]
                      processBlock:^
     GCDWebServerResponse *(GCDWebServerRequest* request) {
         
         NSDictionary *dic = [(GCDWebServerURLEncodedFormRequest*) request arguments];
         
         NSString *action = [dic valueForKey:@"action"];
         NSString *data = [dic valueForKey:@"data"];
         GCDWebServerDataResponse *rep = [GCDWebServerDataResponse responseWithText:@"ok"];
         
         if([action isEqualToString:@"pluginList"]){
             NSArray *arr = [[PluginManager sharedInstance] getList];
             rep = [GCDWebServerDataResponse responseWithJSONObject:arr];
         }else if([action isEqualToString:@"scriptList"]){
             NSArray *scList = [browserEIF GetScriptList];
             
             //NSString *str = [[PluginManager sharedInstance] javascriptForDomain:data];
             rep = [GCDWebServerDataResponse responseWithJSONObject:scList];
         }
         
         [rep setValue:@"*" forAdditionalHeader:@"Access-Control-Allow-Origin"];
         return rep;
     }];
    
    [NSTimer scheduledTimerWithTimeInterval:20
                                     target:self
                                   selector:@selector(saveCookie)
                                   userInfo:nil
                                    repeats:YES];

    [NSTimer scheduledTimerWithTimeInterval:2.5
                                     target:self
                                   selector:@selector(updateParser)
                                   userInfo:nil
                                    repeats:NO];
    
    [webServer startWithOptions:@{
                                  @"Port":@23330,
                                  @"BindToLocalhost":@true,
                    } error:nil];
}

- (void)updateParser{
    WebTabView *tv = (WebTabView *)[browser activeTabContents];
    if(!tv){
        return;
    }
    id wv = [tv GetWebView];
    if(!wv){
        return;
    }
    if([wv subviews] && [wv subviews][0]){
        [[PluginManager sharedInstance] install:@"com.typcn.vp.bilibili" :[wv subviews][0] :1];
    }
}

- (void)installPlugIn:(NSString *)name{
    WebTabView *tv = (WebTabView *)[browser activeTabContents];
    if(!tv){
        return;
    }
    id wv = [tv GetWebView];
    if(!wv){
        return;
    }
    if([wv subviews] && [wv subviews][0]){
        [[PluginManager sharedInstance] install:name :[wv subviews][0] :0];
    }
}

- (void)saveCookie{
    if(cookie && [cookie length] > 5){
        [[NSUserDefaults standardUserDefaults] setObject:cookie forKey:@"cookie"];
    }
}

- (void)showAirPlayByCID:(NSString *)cid withPage:(NSString *)pgUrl title:(NSString *)title
{
    vCID = cid;
    
    if(!pgUrl || !title){
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
        vUrl = [wv getURL];
        if([mediaTitle length] > 0){
            vTitle = [fn objectAtIndex:0];
        }else{
            vTitle = NSLocalizedString(@"未命名", nil);
        }
    }else{
        vTitle = [[title componentsSeparatedByString:@"_"] objectAtIndex:0];
        vUrl = pgUrl;
    }
    
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
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
}

- (void)playVideoByCID:(NSString *)cid withPage:(NSString *)pgUrl title:(NSString *)title
{
    if(parsing){
        return;
    }
    parsing = true;
    vCID = cid;

    if(!pgUrl || !title){
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
        vUrl = [wv getURL];
        if([mediaTitle length] > 0){
            vTitle = [fn objectAtIndex:0];
        }else{
            vTitle = NSLocalizedString(@"未命名", nil);
        }
    }else{
        vTitle = [[title componentsSeparatedByString:@"_"] objectAtIndex:0];
        vUrl = pgUrl;
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
        [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
    });
}

- (void)playVideoByUrl:(NSString *)Url
{
    if(parsing){
        return;
    }
//    WebTabView *tv = (WebTabView *)[browser activeTabContents];
//    if(!tv){
//        return;
//    }
//    TWebView *wv = [tv GetTWebView];
//    if(!wv){
//        return;
//    }
    parsing = true;
    vCID = @"LOCALVIDEO";
    vAID = Url;
    vUrl = Url;
    
    if(acceptAnalytics == 1){
        action("video", "play", "pluginVideo");
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
        [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
    });
}


- (void)downloadVideoByCID:(NSString *)cid withPage:(NSString *)pgUrl title:(NSString *)title
{
    NSString *fulltitle;
    id wvContentView;
    if(!pgUrl || !title){
        WebTabView *tv = (WebTabView *)[browser activeTabContents];
        if(!tv){
            return;
        }
        id wv = [tv GetWebView];
        if(!wv){
            return;
        }
        TWebView *twv = [tv GetTWebView];
        if(!twv){
            return;
        }
        vUrl = [twv getURL];
        wvContentView = [wv subviews][0];
        fulltitle = [twv getTitle];
    }else{
        vUrl = pgUrl;
        wvContentView = [[NSView alloc] init];
        fulltitle = title;
        WebTabView *tv = (WebTabView *)[browser activeTabContents];
        if(tv){
            id wv = [tv GetWebView];
            if(wv){
                wvContentView = [wv subviews][0];
            }
        }
    }

    vCID = cid;
    vPID = @"1";
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\/video\\/av(\\d+)(\\/index.html|\\/index_(\\d+).html)?" options:NSRegularExpressionCaseInsensitive error:nil];
    
    NSTextCheckingResult *match = [regex firstMatchInString:vUrl options:0 range:NSMakeRange(0, [vUrl length])];
    
    NSRange aidRange = [match rangeAtIndex:1];
    
    if(aidRange.length > 0){
        vAID = [vUrl substringWithRange:aidRange];
        NSRange pidRange = [match rangeAtIndex:3];
        if(pidRange.length > 0 ){
            vPID = [vUrl substringWithRange:pidRange];
        }
    }else{
        vAID = @"0";
    }
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:wvContentView animated:YES];
    hud.mode = MBProgressHUDModeIndeterminate;
    hud.labelText = NSLocalizedString(@"正在启动下载引擎", nil);
    hud.removeFromSuperViewOnHide = YES;
    NSLog(@"[Downloader] init");
    if(!DL){
        DL = new Downloader();
    }
    
    if(acceptAnalytics == 1){
        action("video", "download", [cid cStringUsingEncoding:NSUTF8StringEncoding]);
        screenView("DownloadView");
    }else if(acceptAnalytics == 2){
        screenView("DownloadView");
    }else{
        NSLog(@"Analytics disabled ! won't upload.");
    }
    
    NSLog(@"[Downloader] video name %@",fulltitle);
    NSArray *fn = [fulltitle componentsSeparatedByString:@"_"];
    NSString *filename = [fn objectAtIndex:0];
    
    dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        hud.labelText = NSLocalizedString(@"正在解析视频地址", nil);
        BOOL s = DL->newTask([cid intValue],vAID,vPID, filename);
        dispatch_async(dispatch_get_main_queue(), ^(void){
            if(s){
                hud.labelText = NSLocalizedString(@"成功开始下载", nil);
                NSDictionary *activeApp = [[NSWorkspace sharedWorkspace] activeApplication];
                NSString *activeName = (NSString *)[activeApp objectForKey:@"NSApplicationName"];
                if([activeName isEqualToString:@"Bilibili"]){
                    id ct = [browser createTabBasedOn:nil withUrl:@"http://static.tycdn.net/downloadManager/"];
                    [browser addTabContents:ct inForeground:YES];
                }
            }else{
                hud.labelText = NSLocalizedString(@"下载失败，请点击帮助 - 反馈", nil);
            }
            hud.mode = MBProgressHUDModeText;
            [hud hide:YES afterDelay:3];
        });
    });
}

- (void)downloadComment:(NSString *)cid title:(NSString *)title
{
    id wvContentView;
    wvContentView = [[NSView alloc] init];
    
    WebTabView *tv = (WebTabView *)[browser activeTabContents];
    if(tv){
        id wv = [tv GetWebView];
        if(wv){
            wvContentView = [wv subviews][0];
        }
    }
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:wvContentView animated:YES];
    hud.mode = MBProgressHUDModeIndeterminate;
    hud.labelText = NSLocalizedString(@"正在启动下载引擎", nil);
    hud.removeFromSuperViewOnHide = YES;
    NSLog(@"[Downloader] init");
    if(!DL){
        DL = new Downloader();
    }
    
    if(acceptAnalytics == 1){
        action("video", "cmdownload", [cid cStringUsingEncoding:NSUTF8StringEncoding]);
        screenView("DownloadView");
    }else if(acceptAnalytics == 2){
        screenView("DownloadView");
    }else{
        NSLog(@"Analytics disabled ! won't upload.");
    }
    
    NSLog(@"[Downloader] video name %@",title);
    NSArray *fn = [title componentsSeparatedByString:@"_"];
    NSString *filename = [fn objectAtIndex:0];
    
    dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        hud.labelText = NSLocalizedString(@"正在解析视频地址", nil);
        BOOL s = DL->downloadComment([cid intValue], filename);
        dispatch_async(dispatch_get_main_queue(), ^(void){
            if(s){
                hud.labelText = NSLocalizedString(@"弹幕下载完成", nil);
            }else{
                hud.labelText = NSLocalizedString(@"弹幕下载失败", nil);
            }
            hud.mode = MBProgressHUDModeText;
            [hud hide:YES afterDelay:3];
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
