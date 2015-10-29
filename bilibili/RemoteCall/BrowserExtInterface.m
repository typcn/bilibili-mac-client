//
//  BrowserExtInterface.m
//  bilibili
//
//  Created by TYPCN on 2015/10/12.
//  Copyright © 2015 TYPCN. All rights reserved.
//

#import "BrowserExtInterface.h"
#import "PluginManager.h"

@implementation BrowserExtInterface

- (NSArray *)GetScriptList{
    NSDictionary *dic = [[PluginManager sharedInstance] getScript];
    NSMutableArray *scList = [[NSMutableArray alloc] init];
    for(id site in dic){
        [scList addObject:@{
                            @"site":site,
                            @"script":dic[site]
                            }];
    }
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"webpage/inject" ofType:@"js"];
    NSString *WebScript = [[NSString alloc] initWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    path = [[NSBundle mainBundle] pathForResource:@"webpage/webui" ofType:@"html"];
    NSString* WebUI = [[NSString alloc] initWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    WebUI = [WebUI stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"];
    WebUI = [WebUI stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
    WebScript = [WebScript stringByReplacingOccurrencesOfString:@"INJ_HTML" withString:WebUI];
    
    [scList addObject:@{
                        @"site":@"bilibili.com",
                        @"script":WebScript
                        }];
    
    [scList addObject:@{
                        @"site":@"mimi.gg",
                        @"script":WebScript
                        }];
    
    return scList;
}

@end
