//
//  VP_YouGet.m
//  bilibili
//
//  Created by TYPCN on 2016/3/4.
//  Copyright © 2016 TYPCN. All rights reserved.
//

#import "VP_YouGet.h"
#import "PluginManager.h"

@implementation VP_YouGet

- (NSDictionary *)generateParamsFromURL: (NSString *)URL{    
    return @{
             @"url":URL
             };
}

- (VideoAddress *) getVideoAddress: (NSDictionary *)params{
    if(!params[@"url"]){
        [NSException raise:@VP_PARAM_ERROR format:@"CID Cannot be empty"];
        return NULL;
    }
    
    VP_Plugin *plugin = [[PluginManager sharedInstance] Get:@"youget-resolveAddr"];
    if(!plugin){
        [NSException raise:@VP_YG_NOT_INSTALLED format:@"您暂未安装 You-Get 模块，安装后即可解析全球大多数的视频网站，请点击新建标签按钮进入插件中心，在 You-Get 模块下方点击安装。"];
        return NULL;
    }
    
    NSString *url = params[@"url"];
    
    if([url containsString:@"www.bilibili.com"]){
        [self showAlert:@"B 站请直接点击页面上的播放按钮进行播放，通过 You-Get 播放将不能加载弹幕。"];
    }
    
    NSString *vresult = [plugin processEvent:@"youget-resolveAddr" :url];
    if(!vresult || ![vresult containsString:@"Real URLs:\n"]){
        [NSException raise:@VP_RESOLVE_ERROR format:@"视频解析失败，返回信息：\n%@",vresult];
        NSLog(@"YouGet-Callback:\n%@",vresult);
        return NULL;
    }
    
    VideoAddress *video = [[VideoAddress alloc] init];
    
    NSArray *arr = [vresult componentsSeparatedByString:@"Real URLs:\n"];
    NSArray *urls  = [arr[1] componentsSeparatedByString:@"\n"];
    int finalCount = 0;
    for(int i = 0; i < [urls count]; i++ )
    {
        NSString *path = [urls objectAtIndex:i];
        unsigned long realLength = strlen([path UTF8String]);
        
        if(i == 0){
            [video setFirstFragmentURL:path];
            [video addDefaultPlayURL:path];
            finalCount = 1;
        }else if(realLength > 0){
            NSURL* url = [NSURL URLWithString:path];
            if (url == nil) {
                NSLog(@"String is not url: %@", path);
            }else{
                [video addDefaultPlayURL:path];
                finalCount++;
            }
        }
    }
    NSLog(@"[VP_YouGet] YouGet-URL: %@",[video firstFragmentURL]);
    
    return video;
}

- (void)showAlert:(NSString *)text{
#ifdef __vp_enable_alert__
    dispatch_async(dispatch_get_main_queue(), ^{
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:text];
        [alert runModal];
    });
   
#endif
}

@end
