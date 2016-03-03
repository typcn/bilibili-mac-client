//
//  VideoProvider.h
//  bilibili
//
//  Created by TYPCN on 2016/3/3.
//  Copyright © 2016 TYPCN. All rights reserved.
//


// Don't use this class directly , Inherit it

#import <Foundation/Foundation.h>
#import "VideoAddress.h"

@interface VideoProvider : NSObject

+ (instancetype) sharedInstance;

- (NSDictionary *) generateParamsFromURL: (NSString *)url;
- (VideoAddress *) getVideoAddress: (NSDictionary *)params;

@end
