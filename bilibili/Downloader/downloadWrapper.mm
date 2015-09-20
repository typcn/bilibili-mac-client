//
//  downloadWrapper.cpp
//  bilibili
//
//  Created by TYPCN on 2015/6/6.
//  Copyright (c) 2015 TYPCN. All rights reserved.
//

#include "downloadWrapper.h"

#import "APIKey.h"
#import "vp_bilibili.h"
#import <CommonCrypto/CommonDigest.h>


BOOL Downloader::newTask(int cid,NSString *name){
    NSLog(@"[Downloader] New Task CID: %d",cid);
    NSString *path = [NSString stringWithFormat:@"%@%@%@/",NSHomeDirectory(),@"/Movies/Bilibili/",name];

    [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:NULL];
    NSString *commentUrl = [NSString stringWithFormat:@"http://comment.bilibili.com/%d.xml",cid];
    NSURL  *url = [NSURL URLWithString:commentUrl];
    NSData *data = [NSData dataWithContentsOfURL:url];
    [data writeToFile:[NSString stringWithFormat:@"%@%d.xml",path,cid] atomically:YES];
    
    NSLog(@"[Downloader] Comment downloaded");
    
    NSUserDefaults *settingsController = [NSUserDefaults standardUserDefaults];
    long isMP4 = [settingsController integerForKey:@"playMP4"];
    int vtype = k_biliVideoType_flv;
    if(isMP4 == 1){
        vtype = k_biliVideoType_mp4;
    }
    
    NSArray  *urls = vp_bili_get_url(cid, vtype);
    if(!urls){
        NSLog(@"[Downloader] ERROR");
        NSUserNotification *notification = [[NSUserNotification alloc] init];
        notification.title = @"Bilibili Client";
        notification.informativeText = NSLocalizedString(@"下载失败，无法解析视频", nil);
        notification.soundName = NSUserNotificationDefaultSoundName;
        [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
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
                                             @{@"dir": path}
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
        }else{
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
                                                 @{@"dir": path}
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
            }else{
                return false;
            }
            
            
        }
    }
    
    NSLog(@"[Downloader] Download task added");
    return true;
}