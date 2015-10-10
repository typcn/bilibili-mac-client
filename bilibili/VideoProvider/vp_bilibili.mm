//
//  vp_bilibili.m
//  bilibili
//
//  Created by TYPCN on 2015/9/17.
//  Copyright © 2015 TYPCN. All rights reserved.
//

#include "vp_bilibili.h"
#import <CommonCrypto/CommonDigest.h>

extern NSString *APIKey;
extern NSString *APISecret;

NSString *randomStringWithLength(int len){
    NSString *letters = @"abcdefghijklmnopqrstuvwxyz0123456789";

    NSMutableString *randomString = [NSMutableString stringWithCapacity: len];
    
    for (int i=0; i<len; i++) {
        [randomString appendFormat: @"%C", [letters characterAtIndex: arc4random_uniform([letters length])]];
    }
    
    return randomString;
}

NSArray *vp_bili_get_url(int cid,NSString *aid,NSString *pid,int vType){
    NSUserDefaults *settingsController = [NSUserDefaults standardUserDefaults];
    
    if(vType == k_biliVideoType_live_flv){
        return vp_bili_get_live_url(cid, vType);
    }
    
    NSString *type = @"flv";
    if(vType == k_biliVideoType_mp4){
        type = @"mp4";
    }
    
    NSString *hwid = [[NSUserDefaults standardUserDefaults] objectForKey:@"hwid"];
    if([hwid length] < 4){
        hwid  = randomStringWithLength(16);
        [[NSUserDefaults standardUserDefaults] setObject:hwid forKey:@"hwid"];
    }
    
    NSString *param = [NSString stringWithFormat:@"platform=android&_device=android&_hwid=%@&_aid=%@&_tid=0&_p=%@&_down=0&cid=%d&quality=4&otype=json&appkey=%@&type=%@%@",hwid,aid,pid,cid,APIKey,type,APISecret];
    const char *cStr = [[param stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding] UTF8String];
    unsigned char digest[16];
    CC_MD5( cStr, (CC_LONG)strlen(cStr), digest ); // This is the md5 call
    
    NSMutableString *sign= [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [sign appendFormat:@"%02x", digest[i]];
    
    NSURL* URL = [NSURL URLWithString:[NSString stringWithFormat:@"http://interface.bilibili.com/playurl?platform=android&_device=android&_hwid=%@&_aid=%@&_tid=0&_p=%@&_down=0&cid=%d&quality=4&otype=json&appkey=%@&type=%@&sign=%@",hwid,aid,pid,cid,APIKey,type,sign]];
    
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:URL];
    request.HTTPMethod = @"GET";
    request.timeoutInterval = 5;
    [request setValue:@"Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/34.0.1847.116 Safari/537.36" forHTTPHeaderField:@"User-Agent"];
    
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
    if(error || !videoAddressJSONData){
        return NULL;
    }
    NSError *jsonError;
    NSMutableDictionary *videoResult = [NSJSONSerialization JSONObjectWithData:videoAddressJSONData options:NSJSONReadingMutableContainers error:&jsonError];
    
    if(jsonError){
        NSLog(@"JSON ERROR:%@",jsonError);
        return NULL;
    }
    
    NSArray *dUrls = [videoResult objectForKey:@"durl"];
    
    if([dUrls count] == 0){
        return NULL;
    }else{
        return dUrls;
    }
}

NSArray *vp_bili_get_live_url(int cid,int vType){
    // TODO
    return NULL;
}