//
//  PlayPosition.h
//  bilibili
//
//  Created by TYPCN on 2016/6/2.
//  Copyright © 2016 TYPCN. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PlayPosition : NSObject

+ (instancetype)sharedManager;
- (BOOL)addKey:(NSString *)key time:(int64_t)ts;
- (int64_t)getKey:(NSString *)key;
- (BOOL)removeKey:(NSString *)key;

@end
