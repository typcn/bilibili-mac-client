//
//  Analytics.m
//  bilibili
//
//  Created by TYPCN on 2015/9/7.
//  Copyright (c) 2015 TYPCN. All rights reserved.
//

#import "Analytics.h"
#import <Cocoa/Cocoa.h>

void screenView(const char *view){
    NSUserDefaults *s = [NSUserDefaults standardUserDefaults];
    NSString *uuid = [s objectForKey:@"UUID"];
    NSOperatingSystemVersion version = [[NSProcessInfo processInfo] operatingSystemVersion];
    NSString *ver = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString *UA = [NSString stringWithFormat:@"Mozilla/5.0 (Macintosh; Intel Mac OS X %ld_%ld_%ld) AppleWebKit/601.1.43 (KHTML, like Gecko) Version/9.0 Safari/601.1.43 ",(long)version.majorVersion,(long)version.minorVersion,(long)version.minorVersion];
    NSString *POSTDATA = [NSString stringWithFormat:
                          @"v=1&tid=UA-53371941-5&cid=%@"
                          "&t=screenview&an=BilibiliMac"
                          "&av=%@&aid=com.typcn.bilimac"
                          "&cd=%s",uuid,ver,view];
    NSURL* URL = [NSURL URLWithString:@"http://www.google-analytics.com/collect"];
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:URL];
    request.HTTPMethod = @"POST";
    [request addValue:UA forHTTPHeaderField:@"User-Agent"];
    request.HTTPBody = [POSTDATA dataUsingEncoding:NSUTF8StringEncoding];
    NSURLConnection* connection = [NSURLConnection connectionWithRequest:request delegate:nil];
    [connection start];
}

void action(const char *type,const char *action,const char *label){
    NSUserDefaults *s = [NSUserDefaults standardUserDefaults];
    NSString *uuid = [s objectForKey:@"UUID"];
    NSOperatingSystemVersion version = [[NSProcessInfo processInfo] operatingSystemVersion];
    NSString *UA = [NSString stringWithFormat:@"Mozilla/5.0 (Macintosh; Intel Mac OS X %ld_%ld_%ld) AppleWebKit/601.1.43 (KHTML, like Gecko) Version/9.0 Safari/601.1.43",(long)version.majorVersion,(long)version.minorVersion,(long)version.minorVersion];
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
    [request addValue:UA forHTTPHeaderField:@"User-Agent"];
    NSURLConnection* connection = [NSURLConnection connectionWithRequest:request delegate:nil];
    [connection start];
}
