//
//  AutoSuggestTable.m
//  bilibili
//
//  Created by TYPCN on 2015/12/16.
//  Copyright © 2016 TYPCN. All rights reserved.
//

#import "AutoSuggestTable.h"
#import "PJTernarySearchTree.h"
#import "WebTabView.h"

extern NSString *sharedURLFieldString;

@implementation AutoSuggestTable{
    NSImage *icon_webpage;
    NSImage *icon_search;
    NSArray *item_cache;
    NSString *online_cache_key;
    NSMutableArray *online_cache;
}

- (id)init{
    if (self = [super init])
    {
        icon_webpage = [NSImage imageNamed:@"webpage"];
        icon_search = [NSImage imageNamed:@"search"];
    }
    return self;
}

- (BOOL)tableView:(NSTableView *)aTableView shouldSelectTableColumn:(NSTableColumn *)aTableColumn{
    
    return YES;
}


- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)rowIndex {
    int LocalCacheCount = (int)[item_cache count];
    int OnlineCacheIndex = (int)rowIndex - LocalCacheCount;
    if(LocalCacheCount > rowIndex){
        NSString *url = [item_cache objectAtIndex:rowIndex];
        WebTabView *tc = (WebTabView *)[browser activeTabContents];
        [[tc GetTWebView] setURL:url];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"BLChangeURL" object:url userInfo:nil];
    }else if([online_cache count] > OnlineCacheIndex){
        NSString *word = [online_cache objectAtIndex:OnlineCacheIndex];
        if(!word){
            return NO;
        }
        NSString *URL = [NSString stringWithFormat:@"http://search.bilibili.com/all?keyword=%@",[word stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        WebTabView *tc = (WebTabView *)[browser activeTabContents];
        [[tc GetTWebView] setURL:URL];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"BLChangeURL" object:URL userInfo:nil];
    }else if(rowIndex == 4){
        NSString *URL = [NSString stringWithFormat:@"http://search.bilibili.com/all?keyword=%@",[sharedURLFieldString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        WebTabView *tc = (WebTabView *)[browser activeTabContents];
        [[tc GetTWebView] setURL:URL];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"BLChangeURL" object:URL userInfo:nil];
    }else if(rowIndex == 5){
        NSString *URL = [NSString stringWithFormat:@"https://www.google.com/search?q=%@",[sharedURLFieldString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        WebTabView *tc = (WebTabView *)[browser activeTabContents];
        [[tc GetTWebView] setURL:URL];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"BLChangeURL" object:URL userInfo:nil];
    }
    return NO;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView{
    return 6;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn
            row:(NSInteger)rowIndex{
    BOOL isOLCacheOK = [sharedURLFieldString isEqualToString:online_cache_key];
    if(rowIndex == 0 && !isOLCacheOK){
        online_cache_key = [sharedURLFieldString copy];
        NSLog(@"[AddressBar] Finding suggest data");
        // Get 4 suggest from TST
        item_cache = [[PJTernarySearchTree sharedTree] retrievePrefix:sharedURLFieldString countLimit:4];
        // If no result , add http://
        if([item_cache count] == 0){
            NSString *urlAddPrefix = [NSString stringWithFormat:@"http://%@",sharedURLFieldString];
            item_cache = [[PJTernarySearchTree sharedTree] retrievePrefix:urlAddPrefix countLimit:4];
        }
        // Otherwise get from online
        [self loadOnlineResultAsync:aTableView];
    }
    if([aTableColumn.identifier isEqualToString:@"st_icon_col"]){
        if(rowIndex < 4){
            return icon_webpage;
        }else{
            return icon_search;
        }
    }else if([aTableColumn.identifier isEqualToString:@"st_name_col"]){
        if(rowIndex < 4){
            int LocalCacheCount = (int)[item_cache count];
            int OnlineCacheIndex = (int)rowIndex - LocalCacheCount;
            if(LocalCacheCount > rowIndex){
                return [item_cache objectAtIndex:rowIndex];
            }else if([online_cache count] > OnlineCacheIndex && isOLCacheOK){
                return [online_cache objectAtIndex:OnlineCacheIndex];
            }else{
                return @"No Result";
            }
        }else if(rowIndex == 4){
            return [NSString stringWithFormat:@"使用 Bilibili 搜索 %@",sharedURLFieldString];
        }else if(rowIndex == 5){
            return [NSString stringWithFormat:@"使用 Google 搜索 %@",sharedURLFieldString];
        }
        return @"ERROR";
    }else{
        return @"ERROR";
    }
}

- (void)loadOnlineResultAsync:(NSTableView *)tv{
    NSURLSessionConfiguration* sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    
    NSURLSession* session = [NSURLSession sessionWithConfiguration:sessionConfig delegate:nil delegateQueue:nil];
    
    NSString * URLSTR = [NSString stringWithFormat:@"http://s.search.bilibili.com/main/suggest?func=suggest&suggest_type=accurate&sub_type=tag&main_ver=v1&highlight=&userid=0&bangumi_acc_num=1&special_acc_num=0&topic_acc_num=0&upuser_acc_num=0&tag_num=10&special_num=0&bangumi_num=10&upuser_num=0&term=%@",[online_cache_key stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSString * currentKey = [online_cache_key copy];
    NSURL* URL = [NSURL URLWithString:URLSTR];
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:URL];
    request.HTTPMethod = @"GET";
    
    /* Start a new Task */
    NSURLSessionDataTask* task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error == nil) {
            if([currentKey isEqualToString:online_cache_key]){
                NSError *err;
                NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data options:0 error:&err];
                if(err || !dic){
                    return;
                }
                online_cache = [[NSMutableArray alloc] init];
                // FXXK Objective-C JSON processing
                if(dic[@"result"]){
                    if(dic[@"result"][@"accurate"] && dic[@"result"][@"accurate"][@"bangumi"]){
                        NSArray *b = dic[@"result"][@"accurate"][@"bangumi"];
                        if([b count] > 0){
                            for(int i = 0; i < [b count]; i++){
                                NSString *bgmName = [b objectAtIndex:i][@"value"];
                                if(bgmName){
                                    [online_cache addObject:bgmName];
                                }
                            }
                        }
                    }
                    if(dic[@"result"][@"tag"]){
                        NSArray *tags = dic[@"result"][@"tag"];
                        if([tags count] > 0){
                            for(int i = 0; i < [tags count]; i++){
                                NSString *tagName = [tags objectAtIndex:i][@"value"];
                                if(tagName){
                                    [online_cache addObject:tagName];
                                }
                            }
                        }
                    }
                }
                NSLog(@"[AddressBar] Online Suggest Load Succeeded with %lu object",(unsigned long)[online_cache count]);
                dispatch_async(dispatch_get_main_queue(), ^(void){
                    if(tv){
                        [tv reloadData];
                    }
                });
            }
        }
        else {
            // Failure
            NSLog(@"[AddressBar] Online Suggest Failed: %@", [error localizedDescription]);
        }
    }];
    [task resume];
}

@end
