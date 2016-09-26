//
//  BilibiliSocketProvider.m
//  bilibili
//
//  Created by TYPCN on 2015/5/17.
//  Copyright (c) 2016 TYPCN. All rights reserved.
//

#import "BilibiliSocketProvider.h"
#import "Player.h"

#include <sys/socket.h>
#include <netdb.h>
#include <sys/time.h>

@implementation BilibiliSocketProvider{
    __weak id delegate;
    BOOL disconnected;
    NSTimer *hbTimer;
    NSString *host;
    NSMutableData *mBuf;
    NSLock *lock;
    int room;
    int sockfd;
}
- (void)setDelegate:(id)del{
    delegate = del;
}

- (void)loadWithPlayer: (id)player{
    disconnected = false;
    room = [[player getAttr:@"cid"] intValue];
    mBuf = [[NSMutableData alloc] init];
    lock = [[NSLock alloc] init];
    
    struct timeval now;
    gettimeofday(&now, NULL);
    uint64_t current_ms = (now.tv_sec * 1000LL) + now.tv_usec / 1000;
    
    NSURLSessionConfiguration* sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession* session = [NSURLSession sessionWithConfiguration:sessionConfig delegate:nil delegateQueue:nil];
    
    NSURL* URL = [NSURL URLWithString: [NSString stringWithFormat:@"http://live.bilibili.com/api/player?id=cid:%d&ts=%llx",room, current_ms]];
    
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:URL];
    request.HTTPMethod = @"GET";
    [request setValue:@"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_5) AppleWebKit/601.6.17 (KHTML, like Gecko) Version/9.1.1 Safari/601.6.17" forHTTPHeaderField:@"User-Agent"];
    
    /* Start a new Task */
    NSURLSessionDataTask* task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error == nil && [[response className] isEqualToString:@"NSHTTPURLResponse"]) {
            int code = (int)((NSHTTPURLResponse*)response).statusCode;
            if(code == 200){
                NSString *resp = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"<server>(.*?)<\\/server>" options:NSRegularExpressionCaseInsensitive error:nil];
                NSTextCheckingResult *match = [regex firstMatchInString:resp options:0 range:NSMakeRange(0, [resp length])];
                NSRange range = [match rangeAtIndex:1];
                if(range.length > 0){
                    NSString *server = [resp substringWithRange:range];
                    NSLog(@"[LiveComment] Found server: %@",server);
                    host = server;
                    [self connect];
                }
            }else{
                NSLog(@"[LiveComment] Failed with status Code %d",code);
                [delegate onNewError:@"无法获取服务器地址"];
            }
        }
        else {
            NSLog(@"[LiveComment] Failed to request server url: %@", [error localizedDescription]);
            [delegate onNewError:@"无法连接到 API"];
        }
    }];
    
    [task resume];
}

- (void)connect {
    sockfd = socket(AF_INET , SOCK_STREAM , 0);
    struct sockaddr_in server;
    struct hostent *he;
    struct in_addr **addr_list;
    if ((he = gethostbyname([host UTF8String])) == NULL)
    {
        NSLog(@"[LiveComment] Failed to resolve hostname");
        [delegate onNewError:@"无法解析域名"];
        return;
    }
    addr_list = (struct in_addr **) he->h_addr_list;
    server.sin_addr = *addr_list[0];
    server.sin_family = AF_INET;
    server.sin_port = htons(788);
    
    if (connect(sockfd, (struct sockaddr *)&server , sizeof(server)) < 0)
    {
        NSLog(@"[LiveComment] Cannot connect to server: %d",errno);
        [delegate onNewError:@"连接弹幕服务器失败"];
        return;
    }
    
    int on = 1;
    setsockopt(sockfd, SOL_SOCKET, SO_KEEPALIVE, &on, sizeof(on));
    
    struct timeval tv;
    tv.tv_sec = 5;
    tv.tv_usec = 0;
    setsockopt(sockfd, SOL_SOCKET, SO_RCVTIMEO, (char *)&tv,sizeof(struct timeval));
    
    NSString *json = [NSString stringWithFormat:@"{\"roomid\":%d,\"uid\":%ld}",room, 100000000000000 + (rand() / RAND_MAX) * 200000000000000];

    NSString *initStr = [NSString stringWithFormat:@"%08lx001000010000000700000001",[json length] + 16];
    NSMutableData *data = [[self dataFromHexString:initStr] mutableCopy];
    [data appendData:[json dataUsingEncoding:NSUTF8StringEncoding]];
    
    send(sockfd, [data bytes], [data length], 0);
    
    hbTimer = [NSTimer scheduledTimerWithTimeInterval:20.0
                                               target:self
                                             selector:@selector(startHB)
                                             userInfo:nil
                                              repeats:YES];
    
    [delegate changeReconnectButtonStatus:false];
    
    [self doRecv];
}

- (void)reconnect {
    [hbTimer invalidate];
    hbTimer = NULL;
    shutdown(sockfd, SHUT_RDWR);
    close(sockfd);
    [self connect];
}

- (void)doRecv {
    dispatch_async(dispatch_get_global_queue(0, 0), ^(void){
        while (!disconnected) {
            uint8_t buf[1024];
            [lock lock];
            ssize_t recvlen = recv(sockfd, buf, 1024, 0);
            [lock unlock];
            if(recvlen == 0){
                [self reconnect];
                return;
            }else if(recvlen < 0){
                if(errno == EAGAIN || errno == EWOULDBLOCK){
                    continue;
                }
                [self reconnect];
                return;
            }
    
            [mBuf appendBytes:buf length:recvlen];
            [self checkData];
        }
    });
}

- (void)checkData {
    while (1) {
        const uint8_t *data = (const uint8_t *)[mBuf bytes];
        uint32_t contentLen = CFSwapInt32BigToHost(*(uint32_t *)data);
        if([mBuf length] >= contentLen && contentLen > 0){
            if(contentLen > 16){
                [self parseMessage:data + 16 size:contentLen - 16];
            }
            mBuf = [[mBuf subdataWithRange:NSMakeRange(contentLen, [mBuf length] - contentLen)] mutableCopy];
        }else{
            return;
        }
    }
}

- (void)parseMessage: (const uint8_t *)data size: (uint32_t)len{
    NSData *d = [NSData dataWithBytes:data length:len];
    NSError *err;
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:d options:0 error:&err];
    if(!err){
        if(dic){
            if([[dic objectForKey:@"cmd"] isEqualToString:@"DANMU_MSG"]){ // danmaku
                NSArray *info = [dic objectForKey:@"info"];
                NSString *cmContent = [info objectAtIndex:1];
                NSString *userName = [[info objectAtIndex:2] objectAtIndex:1];
                int ftype = [[[info objectAtIndex:0] objectAtIndex:1] intValue];
                int fsize = [[[info objectAtIndex:0] objectAtIndex:2] intValue];
                unsigned int intColor = [[[info objectAtIndex:0] objectAtIndex:3] intValue];
                NSColor  *color  = [NSColor colorWithRed:((float)((intColor & 0xFF0000) >> 16))/255.0 \
                                                   green:((float)((intColor & 0x00FF00) >>  8))/255.0 \
                                                    blue:((float)((intColor & 0x0000FF) >>  0))/255.0 \
                                                   alpha:1.0];
                
                [delegate onNewMessage:cmContent :userName :ftype :fsize :color];
            }else if([[dic objectForKey:@"cmd"] isEqualToString:@"SEND_GIFT"]){ // gifts
                NSArray *info = [dic objectForKey:@"data"];
                NSString *giftName = [info valueForKey:@"giftName"];
                long giftNum = [[info valueForKey:@"num"] intValue];
                NSString *userName = [info valueForKey:@"uname"];
                // long userId = [[info valueForKey:@"uid"] intValue];
                
                [delegate onNewGift :userName :giftName :giftNum];
            }else if([[dic objectForKey:@"cmd"] isEqualToString:@"WELCOME"]) { // welcome
                NSArray *info = [dic objectForKey:@"data"];
                NSString *userName = [info valueForKey:@"uname"];
                // long userId = [[info valueForKey:@"uid"] intValue];
                bool isAdmin = [[info valueForKey:@"isadmin"] boolValue];
                bool isVip = [[info valueForKey:@"vip"] boolValue];
                
                [delegate onNewWelcome:userName :isAdmin :isVip];
            }else{
                // 未定义值
                // [delegate AppendToTextView:[NSString stringWithFormat:@"SYSTEM: %@", dic]];
                printf("@: %s\n", [[NSString stringWithFormat:@"%@", dic] UTF8String]);
            }
        }
    }else{
        [delegate onNewError:[err localizedDescription]];
    }
}

- (void)disconnect{
    disconnected = true;
    [hbTimer invalidate];
    hbTimer = NULL;
    shutdown(sockfd, SHUT_RDWR);
    close(sockfd);
}

- (void) startHB{
    NSString *HBStr = [NSString stringWithFormat:@"00000010001000010000000200000001"];
    NSData *nsdata = [self dataFromHexString:HBStr];
    [lock lock];
    send(sockfd, [nsdata bytes], (int)[nsdata length], 0);
    [lock unlock];
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
