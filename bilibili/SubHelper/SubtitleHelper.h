//
//  SubtitleHelper.h
//  bilibili
//
//  Created by TYPCN on 2016/3/6.
//  Copyright © 2016 TYPCN. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <VPPlugin/SubtitleProvider.h>

@interface SubtitleHelper : SubtitleProvider

+ (instancetype)sharedInstance;
- (void)addProvider: (SubtitleProvider *)prov;

@end
