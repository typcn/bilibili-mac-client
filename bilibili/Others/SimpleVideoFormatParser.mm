//
//  SimpleVideoFormatParser.m
//  bilibili
//
//  Created by TYPCN on 2015/12/15.
//  Copyright © 2015 TYPCN. All rights reserved.
//

#import "SimpleVideoFormatParser.h"

NSData *SendRangeHTTPRequest(NSString *URL,int length){

    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:URL]];
    request.HTTPMethod = @"GET";
    request.timeoutInterval = 5;
    [request setValue:@"Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/34.0.1847.116 Safari/537.36" forHTTPHeaderField:@"User-Agent"];
    [request setValue:[NSString stringWithFormat:@"bytes=0-%d",length] forHTTPHeaderField:@"Range"];

    NSURLResponse * response = nil;
    NSError * error = nil;
    NSData * videoData = [NSURLConnection sendSynchronousRequest:request
                                                          returningResponse:&response
                                                                      error:&error];
    if(error || !videoData){
        NSLog(@"Video Request Error:%@",error);
        return NULL;
    }else{
        return videoData;
    }
}

int magicFind_Loop(uint8_t *bytes,unsigned long length,const uint8_t *magic){
    int qQuickFindLength = ((int)(length/4)) + 1;
    for(int i = 0;i < qQuickFindLength;i++){
        int ix = i*4;
        if(bytes[ix] == magic[0]   && bytes[ix+1] == magic[1] &&
           bytes[ix+2] == magic[2] && bytes[ix+3] == magic[3]){
            return ix;
        }
    }
    return -1;
}

NSDictionary *findMP4Resolution(NSData *videoData){
    // For FFMpeg only !
    static const uint8_t magic[] = { 0x65, 0x64, 0x74, 0x73 };
    uint8_t *videoBytes = (uint8_t *)[videoData bytes];
    int loc = magicFind_Loop(videoBytes, [videoData length], magic);
    if (loc != -1) {
        uint8_t hBytes[2];
        uint8_t wBytes[2];
        // 虽然二进制文件里面是 4 个字节，这里只读两个，因为是 int16，真坑爹
        memcpy(hBytes, videoBytes + loc - 8 , 2);
        memcpy(wBytes, videoBytes + loc - 12, 2);
        // 还是尼玛大头的
        uint32_t heightInt = (hBytes[0] << 8) | hBytes[1];
        uint32_t widthInt =  (wBytes[0] << 8) | wBytes[1];
        if(widthInt > 100 & heightInt > 100 && widthInt < 5000 && heightInt < 3000){
            return @{
                     @"width": [NSNumber numberWithUnsignedInt:widthInt],
                     @"height": [NSNumber numberWithUnsignedInt:heightInt],
                     };
        }else{
            NSLog(@"[SimpleParser][MP4] Invalid data: %s %s",wBytes,hBytes);
            return NULL;
        }
    }else{
        NSLog(@"[SimpleParser][MP4] Magic pattern not found");
        // Not Found
        return NULL;
    }
}

NSDictionary *findFLVResolution(NSData *videoData){
    // TODO
}

NSDictionary *readVideoInfoFromURL(NSString *URL) {
    if([URL containsString:@".mp4"]){
        NSData *d = SendRangeHTTPRequest(URL,1000);
        return findMP4Resolution(d);
    }else if([URL containsString:@".flv"]){
        NSData *d = SendRangeHTTPRequest(URL,1000);
        return findFLVResolution(d);
    }else{
        NSLog(@"[SimpleParser] Format not supported");
        // Not supported
        return NULL;
    }
}