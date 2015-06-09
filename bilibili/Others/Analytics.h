//
//  Analytics.h
//  bilibili
//
//  Created by TYPCN on 2015/6/8.
//  Copyright (c) 2015 TYPCN. All rights reserved.
//

#ifndef bilibili_Analytics_h
#define bilibili_Analytics_h

#import <Foundation/Foundation.h>

void screenView(const char *view){
    NSUserDefaults *s = [NSUserDefaults standardUserDefaults];
    NSString *uuid = [s objectForKey:@"UUID"];
    NSString *ver = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString *POSTDATA = [NSString stringWithFormat:
                          @"v=1&tid=UA-53371941-5&cid=%@"
                          "&t=screenview&an=BilibiliMac"
                          "&av=%@&aid=com.typcn.bilimac"
                          "&cd=%s",uuid,ver,view];
    NSURL* URL = [NSURL URLWithString:@"http://www.google-analytics.com/collect"];
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:URL];
    request.HTTPMethod = @"POST";
    request.HTTPBody = [POSTDATA dataUsingEncoding:NSUTF8StringEncoding];
    NSURLConnection* connection = [NSURLConnection connectionWithRequest:request delegate:nil];
    [connection start];
}

void action(const char *type,const char *action,const char *label){
    NSUserDefaults *s = [NSUserDefaults standardUserDefaults];
    NSString *uuid = [s objectForKey:@"UUID"];
    NSString *ver = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSRect e = [[NSScreen mainScreen] frame];
    NSString *res = [NSString stringWithFormat:@"%fx%f",e.size.width,e.size.height];
    
    NSString *POSTDATA = [NSString stringWithFormat:
                          @"v=1&tid=UA-53371941-5&cid=%@"
                          "&t=event&an=BilibiliMac"
                          "&av=%@&aid=com.typcn.bilimac"
                          "&ec=%s&ea=%s&el=%s&sr=%@",uuid,ver,type,action,label,res];
    NSURL* URL = [NSURL URLWithString:@"http://www.google-analytics.com/collect"];
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:URL];
    request.HTTPMethod = @"POST";
    request.HTTPBody = [POSTDATA dataUsingEncoding:NSUTF8StringEncoding];
    NSURLConnection* connection = [NSURLConnection connectionWithRequest:request delegate:nil];
    [connection start];
}

#endif
