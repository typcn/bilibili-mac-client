//
//  LiveChat.m
//  bilibili
//
//  Created by TYPCN on 2015/5/17.
//  Copyright (c) 2015 TYPCN. All rights reserved.
//

#import "LiveChat.h"
#import "BilibiliSocketClient.h"

extern NSString *vCID;

@interface LiveChat ()

@end

@implementation LiveChat

- (void)viewDidLoad {
    [super viewDidLoad];
    LiveSocket *socket = [[LiveSocket alloc] init];
    
    [socket ConnectToTheFuckingFlashSocketServer:[vCID intValue]];
}

@end
