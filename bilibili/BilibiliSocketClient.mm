//
//  SocketClient.m
//  bilibili
//
//  Created by TYPCN on 2015/5/17.
//  Copyright (c) 2015 TYPCN. All rights reserved.
//

#import "BilibiliSocketClient.h"

#include "Socket.hpp"

@implementation LiveSocket{
    tcp_client c;
}

- (bool)ConnectToTheFuckingFlashSocketServer: (int)roomid{
    if(!c.conn("livecmt.bilibili.com" , 88)){
        return false;
    }
    
    NSString *initStr = [NSString stringWithFormat:@"0101000c0000%04x00000000",roomid];
    NSData *data = [self dataFromHexString:initStr];
    c.send_data([data bytes], (int)[data length]);
    while(true){
        std::string str = c.receive(1024);
        if(str.length() > 0){
            NSLog(@"Data: %s",str.c_str());
        }
    }
    return true;
}

- (NSData *)dataFromHexString:(NSString *)str {
    const char *chars = [str UTF8String];
    int i = 0, len = (int)str.length;
    
    NSMutableData *data = [NSMutableData dataWithCapacity:len / 2];
    char byteChars[3] = {'\0','\0','\0'};
    unsigned long wholeByte;
    
    while (i < len) {
        byteChars[0] = chars[i++];
        byteChars[1] = chars[i++];
        wholeByte = strtoul(byteChars, NULL, 16);
        [data appendBytes:&wholeByte length:1];
    }
    
    return data;
}

@end
