//
//  CloudScript.m
//  bilibili
//
//  Created by TYPCN on 2016/9/30.
//  Copyright © 2016 TYPCN. All rights reserved.
//

#import "CloudScript.h"

@implementation CloudScript {
    NSString *remoteScript;
    NSString *localCache;
}


+ (instancetype)sharedInstance {
    static id sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (id) init
{
    if (self = [super init])
    {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
        NSString *applicationSupportDirectory = [paths firstObject];
        localCache = [NSString stringWithFormat:@"%@/com.typcn.bilibili/cloud_script.js",applicationSupportDirectory];
        if([[NSFileManager defaultManager] fileExistsAtPath:localCache]){
            NSData *lcData = [[NSData alloc] initWithContentsOfFile:localCache];
            if(lcData){
                NSLog(@"[CloudScript] Found local script cache");
                remoteScript = [[NSString alloc] initWithData:lcData encoding:NSUTF8StringEncoding];
            }
        }else{
            remoteScript = @"console.log(\"Remote script not loaded\");";
        }
    }
    return self;
}


- (void)updateScript {
    int t = 0;

retry:;
    NSString *stringURL = [NSString stringWithFormat:@"https://static-ssl.tycdn.net/updates/bilimac.js?t=%ld",time(NULL)];
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:stringURL]];
    request.HTTPMethod = @"GET";
    request.timeoutInterval = 3;
    NSURLResponse * response = nil;
    NSError * error = nil;
    NSData * urlData = [NSURLConnection sendSynchronousRequest:request
                                    returningResponse:&response
                                                error:&error];
    
    if(error){
        t++;
        NSLog(@"[CloudScript] Update failed, retry %d",t);
        if( t > 3 ){
            remoteScript = @"console.log(\"Unable to load remote script\");";
            return;
        }
        goto retry;
    }
    
    
    [urlData writeToFile:localCache atomically:YES];
    remoteScript = [[NSString alloc] initWithData:urlData encoding:NSUTF8StringEncoding];
    
    NSLog(@"[CloudScript] Remote script updated!");
}

- (NSString *)get {
    return remoteScript;
}

@end
