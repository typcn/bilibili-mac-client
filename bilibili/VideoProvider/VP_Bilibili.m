//
//  VP_Bilibili.m
//  bilibili
//
//  Created by TYPCN on 2016/3/3.
//  Copyright © 2016 TYPCN. All rights reserved.
//

#import "VP_Bilibili.h"
#import "PluginManager.h"

#import <CommonCrypto/CommonDigest.h>

extern NSString *APIKey;
extern NSString *APISecret;

@implementation VP_Bilibili{
    NSUserDefaults *ud;
    BOOL FLVFailRetry;
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
        
    }
    return self;
}

- (NSDictionary *)generateParamsFromURL: (NSString *)URL{
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\/video\\/av(\\d+)(\\/index.html|\\/index_(\\d+).html)?" options:NSRegularExpressionCaseInsensitive error:nil];
    
    NSTextCheckingResult *match = [regex firstMatchInString:URL options:0 range:NSMakeRange(0, [URL length])];
    
    NSRange aidRange = [match rangeAtIndex:1];
    
    if(aidRange.length > 0){
        params[@"aid"] = [URL substringWithRange:aidRange];
        NSRange pidRange = [match rangeAtIndex:3];
        if(pidRange.length > 0 ){
            params[@"pid"] = [URL substringWithRange:pidRange];
        }else{
            params[@"pid"] = @"0";
        }
    }else{
        params[@"aid"] = @"0";
        params[@"pid"] = @"0";
    }
    
    params[@"url"] = URL;
    
    return params;
}

- (NSString *)getPlaybackRequestURL: (NSDictionary *)params{
    int quality = [self getQuality];
    NSString *type = [self getFormat:[params[@"download"] boolValue]];
    
    NSLog(@"[VP_Bilibili] AV: %@, CID: %@, PID: %@", params[@"aid"], params[@"cid"], params[@"pid"]);
    
    NSString *req_path = [NSString stringWithFormat:@"platform=android&_device=android&_hwid=%@&_aid=%@&_tid=0&_p=%@&_down=0&cid=%@&quality=%d&otype=json&appkey=%@&type=%@",
                          self.hwid, // Hardware ID ( Generate on first start )
                          params[@"aid"], // Page ID ( AV )
                          params[@"pid"], // Page Number
                          params[@"cid"], // Video ID
                          quality,APIKey,type];
    
    NSString *req_sign = [self getSign:req_path];
    
    NSString *req_url = [NSString stringWithFormat:@"http://interface.bilibili.com/playurl?%@&sign=%@",req_path,req_sign];
    
    NSLog(@"[VP_Bilibili] API Request URL: %@", req_url);
    
    return req_url;
}

- (NSString *)getLiveRequestURL: (NSDictionary *)params{
    NSLog(@"[VP_Bilibili] LiveRoom: %@", params[@"cid"]);
    
    NSString *uuid = [[NSUUID UUID] UUIDString];
    NSString *hwid = [self getRandomHWID];
    
    NSString *req_path = [NSString stringWithFormat:@"platform=android&_appver=406001&_buvid=%@infoc&_device=android&_hwid=%@&_aid=0&_tid=0&_p=%@&_down=0&cid=%@&quality=1&otype=json&appkey=%@&type=mp4",
                          uuid, // BUVID ( Unkown , Random here )
                          hwid, // Hardware ID ( Random here , avoid BUVID
                          params[@"cid"], // Live room ID
                          params[@"cid"], // Live room ID
                          APIKey];

    NSString *req_sign = [self getSign:req_path];
    
    NSString *req_url = [NSString stringWithFormat:@"http://live.bilibili.com/api/playurl?%@&sign=%@",req_path,req_sign];
    
    NSLog(@"[VP_Bilibili] API Request URL: %@", req_url);
    
    return req_url;
}


- (VideoAddress *) getVideoAddress: (NSDictionary *)params{
    if(!params[@"cid"]){
        [NSException raise:@"Params CID Error" format:@"CID Cannot be empty"];
        return NULL;
    }
                      
getUrl: NSLog(@"[VP_Bilibili] Getting video url");

    NSString *pbUrl;
    
    if(params[@"live"]){
        pbUrl = [self getPlaybackRequestURL:params];
    }else{
        pbUrl = [self getLiveRequestURL:params];
    }
    
    NSURL* URL = [NSURL URLWithString:pbUrl];
    
    NSString *fakeIP = [self getFakeIP:params];
    
    NSDictionary *videoResult = [self sendAPIRequest:URL :fakeIP];
    
parseJSON: NSLog(@"[VP_Bilibili] Parsing result");
    
    NSArray *dUrls = [videoResult objectForKey:@"durl"];
    if([dUrls count] == 0){
        if(FLVFailRetry){
            FLVFailRetry = NO;
            [NSException raise:@"VideoResolveError" format:@"Bilibili API Error"];
            return NULL;
        }else{
            FLVFailRetry = YES;
            NSLog(@"[VP_Bilibili] Retring resolve with FLV format");
            goto getUrl;
        }
    }
    
    FLVFailRetry = NO;
    
    VideoAddress *video = [[VideoAddress alloc] init];
    [video setUserAgent:@"Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/34.0.1847.116 Safari/537.36"];
    
    BOOL URLisString = [[[dUrls valueForKey:@"url"] className] isEqualToString:@"__NSCFString"];
    if(URLisString){ // URL is String ( Single Fragment )
        NSString *url = [dUrls valueForKey:@"url"];
        [video setDefaultPlayURL:url];
        [video setFirstFragmentURL:url];
    }else{ // URL is Array
        for (NSDictionary *match in dUrls) {
            if([dUrls count] == 1){ // Single Fragment
                NSString *url = [match valueForKey:@"url"];
                [video setDefaultPlayURL:url];
                [video setFirstFragmentURL:url];
                
                NSArray *burl = [match valueForKey:@"backup_url"];
                if([burl count] > 0){
                    [video setBackupPlayURLs:burl];
                }
            }else{ // Multi Fragment
                NSString *edlUrl;
                NSString *tmp = [match valueForKey:@"url"];
                if(![[video firstFragmentURL] length]){ // FirstFragment is empty
                    [video setFirstFragmentURL:tmp];
                    edlUrl = [NSString stringWithFormat:@"%@%@%lu%@%@%@", @"edl://", @"%",(unsigned long)[tmp length], @"%" , tmp ,@";"];
                }else{
                    edlUrl = [NSString stringWithFormat:@"%@%@%lu%@%@%@",  edlUrl  , @"%",(unsigned long)[tmp length], @"%" , tmp ,@";"];
                }
                [video setDefaultPlayURL:edlUrl];
                
            }
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
    
    [request setValue:[ud objectForKey:@"cookie"] forHTTPHeaderField:@"Cookie"];
    [request setValue:@"Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/34.0.1847.116 Safari/537.36" forHTTPHeaderField:@"User-Agent"];
    [request setValue:@"trailers" forHTTPHeaderField:@"TE"];
    
    NSURLResponse * response = nil;
    NSError * error = nil;
    NSData * respData = [NSURLConnection sendSynchronousRequest:request
                                              returningResponse:&response
                                                          error:&error];
    if(error || !respData){
        NSLog(@"[VP_Bilibili] API Request Error: %@",error);
        [NSException raise:@"APIError" format:@"%@", error.localizedDescription];
        return NULL;
    }
    
    NSMutableDictionary *videoResult = [NSJSONSerialization JSONObjectWithData:respData options:0 error:&error];
    
    if(error){
        NSLog(@"[VP_Bilibili] JSON Parse Error: %@",error);
        [NSException raise:@"APIJSONError" format:@"%@", error.localizedDescription];
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
        NSDictionary *o = @{
                            @"cid": [NSNumber numberWithInt:intcid] ,
                            @"quality": [NSNumber numberWithInt:[self getQuality]],
                            @"isMP4": [NSNumber numberWithInt:(int)[ud integerForKey:@"quality"]],
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
                [NSException raise:@"APIJSONError" format:@"%@", error.localizedDescription];
                return NULL;
            }
            
            NSLog(@"[VP_Bilibili] Dynamic parse success");
            
            return videoResult;
            
        }else{
            [NSException raise:@"DynamicParserError" format:@"视频解析出现错误，且云端动态解析模块未安装，请升级到最新版，或重新启动软件再试。"];
        }
    }else{
        NSLog(@"[VP_Bilibili] Can't load dynamic parser");
        [NSException raise:@"DynamicParserError" format:@"视频解析出现错误，且云端动态解析模块未安装，请升级到最新版，或重新启动软件再试。"];
    }
    
    return NULL;
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
        [randomString appendFormat: @"%C", [letters characterAtIndex: arc4random_uniform((int)[letters length])]];
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
