//
//  BrowserExtInterface.m
//  bilibili
//
//  Created by TYPCN on 2015/10/12.
//  Copyright © 2016 TYPCN. All rights reserved.
//

#import "BrowserExtInterface.h"
#import "PluginManager.h"
#import "BrowserHistory.h"
#import "CloudScript.h"

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
    WebScript = [NSString stringWithFormat:@"%@;%@",[WebScript stringByReplacingOccurrencesOfString:@"INJ_HTML" withString:WebUI],[[CloudScript sharedInstance] get]];
    
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

- (NSArray *)GetHistory:(int)page{
    BrowserHistory *bhm = [BrowserHistory sharedManager];
    if(bhm){
        int count = 50;
        int start = page * count;
        if(start > -1){
            return [bhm get:start count:count];
        }
    }
    return NULL;
}

- (BOOL)DelHistory:(NSString *)ids{
    if(!ids || [ids length] < 1){
        return false;
    }
    BrowserHistory *bhm = [BrowserHistory sharedManager];
    if(bhm){
        if([ids isEqualToString:@"ALL"]){
            return [bhm deleteAll];
        }else if(![ids containsString:@","]){
            return [bhm deleteItem:[ids longLongValue]];
        }
        NSArray *arr = [ids componentsSeparatedByString:@","];
        if([arr count] > 50){
            return false;
        }
        for (int i = 0; i < [arr count]; i++) {
            NSString *idx = [arr objectAtIndex:i];
            if(![bhm deleteItem:[idx longLongValue]]){
                return false;
            }
        }
        return true;
    }
    return false;
}

@end
