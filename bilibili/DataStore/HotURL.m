//
//  HotURL.m
//  bilibili
//
//  Created by TYPCN on 2016/1/25.
//  Copyright © 2016 TYPCN. All rights reserved.
//

#import "HotURL.h"
#import "PJTernarySearchTree.h"

@implementation HotURL{
    FMDatabase *db;
}

- (instancetype)initWithDatabase:(FMDatabase *)icdb{
    if (self = [super init])
    {
        db = icdb;
        [self initTable];
    }
    return self;
}

- (BOOL)initTable {
    NSString *sql = @"CREATE TABLE IF NOT EXISTS hot_url (url char(256) primary key,times integer);";
    
    BOOL success = [db executeStatements:sql];
    if(!success){
        NSLog(@"[HotURL] Table create failed: %@",[db lastErrorMessage]);
        return false;
    }
    return true;
}

- (BOOL)appendURL:(NSString *)URL{
    BOOL success = [db executeUpdate:@"UPDATE hot_url SET times = times + 1 WHERE url = ?", URL];
    if (!success) {
        NSLog(@"[HotURL] Update failed: %@", [db lastErrorMessage]);
        return false;
    }else if([db changes] == 0){
        BOOL success = [db executeUpdate:@"INSERT INTO hot_url (url,times) VALUES (?, 1)", URL];
        if(!success){
            NSLog(@"[HotURL] URL insert failed:%@", [db lastErrorMessage]);
            return false;
        }else{
            NSLog(@"[HotURL] URL inserted");
            return true;
        }
    }
    [self trimData];
    return true;
}

- (void)trimData {
    // Remove items more than 512
    FMResultSet *s = [db executeQuery:@"SELECT Count(*) FROM hot_url"];
    if([s next]) {
        int totalCount = [s intForColumnIndex:0];
        NSLog(@"Total count: %d",totalCount);
        if(totalCount > 512){
            
        }
    }
}

@end
