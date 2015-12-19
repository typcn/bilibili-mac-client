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

inline int MP4CharFind_Loop(uint8_t *bytes,unsigned long length,const uint8_t *magic){
    for(int i = 0;i < length;i++){
        if(i > length - 4){ // Ignore last char
            return -1;
        }
        if(bytes[i] == magic[0]   && bytes[i+1] == magic[1] &&
           bytes[i+2] == magic[2] && bytes[i+3] == magic[3]){
            return i;
        }
    }
    return -1;
}

NSDictionary *findMP4Resolution(NSData *videoData){
    // For FFMpeg only !
    static const uint8_t magic[] = { 0x65, 0x64, 0x74, 0x73 };
    uint8_t *videoBytes = (uint8_t *)[videoData bytes];
    int loc = MP4CharFind_Loop(videoBytes, [videoData length], magic);
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

inline int FLVCharFind_Loop(uint8_t *bytes,unsigned long length,const uint8_t *magic){
    for(int i = 0;i < length;i++){
        if(i > length - 5){ // Ignore last char
            return -1;
        }
        if(bytes[i] == magic[0]   && bytes[i+1] == magic[1] &&
           bytes[i+2] == magic[2] && bytes[i+3] == magic[3] && bytes[i+4] == magic[4]){
            return i;
        }
    }
    return -1;
}

inline double get_double_from_BE_binary(uint64_t *be_bin){
    uint64_t output = *be_bin;
    output = (output & 0x00000000FFFFFFFF) << 32 | (output & 0xFFFFFFFF00000000) >> 32;
    output = (output & 0x0000FFFF0000FFFF) << 16 | (output & 0xFFFF0000FFFF0000) >> 16;
    output = (output & 0x00FF00FF00FF00FF) << 8  | (output & 0xFF00FF00FF00FF00) >> 8;
    return *((double*)&output);
}

NSDictionary *findFLVResolution(NSData *videoData){
    // For any flv file
    uint8_t *videoBytes = (uint8_t *)[videoData bytes];
    static const uint8_t height[] = { 0x68, 0x65, 0x69, 0x67, 0x68};
    static const uint8_t width[] = { 0x77, 0x69, 0x64, 0x74, 0x68 };
    int heightLoc = FLVCharFind_Loop(videoBytes,[videoData length],height);
    int widthLoc  = FLVCharFind_Loop(videoBytes,[videoData length],width);
    if(heightLoc > -1 && widthLoc > -1){
        uint64_t h_BE_Binary;
        uint64_t w_BE_Binary;
        memcpy(&h_BE_Binary, videoBytes + heightLoc + 7, 8);
        memcpy(&w_BE_Binary, videoBytes + widthLoc  + 6, 8);
        double height = get_double_from_BE_binary(&h_BE_Binary);
        double width = get_double_from_BE_binary(&w_BE_Binary);
        
        if(width > 100 & height > 100 && width < 5000 && height < 3000){
            return @{
                     @"width": [NSNumber numberWithInt:(int)width],
                     @"height": [NSNumber numberWithInt:(int)height],
                     };
        }else{
            NSLog(@"[SimpleParser][FLV] Invalid data: %f %f",width,height);
            return NULL;
        }
    }else{
        NSLog(@"[SimpleParser][FLV] Size pattern not found");
        return NULL;
    }
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