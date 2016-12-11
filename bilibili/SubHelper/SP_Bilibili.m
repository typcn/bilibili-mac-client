//
//  SP_Bilibili.m
//  bilibili
//
//  Created by TYPCN on 2016/3/6.
//  Copyright © 2016 TYPCN. All rights reserved.
//

#import "SP_Bilibili.h"
#import "PreloadManager.h"
#import "Common.hpp"

@implementation SP_Bilibili

- (BOOL) canHandle: (NSDictionary *)dict{
    if(dict && dict[@"cid"]){
        return YES;
    }
    return NO;
}

- (NSDictionary *) getSubtitle: (NSDictionary *)dict{
    if(dict[@"live"]){
        return dict;
    }
    NSString *vCID = dict[@"cid"];
    NSData *urlData = [[PreloadManager sharedInstance] GetComment:vCID];
    int t = 0;

cmDownload:
    
    if(!urlData && t < 3){
        NSString *stringURL = [NSString stringWithFormat:@"http://comment.bilibili.com/%@.xml",vCID];
        NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:stringURL]];
        request.HTTPMethod = @"GET";
        request.timeoutInterval = 3;
        
        [request setValue:userAgent forHTTPHeaderField:@"User-Agent"];
        
        NSURLResponse * response = nil;
        NSError * error = nil;
        urlData = [NSURLConnection sendSynchronousRequest:request
                                                   returningResponse:&response
                                                               error:&error];
        if(error){
            t++;
            NSLog(@"Comment download failed, retry %d",t);
            goto cmDownload;
        }
    }else{
        NSLog(@"Comment cache hit from PreloadManager");
    }
    
    NSMutableDictionary *rdict = [dict mutableCopy];
    
    if (!urlData)
    {
        if(rdict[@"title"]){
            rdict[@"title"] = [rdict[@"title"] stringByAppendingString:NSLocalizedString(@" - 弹幕下载失败", nil)];
            
        }
        return rdict;
    }
    
    NSString  *filePath = [NSString stringWithFormat:@"%@%@.cminfo.xml", NSTemporaryDirectory(),vCID];
    BOOL isSuc = [urlData writeToFile:filePath atomically:YES];
    if(!isSuc){
        if(rdict[@"title"]){
            rdict[@"title"] = [rdict[@"title"] stringByAppendingString:NSLocalizedString(@" - 弹幕保存失败", nil)];
            
        }
        return rdict;
    }
    
    
    rdict[@"commentFile"] = filePath;
    
    return rdict;
}

@end
