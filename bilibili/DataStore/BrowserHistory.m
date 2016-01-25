//
//  BrowserHistory.m
//  bilibili
//
//  Created by TYPCN on 2016/1/25.
//  Copyright © 2016 TYPCN. All rights reserved.
//

#import "BrowserHistory.h"
#include <sqlite3.h>

@implementation BrowserHistory{
    sqlite3 *db;
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
        NSString *path = [NSString stringWithFormat:@"%@/com.typcn.bilibili/History.db",ASDir];
        int status = sqlite3_open([path UTF8String], &db);
        if(status){
            NSLog(@"[HistoryManager] Can't open database: %s\n", sqlite3_errmsg(db));
            sqlite3_close(db);
            return NULL;
        }else{
            NSLog(@"[HistoryManager] Database load success");
        }
    }
    return self;
}

- (BOOL)initTable{
    char *sql = "CREATE TABLE browse_history IF NOT EXISTS ("  \
    "id integer primary key autoincrement," \
    "title char(64)," \
    "url char(256)," \
    "time integer," \
    "status integer);";
    char *err;
    sqlite3_exec(db, sql, NULL, NULL, &err);
    if(err){
        NSLog(@"[HistoryManager] Table create failed:%s",err);
        return false;
    }
    return true;
}

- (int)insertURL:(NSString *)URL title:(NSString *)title{
    char *err;
    char *zSQL = sqlite3_mprintf("INSERT INTO browse_history (title,url,time,status) VALUES ('%q', '%q', '%lld', 1)",[title UTF8String], [URL UTF8String],time(0));
    sqlite3_exec(db, zSQL, NULL, NULL, &err);
    if(err){
        NSLog(@"[HistoryManager] History insert failed:%s",err);
        return -1;
    }
    int lastRowId = (int)sqlite3_last_insert_rowid(db);
    return lastRowId;
}

- (bool)setStatus:(int)status forID:(int)ID{
    char *err;
    char *zSQL = sqlite3_mprintf("update browse_history set status=%lld where id=%lld",status,ID);
    sqlite3_exec(db, zSQL, NULL, NULL, &err);
    if(err){
        NSLog(@"[HistoryManager] History update failed:%s",err);
        return false;
    }
    return true;
}

- (bool)delete:(int)ID{
    char *err;
    char *zSQL = sqlite3_mprintf("delete from browse_history where id=%lld",ID);
    sqlite3_exec(db, zSQL, NULL, NULL, &err);
    if(err){
        NSLog(@"[HistoryManager] History delete failed:%s",err);
        return false;
    }
    return true;
}

@end
