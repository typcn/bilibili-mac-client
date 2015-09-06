//
//  downloadWrapper.cpp
//  bilibili
//
//  Created by TYPCN on 2015/6/6.
//  Copyright (c) 2015 TYPCN. All rights reserved.
//

#include "downloadWrapper.h"

#import "APIKey.h"
#import <CommonCrypto/CommonDigest.h>

BOOL isStopped;

//int downloadEventCallback(aria2::Session* session, aria2::DownloadEvent event,
//                          aria2::A2Gid gid, void* userData)
//{
//    switch(event) {
//        case aria2::EVENT_ON_DOWNLOAD_COMPLETE:{
//            
//            break;
//        }
//        case aria2::EVENT_ON_DOWNLOAD_ERROR:{
//            NSUserNotification *notification = [[NSUserNotification alloc] init];
//            notification.title = @"Bilibili Client";
//            notification.informativeText = NSLocalizedString(@"下载失败", nil);
//            notification.soundName = NSUserNotificationDefaultSoundName;
//            [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
//            break;
//        }
//        default:
//            return 0;
//    }
//    return 0;
//}

void Downloader::newTask(int cid,NSString *name){
    NSLog(@"[Downloader] New Task CID: %d",cid);
    NSString *path = [NSString stringWithFormat:@"%@%@%@/",NSHomeDirectory(),@"/Movies/Bilibili/",name];

    [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:NULL];
    NSString *commentUrl = [NSString stringWithFormat:@"http://comment.bilibili.com/%d.xml",cid];
    NSURL  *url = [NSURL URLWithString:commentUrl];
    NSData *data = [NSData dataWithContentsOfURL:url];
    [data writeToFile:[NSString stringWithFormat:@"%@%d.xml",path,cid] atomically:YES];
    
    NSLog(@"[Downloader] Comment downloaded");
    
    NSArray  *urls = getUrl(cid);
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
        NSURLConnection* connection = [NSURLConnection connectionWithRequest:request delegate:nil];
        [connection start];
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
            NSURLConnection* connection = [NSURLConnection connectionWithRequest:request delegate:nil];
            [connection start];
        }
    }
    
    NSLog(@"[Downloader] Download task added");
}

NSArray *Downloader::getUrl(int cid){
    NSUserDefaults *settingsController = [NSUserDefaults standardUserDefaults];
    long isMP4 = [settingsController integerForKey:@"DLMP4"];
    NSString *type = @"flv";
    if(isMP4 == 1){
        type = @"mp4";
    }
    
    NSString *param = [NSString stringWithFormat:@"appkey=%@&otype=json&cid=%d&quality=4&type=%@%@",APIKey,cid,type,APISecret];
    const char *cStr = [[param stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding] UTF8String];
    unsigned char digest[16];
    CC_MD5( cStr, (CC_LONG)strlen(cStr), digest ); // This is the md5 call
    
    NSMutableString *sign= [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [sign appendFormat:@"%02x", digest[i]];
    
    NSURL* URL = [NSURL URLWithString:[NSString stringWithFormat:@"http://interface.bilibili.com/playurl?appkey=%@&otype=json&cid=%d&quality=4&type=%@&sign=%@",APIKey,cid,type,sign]];
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:URL];
    request.HTTPMethod = @"GET";
    request.timeoutInterval = 5;
    [request addValue:@"Mozilla/5.0 (Windows NT 6.1; WOW64; rv:6.0.2) Gecko/20100101 Firefox/6.0.2 Fengfan/1.0" forHTTPHeaderField:@"User-Agent"];
    NSString *xff = [settingsController objectForKey:@"xff"];
    if([xff length] > 4){
        [request setValue:xff forHTTPHeaderField:@"X-Forwarded-For"];
        [request setValue:xff forHTTPHeaderField:@"Client-IP"];
    }
    NSURLResponse * response = nil;
    NSError * error = nil;
    NSData * videoAddressJSONData = [NSURLConnection sendSynchronousRequest:request
                                                          returningResponse:&response
                                                                      error:&error];
    if(!videoAddressJSONData){
        return NULL;
    }
    NSError *jsonError;
    NSMutableDictionary *videoResult = [NSJSONSerialization JSONObjectWithData:videoAddressJSONData options:NSJSONWritingPrettyPrinted error:&jsonError];

    return [videoResult objectForKey:@"durl"];
}