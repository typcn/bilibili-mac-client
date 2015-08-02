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

extern NSMutableArray *downloaderObjects;
extern NSLock *dList;
BOOL isStopped;

int downloadEventCallback(aria2::Session* session, aria2::DownloadEvent event,
                          aria2::A2Gid gid, void* userData)
{
    switch(event) {
        case aria2::EVENT_ON_DOWNLOAD_COMPLETE:{
            
            break;
        }
        case aria2::EVENT_ON_DOWNLOAD_ERROR:{
            NSUserNotification *notification = [[NSUserNotification alloc] init];
            notification.title = @"Bilibili Client";
            notification.informativeText = @"下载失败";
            notification.soundName = NSUserNotificationDefaultSoundName;
            [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
            break;
        }
        default:
            return 0;
    }
    return 0;
}

void Downloader::init(){
    mtx.lock();
    config.downloadEventCallback = downloadEventCallback;
    session = aria2::sessionNew(aria2::KeyVals(), config);
    aria2::changeGlobalOption(session, {{ "user-agent", "Mozilla/5.0 (Windows NT 6.1; WOW64; rv:6.0.2) Gecko/20100101 Firefox/6.0.2 Fengfan/1.0" }});
    mtx.unlock();
    NSLog(@"[Downloader] Init");
}

void Downloader::newTask(int cid,NSString *name){
    NSLog(@"[Downloader] New Task CID: %d",cid);
    mtx.lock();
    NSString *path = [NSString stringWithFormat:@"%@%@%@/",NSHomeDirectory(),@"/Movies/Bilibili/",name];
    aria2::changeGlobalOption(session, {{ "dir", [path cStringUsingEncoding:NSUTF8StringEncoding] }});
    
    aria2::KeyVals options;
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
        notification.informativeText = @"下载失败，无法解析视频";
        notification.soundName = NSUserNotificationDefaultSoundName;
        [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
        mtx.unlock();
    }
    if([[[urls valueForKey:@"url"] className] isEqualToString:@"__NSCFString"]){
        NSString *tmp = [urls valueForKey:@"url"];
        std::vector<std::string> uris = {[tmp cStringUsingEncoding:NSUTF8StringEncoding]};
        aria2::addUri(session, nullptr, uris, options);
    }else{
        for (NSDictionary *match in urls) {
            NSString *tmp = [match valueForKey:@"url"];
            std::vector<std::string> uris = {[tmp cStringUsingEncoding:NSUTF8StringEncoding]};
            aria2::addUri(session, nullptr, uris, options);
        }
    }
    
    NSLog(@"[Downloader] Download task added");
    
    mtx.unlock();
}

void Downloader::runDownload(int fileid,NSString *filename){
    
    NSLog(@"[Downloader] Starting download");
    NSString *cid = [[downloaderObjects objectAtIndex:fileid] valueForKey:@"cid"];
    mtx.lock();
    while(!isStopped) {
        int rv = aria2::run(session, aria2::RUN_ONCE);
        if(rv != 1) {
            break;
        }
        aria2::GlobalStat gstat = aria2::getGlobalStat(session);
        int allLength = 0;
        int currentLength = 0;
        std::vector<aria2::A2Gid> gids = aria2::getActiveDownload(session);
        for(const auto& gid : gids) {
            aria2::DownloadHandle* dh = aria2::getDownloadHandle(session, gid);
            if(dh) {
                allLength = allLength + (int)dh->getTotalLength();
                currentLength = currentLength + (int)dh->getCompletedLength();
                aria2::deleteDownloadHandle(dh);
            }
        }
        [dList lock];
        [downloaderObjects removeObjectAtIndex:fileid];
        NSDictionary *taskData = @{
                                    @"name":filename,
                                    @"status":[NSString stringWithFormat:@"剩余分段:%d 下载速度:%dKB/s 大小:%d/%dMB",gstat.numActive,gstat.downloadSpeed/1024,currentLength/1024/1024,allLength/1024/1024],
                                    @"cid":cid,
                                    @"lastUpdate":[NSString stringWithFormat:@"%lu",time(0)]
                                    };
        [downloaderObjects insertObject:taskData atIndex:fileid];
        [dList unlock];
    }
    int rv = aria2::sessionFinal(session);
    
    NSLog(@"Download success! STATUS: %d",rv);
    
    if(rv == 0){
        NSUserNotification *notification = [[NSUserNotification alloc] init];
        notification.title = filename;
        notification.informativeText = @"视频与弹幕下载完成";
        notification.soundName = NSUserNotificationDefaultSoundName;
        [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
    }
    [dList lock];
    if(!isStopped){
        [downloaderObjects removeObjectAtIndex:fileid];
        NSDictionary *taskData = @{
                                   @"name":filename,
                                   @"status":@"下载已完成",
                                   };
        [downloaderObjects insertObject:taskData atIndex:fileid];
    }else{
        
    }

    [dList unlock];
    mtx.unlock();
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