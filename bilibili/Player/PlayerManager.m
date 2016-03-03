//
//  PlayerManager.m
//  bilibili
//
//  Created by TYPCN on 2016/3/3.
//  Copyright © 2016 TYPCN. All rights reserved.
//

#import "PlayerManager.h"

@implementation PlayerManager{
    NSMutableDictionary *players;
}

+ (instancetype)sharedInstance {
    static id sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (Player *)createPlayer:(NSString *)name withVideo:(VideoAddress *)video{
    Player *p = [[Player alloc] initWithVideo:video];
    [players insertValue:p inPropertyWithKey:name];
    NSLog(@"[PlayerManager] Create player %@",name);
    return p;
}

- (Player *)getPlayer:(NSString *)name{
    return [players objectForKey:name];
}

- (NSDictionary *)getPlayerList{
    return players;
}

- (BOOL)removePlayer:(Player *)player{
    for (id key in players) {
        Player *p = [players objectForKey:key];
        if(p == player){
            [self removePlayerWithName:key];
        }
    }
    return YES;
}

- (BOOL)removePlayerWithName:(NSString *)name{
    Player *p = [players objectForKey:name];
    if(!p){
        return YES;
    }
    [p stopAndDestory];
    [players removeObjectForKey:name];
    NSLog(@"[PlayerManager] Removed player %@",name);
    return true;
}

@end
