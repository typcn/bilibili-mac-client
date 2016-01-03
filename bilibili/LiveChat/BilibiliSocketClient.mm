//
//  SocketClient.m
//  bilibili
//
//  Created by TYPCN on 2015/5/17.
//  Copyright (c) 2016 TYPCN. All rights reserved.
//

#import "BilibiliSocketClient.h"

#include "Socket.hpp"

int room;
tcp_client c;

@implementation LiveSocket{
    id delegate;
    BOOL disconnected;
    NSTimer *hbTimer;
}
- (void)setDelegate:(id)del{
    delegate = del;
}

- (bool)ConnectToTheFuckingFlashSocketServer: (int)roomid{
    disconnected = false;
    room = roomid;
    if(!c.conn("livecmt.bilibili.com" , 88)){
        return false;
    }
    
    hbTimer = [NSTimer scheduledTimerWithTimeInterval:30.0
                                     target:self
                                   selector:@selector(startHB)
                                   userInfo:nil
                                    repeats:YES];
    
    [NSTimer scheduledTimerWithTimeInterval:1.0
                                     target:self
                                   selector:@selector(recvMsg)
                                   userInfo:nil
                                    repeats:NO];
    return true;
}

- (void)Disconnect{
    disconnected = true;
    [hbTimer invalidate];
    hbTimer = nil;
    c.disconnect😈();
}

- (void) recvMsg{
    dispatch_queue_t q = dispatch_queue_create("com.typcn.bilisocket", NULL);
    dispatch_async(q, ^(void){
        while (!disconnected) {
            std::string str = c.receive(2048);
            if(str.length() > 4){
                dispatch_async(dispatch_get_main_queue(), ^{
                NSString *recv = [NSString stringWithUTF8String:str.c_str()];
                if([recv length] > 5){
                    NSError *err;
                    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:[recv dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONWritingPrettyPrinted error:&err];
                    if(!err){
                        if(dic){
                            [delegate onNewMessage:dic];
                        }
                    }else{
                        [delegate onNewError:recv];
                    }
                }
                

                });
            }
        }
        NSLog(@"Loop end");
    });
}

- (void) startHB{
    NSString *HBStr = [NSString stringWithFormat:@"01020004"];
    NSData *nsdata = [self dataFromHexString:HBStr];
    c.send_data([nsdata bytes], (int)[nsdata length]);
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

void handShake(){
    NSString *initStr = [NSString stringWithFormat:@"0101000c0000%04x00000000",room];
    const char *chars = [initStr UTF8String];
    int i = 0, len = (int)initStr.length;
    
    NSMutableData *data = [NSMutableData dataWithCapacity:len / 2];
    char byteChars[3] = {'\0','\0','\0'};
    unsigned long wholeByte;
    
    while (i < len) {
        byteChars[0] = chars[i++];
        byteChars[1] = chars[i++];
        wholeByte = strtoul(byteChars, NULL, 16);
        [data appendBytes:&wholeByte length:1];
    }
    c.send_data([data bytes], (int)[data length]);
}
