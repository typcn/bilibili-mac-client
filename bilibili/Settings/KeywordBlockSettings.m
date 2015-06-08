//
//  KeywordBlockSettings.m
//  bilibili
//
//  Created by TYPCN on 2015/4/6.
//  Copyright (c) 2015 TYPCN. All rights reserved.
//

#import "KeywordBlockSettings.h"

@interface KeywordBlockSettings ()

@end

@implementation KeywordBlockSettings

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString *keywords = [[NSUserDefaults standardUserDefaults] objectForKey:@"blockKeywords"];
    if([keywords length] < 1){
        [self.textView setString:@"请输入关键词，一行一个"];
    }else{
        keywords = [keywords stringByReplacingOccurrencesOfString:@"|" withString:@"\n"];
        [self.textView setString:keywords];
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowWillClose:) name:NSWindowWillCloseNotification object:self.view.window];
}

- (void)windowWillClose:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    if(![[self.textView string] length]){
        [[NSUserDefaults standardUserDefaults] setObject:@"" forKey:@"blockKeywords"];
        return;
    }
    
    NSArray *array = [[self.textView string] componentsSeparatedByString:@"\n"];
    
    NSArray *cleanedArray = [[NSSet setWithArray:array] allObjects]; // 去重
    
    NSString *blockWords = [cleanedArray componentsJoinedByString:@"|"];
    
    //去首尾（空行）
    
    if([blockWords hasSuffix:@"|"]){
        blockWords = [blockWords substringToIndex:[blockWords length]-1];
    }
    if([blockWords hasPrefix:@"|"]){
        blockWords = [blockWords substringFromIndex:1];
    }
    
    NSLog(@"BlockWords is %@",blockWords);
    [[NSUserDefaults standardUserDefaults] setObject:blockWords forKey:@"blockKeywords"];
}

@end
