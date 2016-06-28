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
    NSMutableArray *providerList;
}

+ (instancetype)sharedInstance {
    static id sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (id)init{
    self = [super init];
    if(self){
        providerList = [@[
                         [[SP_Bilibili alloc] init],
                         [[SP_Local alloc] init]
                         ] mutableCopy];
    }
    return self;
}

- (void)addProvider: (SubtitleProvider *)prov{
    NSLog(@"[SubHelper] Adding subtitle provider %@", prov);
    [providerList addObject:prov];
}

- (BOOL) canHandle: (NSDictionary *)dict{
    for (SubtitleProvider *prov in providerList) {
        if([prov canHandle:dict]){
            NSLog(@"[SubHelper] Using subtitle provider %@",prov);
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
