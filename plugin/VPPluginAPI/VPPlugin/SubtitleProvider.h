//
//  SubtitleProvider.h
//  bilibili
//
//  Created by TYPCN on 2016/3/6.
//  Copyright © 2016 TYPCN. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SubtitleProvider : NSObject

- (BOOL) canHandle: (NSDictionary *)dict;
- (NSDictionary *) getSubtitle: (NSDictionary *)dict;

@end
