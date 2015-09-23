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

NSArray *vp_bili_get_url(int cid,int vType){
    NSUserDefaults *settingsController = [NSUserDefaults standardUserDefaults];
    
    if(vType == k_biliVideoType_live_flv){
        return vp_bili_get_live_url(cid, vType);
    }
    
    NSString *type = @"flv";
    if(vType == k_biliVideoType_mp4){
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