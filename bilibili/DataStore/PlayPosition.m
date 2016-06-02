//
//  PlayPosition.m
//  bilibili
//
//  Created by TYPCN on 2016/6/2.
//  Copyright © 2016 TYPCN. All rights reserved.
//

#import "PlayPosition.h"
#import <FMDB/FMDB.h>

@implementation PlayPosition{
    FMDatabase *db;
}

+ (instancetype)sharedManager {
    static id sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (id)init{
    if (self = [super init])
    {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
        NSString *ASDir = [paths firstObject];
        NSString *path = [NSString stringWithFormat:@"%@/com.typcn.bilibili/PlayPosition.db",ASDir];
        db = [FMDatabase databaseWithPath:path];
        if (![db open]) {
            NSLog(@"[PlayPositionManager] Can't open database: %@", [db lastErrorMessage]);
            [db close];
            return NULL;
        }else{
            [self initTable];
            [self trimData];
            NSLog(@"[PlayPositionManager] Database load success");
        }
    }
    return self;
}

- (BOOL)initTable{
    NSString *sql = @"CREATE TABLE IF NOT EXISTS play_position (id char(512) primary key,time integer,savetime integer);";
    
    BOOL success = [db executeStatements:sql];
    if(!success){
        NSLog(@"[PlayPositionManager] Table create failed: %@",[db lastErrorMessage]);
        return false;
    }
    
    return true;
}

- (BOOL)addKey:(NSString *)key time:(int64_t)ts{
    BOOL success = [db executeUpdate:@"UPDATE play_position SET time = ? WHERE id = ?", @(ts),key];
    if (!success) {
        NSLog(@"[PlayPositionManager] Update failed: %@", [db lastErrorMessage]);
        return false;
    }else if([db changes] == 0){
        BOOL success = [db executeUpdate:@"INSERT INTO play_position (id,time,savetime) VALUES (?, ?, ?)", key, @(ts), @(time(0))];
        if(!success){
            NSLog(@"[PlayPositionManager] Key insert failed:%@", [db lastErrorMessage]);
            return false;
        }else{
            return true;
        }
    }else{
        return true;
    }
}

- (int64_t)getKey:(NSString *)key{
    FMResultSet *s = [db executeQuery:@"SELECT * FROM play_position WHERE id = ?",key];
    while ([s next]) {
        return [s intForColumn:@"time"];
    }
    return 0;
}

- (BOOL)removeKey:(NSString *)key{
    BOOL success = [db executeUpdate:@"DELETE FROM play_position WHERE id = ?", key];
    if (!success) {
        NSLog(@"[PlayPositionManager] Delete failed: %@", [db lastErrorMessage]);
        return false;
    }
    return true;
}

- (void)trimData {
    long minSaveTime = time(0) - ( 3600 * 30 ); // Remove records before 30 days
    [db executeUpdate:@"DELETE FROM play_position WHERE savetime < ?", @(minSaveTime)];
}

@end
