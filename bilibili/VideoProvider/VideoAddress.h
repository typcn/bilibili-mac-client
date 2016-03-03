//
//  VideoAddress.h
//  bilibili
//
//  Created by TYPCN on 2016/3/3.
//  Copyright © 2016 TYPCN. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VideoAddress : NSObject

@property NSString *defaultPlayURL;
@property NSArray *backupPlayURLs;

@property NSString *userAgent;
@property NSString *cookie;

- (NSString *)nextPlayURL;

@end
