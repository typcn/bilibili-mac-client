//
//  PreloadManager.m
//  bilibili
//
//  Created by TYPCN on 2015/12/16.
//  Copyright © 2015 TYPCN. All rights reserved.
//

#import "PreloadManager.h"

@implementation PreloadManager{
    NSMutableDictionary *cmPreloadList;
}

+ (instancetype)sharedInstance {
    static id sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (void)preloadComment:(NSString *)cid{
    if(!cmPreloadList){
        cmPreloadList = [[NSMutableDictionary alloc] init];
    }
    NSURLSessionConfiguration* sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession* session = [NSURLSession sessionWithConfiguration:sessionConfig delegate:nil delegateQueue:nil];
    NSURL* URL = [NSURL URLWithString:
                  [NSString stringWithFormat:@"http://comment.bilibili.com/%@.xml",cid]];
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:URL];
    request.HTTPMethod = @"GET";
    
    /* Start a new Task */
    NSURLSessionDataTask* task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error == nil) {
            int code = (int)((NSHTTPURLResponse*)response).statusCode;
            if(code == 200){
                cmPreloadList[cid] = data;
                NSLog(@"[PreloadManager] Comment Preloaded for %@",cid);
            }else{
                NSLog(@"[PreloadManager] Comment Preload Failed: Status Code %d",code);
            }
        }
        else {
            NSLog(@"[PreloadManager] Comment Preload Failed: %@", [error localizedDescription]);
        }
    }];
    [task resume];
}

- (NSData *)GetComment:(NSString *)cid{
    if(!cid){
        return NULL;
    }
    return cmPreloadList[cid];
}

- (void)removeComment:(NSString *)cid{
    if(!cid){
        return;
    }
    [cmPreloadList removeObjectForKey:cid];
}
@end
