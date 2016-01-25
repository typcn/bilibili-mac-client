//
//  HotURL.m
//  bilibili
//
//  Created by TYPCN on 2016/1/25.
//  Copyright © 2016 TYPCN. All rights reserved.
//

#import "HotURL.h"
#import "PJTernarySearchTree.h"

#define MAX_URL_COUNT 512

@implementation HotURL{
    FMDatabase *db;
}

- (instancetype)initWithDatabase:(FMDatabase *)icdb path:(NSString *)path{
    if (self = [super init])
    {
        db = icdb;
        [self initTable];
        [self loadDataToTST:path];
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

- (void)loadDataToTST:(NSString *)path{
    PJTernarySearchTree *tree = [PJTernarySearchTree sharedTree];
    dispatch_async([tree sharedIndexQueue], ^(void){
        // For thread safety , create a new db instance
        FMDatabase *importdb = [FMDatabase databaseWithPath:path];
        if (![importdb open]) {
            return;
        }
        FMResultSet *s = [importdb executeQueryWithFormat:@"SELECT url FROM hot_url ORDER BY times DESC LIMIT 0,%d",MAX_URL_COUNT];
        int count = 0;
        while ([s next]) {
            count++;
            NSString *url = [s stringForColumn:@"url"];
            [tree insertString:url];
        }
        NSLog(@"[SearchTree] Imported %d hot url from database",count);
    });
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
            PJTernarySearchTree *tree = [PJTernarySearchTree sharedTree];
            dispatch_async([tree sharedIndexQueue], ^(void){
                [tree insertString:URL];
            });
            return true;
        }
    }
    [self trimData];
    return true;
}

- (void)trimData {
    // Remove items if content more than MAX_URL_COUNT
    FMResultSet *s = [db executeQuery:@"SELECT Count(*) FROM hot_url"];
    if([s next]) {
        int totalCount = [s intForColumnIndex:0];
        NSLog(@"[HotURL] Total count: %d",totalCount);
        if(totalCount > MAX_URL_COUNT){
            int needTrimCount = totalCount - MAX_URL_COUNT;
            NSLog(@"[HotURL] Will remove %d items",totalCount);
            FMResultSet *s = [db executeQueryWithFormat:@"SELECT * FROM hot_url ORDER BY times ASC LIMIT 0,%d",needTrimCount];
            while ([s next]) {
                NSString *url = [s stringForColumn:@"url"];
                [db executeUpdate:@"DELETE FROM hot_url WHERE url = ?", url];
            }
            
        }
    }
}

- (void)dealloc {
    [self trimData];
}

@end
