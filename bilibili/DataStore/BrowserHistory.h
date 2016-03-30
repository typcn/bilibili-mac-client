//
//  BrowserHistory.h
//  bilibili
//
//  Created by TYPCN on 2016/1/25.
//  Copyright © 2016 TYPCN. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BrowserHistory : NSObject

+ (instancetype)sharedManager;
- (int64_t)insertURL:(NSString *)URL title:(NSString *)title;
- (NSArray *)get:(int)start count:(int)count;
- (NSArray *)getUnclosed;
- (void)resetStatus;
- (bool)setStatus:(int64_t)status forID:(int64_t)ID;
- (bool)deleteItem:(int64_t)ID;
- (bool)deleteAll;

@end
