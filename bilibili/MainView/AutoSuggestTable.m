//
//  AutoSuggestTable.m
//  bilibili
//
//  Created by TYPCN on 2015/12/16.
//  Copyright © 2015 TYPCN. All rights reserved.
//

#import "AutoSuggestTable.h"
#import "PJTernarySearchTree.h"
#import "WebTabView.h"

extern NSString *sharedURLFieldString;

@implementation AutoSuggestTable{
    NSImage *icon_webpage;
    NSImage *icon_search;
    NSArray *item_cache;
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
    if([item_cache count] > rowIndex){
        NSString *url = [item_cache objectAtIndex:rowIndex];
        WebTabView *tc = (WebTabView *)[browser activeTabContents];
        [[tc GetTWebView] setURL:url];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"BLChangeURL" object:url userInfo:nil];
    }else if(rowIndex == 4){
        NSString *URL = [NSString stringWithFormat:@"http://search.bilibili.com/all?keyword=%@",sharedURLFieldString];
        WebTabView *tc = (WebTabView *)[browser activeTabContents];
        [[tc GetTWebView] setURL:URL];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"BLChangeURL" object:URL userInfo:nil];
    }else if(rowIndex == 5){
        NSString *URL = [NSString stringWithFormat:@"https://www.google.com/search?q=%@",sharedURLFieldString];
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
    if(rowIndex == 0){
        item_cache = [[PJTernarySearchTree sharedTree] retrievePrefix:sharedURLFieldString countLimit:4];
    }
    if([aTableColumn.identifier isEqualToString:@"st_icon_col"]){
        if(rowIndex < 4){
            return icon_webpage;
        }else{
            return icon_search;
        }
    }else if([aTableColumn.identifier isEqualToString:@"st_name_col"]){
        if(rowIndex < 4){
            if([item_cache count] > rowIndex){
                return [item_cache objectAtIndex:rowIndex];
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

@end
