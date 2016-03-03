//
//  VideoProvider.m
//  bilibili
//
//  Created by TYPCN on 2016/3/3.
//  Copyright © 2016 TYPCN. All rights reserved.
//

#import "VideoProvider.h"

@implementation VideoProvider

+ (instancetype)sharedInstance {
    static id sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (NSDictionary *) generateParamsFromURL: (NSString *)url{
    return NULL;
}

- (VideoAddress *) getVideoAddress: (NSDictionary *)params{
    return NULL;
}

@end
