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

- (id)init {
    self = [super init];
    if(self){
        players = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (Player *)createPlayer:(NSString *)name withVideo:(VideoAddress *)video attrs:(NSDictionary *)dict{
    if(players[name]){
        NSLog(@"[PlayerManager] Failed to create player with duplicate key %@",name);
        return NULL;
    }
    Player *p = [[Player alloc] initWithVideo:video attrs:dict];
    [p setPlayerName:name];
    players[name] = p;
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
            break;
        }
    }
    return YES;
}

- (BOOL)removePlayerWithName:(NSString *)name{
    Player *p = [players objectForKey:name];
    if(!p){
        return YES;
    }
    [players removeObjectForKey:name];
    NSLog(@"[PlayerManager] Removed player %@",name);
    return true;
}

@end
