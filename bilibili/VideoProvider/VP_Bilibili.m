//
//  VP_Bilibili.m
//  bilibili
//
//  Created by TYPCN on 2016/3/3.
//  Copyright © 2016 TYPCN. All rights reserved.
//

#import "VP_Bilibili.h"
#import "PluginManager.h"
#import "APIKey.h"

#import <CommonCrypto/CommonDigest.h>

@implementation VP_Bilibili{
    NSUserDefaults *ud;
    BOOL FLVFailRetry;
}

+ (instancetype)sharedInstance {
    static id sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (id)init{
    self = [super init];
    if(self) {
        ud = [NSUserDefaults standardUserDefaults];
        
        // HWID
        self.hwid = [ud objectForKey:@"hwid_2"];
        if([self.hwid length] < 4){
            self.hwid  = [self getRandomHWID];
            [ud setObject:self.hwid forKey:@"hwid_2"];
        }
        
        self.userAgent = @"Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/34.0.1847.116 Safari/537.36";
    }
    return self;
}

- (NSDictionary *)generateParamsFromURL: (NSString *)URL{
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    if([URL containsString:@"live.bilibili.com"]){
        params[@"aid"] = @"0";
        params[@"pid"] = @"0";
        params[@"url"] = URL;
        params[@"live"] = @"true";
        return params;
    }
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\/video\\/av(\\d+)(\\/index.html|\\/index_(\\d+).html)?" options:NSRegularExpressionCaseInsensitive error:nil];
    
    NSTextCheckingResult *match = [regex firstMatchInString:URL options:0 range:NSMakeRange(0, [URL length])];
    
    NSRange aidRange = [match rangeAtIndex:1];
    
    if(aidRange.length > 0){
        params[@"aid"] = [URL substringWithRange:aidRange];
        NSRange pidRange = [match rangeAtIndex:3];
        if(pidRange.length > 0 ){
            params[@"pid"] = [URL substringWithRange:pidRange];
        }else{
            params[@"pid"] = @"1";
        }
    }else{
        params[@"aid"] = @"0";
        params[@"pid"] = @"1";
    }
    
    params[@"url"] = URL;
    
    return params;
}

- (NSString *)getPlaybackRequestURL: (NSDictionary *)params{
    int quality = [self getQuality];
    NSString *type = [self getFormat:[params[@"download"] boolValue]];
    
    NSLog(@"[VP_Bilibili] AV: %@, CID: %@, PID: %@", params[@"aid"], params[@"cid"], params[@"pid"]);
    
    [self writeHistory:params[@"cid"] :params[@"aid"]];
    
//    NSString *req_path = [NSString stringWithFormat:@"platform=android&_device=android&_hwid=%@&_aid=%@&_tid=0&_p=%@&_down=0&cid=%@&quality=%d&otype=json&appkey=%@&type=%@",
//                          self.hwid, // Hardware ID ( Generate on first start )
//                          params[@"aid"], // Page ID ( AV )
//                          params[@"pid"], // Page Number
//                          params[@"cid"], // Video ID
//                          quality,APIKey,type];
//    
//    NSString *req_sign = [self getSign:req_path];
//    
//    NSString *req_url = [NSString stringWithFormat:@"http://interface.bilibili.com/playurl?%@&sign=%@",req_path,req_sign];

    int rnd = arc4random_uniform(9999);
    
    NSString *req_path = [NSString stringWithFormat:@"platform=android&cid=%@&quality=%d&otype=json&appkey=%@&type=%@&rnd=%d",
                          params[@"cid"], // Video ID
                          quality,APIKey,type,rnd];
    
    NSString *req_sign = [self getSign:req_path];
    
    NSString *req_url = [NSString stringWithFormat:@"http://interface.bilibili.com/playurl?%@&sign=%@",req_path,req_sign];
    
    NSLog(@"[VP_Bilibili] API Request URL: %@", req_url);
    
    return req_url;
}

- (NSString *)getLiveRequestURL: (NSDictionary *)params{
    NSLog(@"[VP_Bilibili] LiveRoom: %@", params[@"cid"]);
    
//    NSString *uuid = [[NSUUID UUID] UUIDString];
//    NSString *hwid = [self getRandomHWID];
//    
//    NSString *req_path = [NSString stringWithFormat:@"platform=android&_appver=406001&_buvid=%@infoc&_device=android&_hwid=%@&_aid=0&_tid=0&_p=%@&_down=0&cid=%@&quality=1&otype=json&appkey=%@&type=mp4",
//                          uuid, // BUVID ( Unkown , Random here )
//                          hwid, // Hardware ID ( Random here , avoid BUVID
//                          params[@"cid"], // Live room ID
//                          params[@"cid"], // Live room ID
//                          APIKey];
//
//    NSString *req_sign = [self getSign:req_path];
//    
//    NSString *req_url = [NSString stringWithFormat:@"http://live.bilibili.com/api/playurl?%@&sign=%@",req_path,req_sign];

    int rnd = arc4random_uniform(9999);
    
    NSString *req_path = [NSString stringWithFormat:@"platform=android&cid=%@&quality=1&otype=json&appkey=%@&type=mp4&rnd=%d",
                          params[@"cid"], // Video ID
                          APIKey,rnd];
    
    NSString *req_sign = [self getSign:req_path];
    
    NSString *req_url = [NSString stringWithFormat:@"http://live.bilibili.com/api/playurl?%@&sign=%@",req_path,req_sign];
    
    NSLog(@"[VP_Bilibili] API Request URL: %@", req_url);
    
    return req_url;
}

//  Complete params:
//      {
//          "cid":0,
//          "aid":0,
//          "pid":0,
//          "url":"",
//          "title":"",
//          "download":true
//      }

- (VideoAddress *) getVideoAddress: (NSDictionary *)params{
    if(!params[@"cid"]){
        [NSException raise:@VP_PARAM_ERROR format:@"CID Cannot be empty"];
        return NULL;
    }
                      
getUrl: NSLog(@"[VP_Bilibili] Getting video url");

    NSString *pbUrl;
    
    if(!params[@"live"]){
        pbUrl = [self getPlaybackRequestURL:params];
    }else{
        pbUrl = [self getLiveRequestURL:params];
    }
    
    NSURL* URL = [NSURL URLWithString:pbUrl];
    
    NSString *fakeIP = [self getFakeIP:params];

    NSDictionary *videoResult;
    
    // Their offical android/ios client is using dynamic downloaded lua to parse video
    // So I've implemented a lua interpreter , will find the appkey & secret automatically
    // My continuous integration server will build new dynamic library if new key detected
    // This program will download new dynamic library on startup, and verify the digital signature of  library, load it into memory
    
    
    // Build-in parser's result(ws.acgvideo.com/path.flv?*&or=xxx the "or" param) have speed limit , so use dynamic parser by default
    
#ifndef DEBUG
    VP_Plugin *plugin = [[PluginManager sharedInstance] Get:@"bilibili-resolveAddr"];
    if(plugin){
        NSLog(@"[VP_Bilibili] Using dynamic parser");
        videoResult = [self dynamicPluginParser:params];
    }else{
#endif
        NSLog(@"[VP_Bilibili] Dynamic parser not installed ( or running in debug mode )");
        NSLog(@"[VP_Bilibili] Using built-in parser");
        videoResult = [self sendAPIRequest:URL :fakeIP];
#ifndef DEBUG
    }
#endif

    
parseJSON: NSLog(@"[VP_Bilibili] Parsing result");
    
    NSArray *dUrls = [videoResult objectForKey:@"durl"];
    if([dUrls count] == 0){
        if(FLVFailRetry){
            FLVFailRetry = NO;
            NSLog(@"[VP_Bilibili] Retring using dynamic parser.");
            videoResult = [self dynamicPluginParser:params];
            goto parseJSON;
        }else{
            FLVFailRetry = YES;
            NSLog(@"[VP_Bilibili] Retring resolve with FLV format");
            goto getUrl;
        }
    }
    
    FLVFailRetry = NO;
    
    VideoAddress *video = [[VideoAddress alloc] init];
    [video setUserAgent:self.userAgent];
    
    BOOL URLisString = [[[dUrls valueForKey:@"url"] className] isEqualToString:@"__NSCFString"];
    
    if(URLisString){ // URL is String ( Some old videos , Single fragment )
        
        NSString *url = [dUrls valueForKey:@"url"];
        [video addDefaultPlayURL:url];
        [video setFirstFragmentURL:url];
        
    }else if([dUrls count] == 1){ // URL is Array ( Most MP4 videos, Single fragment )
        
        NSString *url = [[dUrls objectAtIndex:0] valueForKey:@"url"];
        [video addDefaultPlayURL:url];
        [video setFirstFragmentURL:url];
        
        NSArray *bUrls = [[dUrls objectAtIndex:0] valueForKey:@"backup_url"];
        if([bUrls count] > 0){
            for (NSString *burl in bUrls) {
                [video addBackupURL:@[burl]];
            }
        }
        
    }else{ // URL is Array ( Most FLV videos, Multi fragment )
        
        for (NSDictionary *match in dUrls) {
            NSString *url = [match valueForKey:@"url"];
            if(![[video firstFragmentURL] length]){ // Set first fragment url
                [video setFirstFragmentURL:url];
            }
            
            [video addDefaultPlayURL:url];
        }
        
    }
    
    // Sina old video ( only flv )
    if([[video firstFragmentURL] isEqualToString:@"http://v.iask.com/v_play_ipad.php?vid=false"]){
        FLVFailRetry = YES;
        NSLog(@"[VP_Bilibili] Retring resolve with FLV format");
        goto getUrl;
    }
    
    // Anti Hot Linking

    if([[video firstFragmentURL] containsString:@".hdslb."] || // *.hdslb.* only have static content
       [[video firstFragmentURL] containsString:@".bilibili.com"] // Main site only have webpage/API
                                                                ){
        NSLog(@"[VP_Bilibili] Anti-Hotlinking video detected! use dynamic parser.");
        videoResult = [self dynamicPluginParser:params];
        goto parseJSON;
    }
    
    return video;
}

- (NSDictionary *)sendAPIRequest: (NSURL *)URL :(NSString *)fakeIP{
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:URL];
    request.HTTPMethod = @"GET";
    request.timeoutInterval = 5;
    
    
    if(fakeIP){
        [request setValue:fakeIP forHTTPHeaderField:@"X-Forwarded-For"];
        [request setValue:fakeIP forHTTPHeaderField:@"Client-IP"];
    }
    
//    [request setValue:[ud objectForKey:@"cookie"] forHTTPHeaderField:@"Cookie"];
//    [request setValue:self.userAgent forHTTPHeaderField:@"User-Agent"];
//    [request setValue:@"trailers" forHTTPHeaderField:@"TE"];

    [request setValue:@"Mozilla/5.0 (Windows NT 6.3; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2272.118 Safari/537.36" forHTTPHeaderField:@"User-Agent"];
    [request setValue:@"http://interface.bilibili.com/" forHTTPHeaderField:@"Referer"];
    [request setValue:@"gzip, deflate, sdch" forHTTPHeaderField:@"Accept-Encoding"];
    [request setValue:@"text/html, application/xhtml+xml, application/xml; q=0.9, image/webp, */*; q=0.8" forHTTPHeaderField:@"Accept"];

    NSURLResponse * response = nil;
    NSError * error = nil;
    NSData * respData = [NSURLConnection sendSynchronousRequest:request
                                              returningResponse:&response
                                                          error:&error];
    if(error || !respData){
        NSLog(@"[VP_Bilibili] API Request Error: %@",error);
        [NSException raise:@VP_BILI_API_ERROR format:@"视频解析出现错误，返回内容为空，可能的原因：\n1. 您的网络连接出现故障\n2. Bilibili API 服务器出现故障\n请尝试以下步骤：\n1. 更换网络连接或重启电脑\n2. 可能触发了频率限制，请更换 IP 地址\n\n如果您确信是软件问题，请点击帮助 -- 反馈"];
        return NULL;
    }
    
    NSMutableDictionary *videoResult = [NSJSONSerialization JSONObjectWithData:respData options:0 error:&error];
    
    if(error){
        NSLog(@"[VP_Bilibili] JSON Parse Error: %@",error);
        [NSException raise:@VP_BILI_JSON_ERROR format:@"视频解析出现错误，JSON 解析失败，可能的原因：\n1. 您的网络被劫持\n2. Bilibili 服务器出现故障\n请尝试以下步骤：\n1. 尝试更换网络\n2. 过一会再试\n\n如果您确信是软件问题，请点击帮助 -- 反馈"];
        return NULL;
    }
    
    return videoResult;
}

- (NSDictionary *)dynamicPluginParser: (NSDictionary *)params{
    VP_Plugin *plugin = [[PluginManager sharedInstance] Get:@"bilibili-resolveAddr"];
    if(plugin){
        // Generate plugin message ( old format )
        // TODO: Update plugin params
        int intcid = [params[@"cid"] intValue];
        int quality = [self getQuality];
        int intIsMp4 = 0;
        NSString *type = [self getFormat:[params[@"download"] boolValue]];
        if([type isEqualToString:@"mp4"]){
            intIsMp4 = 1;
        }
        
        NSDictionary *o = @{
                            @"cid": [NSNumber numberWithInt:intcid] ,
                            @"quality": [NSNumber numberWithInt:quality],
                            @"isMP4": [NSNumber numberWithInt:intIsMp4],
                            @"url": params[@"url"]
                            };
    
        NSData *d= [NSJSONSerialization dataWithJSONObject:o options:NSJSONWritingPrettyPrinted error:nil];
        NSString *jsonString = [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
        NSString *vjson = [plugin processEvent:@"bilibili-resolveAddr" :jsonString];
        if(vjson && [vjson length] > 5){
            NSData *jsonData = [vjson dataUsingEncoding:NSUTF8StringEncoding];
            
            NSError * error = nil;
            NSMutableDictionary *videoResult = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
            
            if(error || !videoResult){
                NSLog(@"[VP_Bilibili] JSON Parse Error: %@",error);
                [NSException raise:@VP_BILI_JSON_ERROR format:@"%@", error.localizedDescription];
                return NULL;
            }
            
            NSLog(@"[VP_Bilibili] Dynamic parse success");
            
            return videoResult;
            
        }else{
            [NSException raise:@VP_BILI_DYN_PARSER_ERROR format:@"视频解析出现错误，且云端动态解析模块也无法解析，可能该版本已失效，请升级到最新版，或稍后重新启动软件再试。"];
        }
    }else{
        NSLog(@"[VP_Bilibili] Can't load dynamic parser");
        [NSException raise:@VP_BILI_DYN_PARSER_ERROR format:@"视频解析出现错误，且云端动态解析模块未安装，请升级到最新版，或重新启动软件再试。"];
    }
    
    return NULL;
}

- (void)writeHistory: (NSString *)cid :(NSString *)aid{
    NSURL* URL = [NSURL URLWithString:[NSString stringWithFormat:@"http://interface.bilibili.com/player?id=cid:%@&aid=%@",cid,aid]];
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:URL];
    request.HTTPMethod = @"GET";
    request.timeoutInterval = 5;

    long isDisabled = [ud integerForKey:@"disableWritePlayHistory"];
    if(isDisabled){
        return;
    }
    NSString *xff = [ud objectForKey:@"xff"];
    NSString *cookie = [ud objectForKey:@"cookie"];
    if([xff length] > 4){
        [request setValue:xff forHTTPHeaderField:@"X-Forwarded-For"];
        [request setValue:xff forHTTPHeaderField:@"Client-IP"];
    }
    [request setValue:cookie forHTTPHeaderField:@"Cookie"];
    [request setValue:self.userAgent forHTTPHeaderField:@"User-Agent"];
    NSURLConnection* connection = [NSURLConnection connectionWithRequest:request delegate:nil];
    [connection start];
}

- (NSString *)getFakeIP: (NSDictionary *)params{
    int fakeType = [[ud objectForKey:@"iptype"] intValue];
    
    NSString *xff = [ud objectForKey:@"xff"];
    
    NSString *title = params[@"title"];
    if(title && [title containsString:@"MIMI"]){
        fakeType = 2; // Force set XFF to Hong Kong IP
    }
    
    if(fakeType == 2){
        xff = [ud objectForKey:@"xff_HK2"];
        if(!xff){
            xff = [NSString stringWithFormat:@"59.152.193.%d",arc4random_uniform(255)];
            [ud setObject:xff forKey:@"xff_HK2"];
        }
    }
    
    return xff;
}

- (NSString *)getSign:(NSString *)path{
    NSString *input = [NSString stringWithFormat:@"%@%@",path,APISecret];
    const char *cStr = [input UTF8String];
    unsigned char digest[16];
    CC_MD5( cStr, (CC_LONG)strlen(cStr), digest ); // This is the md5 call
    
    NSMutableString *md5 = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [md5 appendFormat:@"%02x", digest[i]];
    return md5;
}

- (NSString *)getRandomHWID {
    NSString *letters = @"abcdef0123456789";
    NSMutableString *randomString = [NSMutableString stringWithCapacity:16];
    
    for (int i=0; i<16; i++) {
        [randomString appendFormat: @"%C", [letters characterAtIndex: arc4random_uniform((int)[letters length]-1)]];
    }
    
    return randomString;
}

- (int)getQuality{
    int quality = (int)[ud integerForKey:@"quality"];
    if(!quality){
        return 4;
    }else{
        return quality;
    }
}

- (NSString *)getFormat: (BOOL)isDownload{
    if(FLVFailRetry){
        return @"flv";
    }
    NSString *key = @"playMP4";
    if(isDownload){
        key = @"DLMP4";
    }
    int isMP4 = (int)[ud integerForKey:key];
    if(isMP4){
        return @"mp4";
    }else{
        return @"flv";
    }
}

@end
