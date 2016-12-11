//
//  PlayerManager.h
//  bilibili
//
//  Created by TYPCN on 2016/3/3.
//  Copyright © 2016 TYPCN. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Player.h"

@interface PlayerManager : NSObject

+ (instancetype)sharedInstance;

- (Player *)createPlayer:(NSString *)name withVideo:(VideoAddress *)video attrs:(NSDictionary *)dict;
- (Player *)getPlayer:(NSString *)name;

- (NSDictionary *)getPlayerList;

- (BOOL)removePlayer:(Player *)player;
- (BOOL)removePlayerWithName:(NSString *)name;

@end
