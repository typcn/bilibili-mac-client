//
//  SubtitleProvider.m
//  bilibili
//
//  Created by TYPCN on 2016/3/6.
//  Copyright © 2016 TYPCN. All rights reserved.
//

#import "SubtitleProvider.h"

@implementation SubtitleProvider

- (BOOL) canHandle: (NSDictionary *)dict{
    return NO;
}
- (NSDictionary *) getSubtitle: (NSDictionary *)dict{
    return dict;
}

@end
