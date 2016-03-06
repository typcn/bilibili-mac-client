//
//  SubtitleHelper.m
//  bilibili
//
//  Created by TYPCN on 2016/3/6.
//  Copyright © 2016 TYPCN. All rights reserved.
//

#import "SubtitleHelper.h"
#import "SP_Bilibili.h"
#import "SP_Local.h"

@implementation SubtitleHelper{
    NSArray *providerList;
}

- (id)init{
    self = [super init];
    if(self){
        providerList = @[
                         [[SP_Bilibili alloc] init],
                         [[SP_Local alloc] init]
                         ];
    }
    return self;
}

- (BOOL) canHandle: (NSDictionary *)dict{
    for (SubtitleProvider *prov in providerList) {
        if([prov canHandle:dict]){
            return YES;
        }
    }
    return NO;
}
- (NSDictionary *) getSubtitle: (NSDictionary *)dict{
    for (SubtitleProvider *prov in providerList) {
        if([prov canHandle:dict]){
            NSDictionary *sub = [prov getSubtitle:dict];
            if(sub){
                return sub;
            }
        }
    }
    return dict;
}

@end
