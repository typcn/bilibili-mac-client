//
//  downloadWrapper.cpp
//  bilibili
//
//  Created by TYPCN on 2015/6/6.
//  Copyright (c) 2016 TYPCN. All rights reserved.
//

#include "downloadWrapper.h"

#import "APIKey.h"
#import "vp_bilibili.h"
#import <CommonCrypto/CommonDigest.h>

BOOL Downloader::downloadComment(int cid,NSString *name){
    NSString *filteredName = [name stringByReplacingOccurrencesOfString:@"/" withString:@""];
    NSString *path = [NSString stringWithFormat:@"%@%@%@/",NSHomeDirectory(),@"/Movies/Bilibili/",filteredName];
    [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:NULL];
    NSString *commentUrl = [NSString stringWithFormat:@"http://comment.bilibili.com/%d.xml",cid];
    NSURL  *url = [NSURL URLWithString:commentUrl];
    NSData *data = [NSData dataWithContentsOfURL:url];
    if(!data){
        return false;
    }
    [data writeToFile:[NSString stringWithFormat:@"%@%d.xml",path,cid] atomically:YES];
    [[NSWorkspace sharedWorkspace]openFile:path withApplication:@"Finder"];
    return true;
}

BOOL Downloader::newTask(int cid,NSString* aid,NSString *pid,NSString *name){
    NSLog(@"[Downloader] New Task CID: %d",cid);
    
    NSString *filteredName = [name stringByReplacingOccurrencesOfString:@"/" withString:@""];
    NSString *path = [NSString stringWithFormat:@"%@%@%@/",NSHomeDirectory(),@"/Movies/Bilibili/",filteredName];

    [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:NULL];
    NSString *commentUrl = [NSString stringWithFormat:@"http://comment.bilibili.com/%d.xml",cid];
    NSURL  *url = [NSURL URLWithString:commentUrl];
    NSData *data = [NSData dataWithContentsOfURL:url];
    if(!data){
        return false;
    }
    [data writeToFile:[NSString stringWithFormat:@"%@%d.xml",path,cid] atomically:YES];
    
    NSLog(@"[Downloader] Comment downloaded");
    
    NSUserDefaults *settingsController = [NSUserDefaults standardUserDefaults];
    long isMP4 = [settingsController integerForKey:@"playMP4"];
    int vtype = k_biliVideoType_flv;
    if(isMP4 == 1){
        vtype = k_biliVideoType_mp4;
    }
    
    int sucCount = 0 ;
    int failCount = 0;
    
    NSArray  *urls = vp_bili_get_url(cid,aid,pid,vtype);
    if(!urls){
        NSLog(@"[Downloader] ERROR");
        NSUserNotification *notification = [[NSUserNotification alloc] init];
        notification.title = @"Bilibili Client";
        notification.informativeText = NSLocalizedString(@"下载失败，无法解析视频", nil);
        notification.soundName = NSUserNotificationDefaultSoundName;
        [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
        return false;
    }
    if([[[urls valueForKey:@"url"] className] isEqualToString:@"__NSCFString"]){
        NSString *tmp = [urls valueForKey:@"url"];
        NSString *taskid = [NSString stringWithFormat:@"%d-%ld",cid,time(0)];
        NSURL* URL = [NSURL URLWithString:@"http://localhost:23336/jsonrpc"];
        NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:URL];
        request.HTTPMethod = @"POST";
        NSDictionary* bodyObject = @{
                                     @"jsonrpc": @"2.0",
                                     @"id": taskid,
                                     @"method": @"aria2.addUri",
                                     @"params": @[
                                             @[tmp],
                                             @{
                                                 @"dir": path,
                                                 @"split": @"10",
                                                 @"max-connection-per-server" : @"10",
                                                 @"min-split-size": @"1M"
                                                 },
                                             ]
                                     };
        request.HTTPBody = [NSJSONSerialization dataWithJSONObject:bodyObject options:kNilOptions error:NULL];
        NSURLResponse * response = nil;
        NSError * error = nil;
        [NSURLConnection sendSynchronousRequest:request
                              returningResponse:&response
                                          error:&error];
        if(!error && [(NSHTTPURLResponse *)response statusCode] == 200){
            NSLog(@"Download Task Added");
            sucCount++;
        }else{
            failCount++;
            return false;
        }
    }else{
        for (NSDictionary *match in urls) {
            NSString *tmp = [match valueForKey:@"url"];
            NSString *taskid = [NSString stringWithFormat:@"%d-%ld",cid,time(0)];
            NSURL* URL = [NSURL URLWithString:@"http://localhost:23336/jsonrpc"];
            NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:URL];
            request.HTTPMethod = @"POST";
            NSDictionary* bodyObject = @{
                                         @"jsonrpc": @"2.0",
                                         @"id": taskid,
                                         @"method": @"aria2.addUri",
                                         @"params": @[
                                                 @[tmp],
                                                 @{
                                                     @"dir": path,
                                                     @"split": @"10",
                                                     @"max-connection-per-server" : @"10",
                                                     @"min-split-size": @"1M"
                                                     },
                                                 ]
                                         };
            request.HTTPBody = [NSJSONSerialization dataWithJSONObject:bodyObject options:kNilOptions error:NULL];
            NSURLResponse * response = nil;
            NSError * error = nil;
            [NSURLConnection sendSynchronousRequest:request
                                                    returningResponse:&response
                                                    error:&error];
            if(!error && [(NSHTTPURLResponse *)response statusCode] == 200){
                NSLog(@"Download Task Added");
                sucCount++;
            }else{
                failCount++;
                return false;
            }
            
            
        }
    }
    NSDictionary *activeApp = [[NSWorkspace sharedWorkspace] activeApplication];
    NSString *activeName = (NSString *)[activeApp objectForKey:@"NSApplicationName"];
    if(![activeName isEqualToString:@"Bilibili"]){
        NSString *vtypeStr = @"FLV";
        if(isMP4){
            vtypeStr = @"MP4";
        }
        NSUserNotification *notification = [[NSUserNotification alloc] init];
        notification.title = [NSString stringWithFormat:@"下载任务已开始 - %@",name];
        notification.informativeText = [NSString stringWithFormat:@"视频格式：%@ 成功分段：%d 失败分段：%d",vtypeStr,sucCount,failCount];
        notification.soundName = NSUserNotificationDefaultSoundName;
        [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
    }
    NSLog(@"[Downloader] Download task added");
    return true;
}