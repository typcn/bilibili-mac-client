//
//  BilibiliSocketClient.h
//  bilibili
//
//  Created by TYPCN on 2015/5/17.
//  Copyright (c) 2015 TYPCN. All rights reserved.
//

#ifndef bilibili_BilibiliSocketClient_h
#define bilibili_BilibiliSocketClient_h

#import <Foundation/Foundation.h>
#import "LiveChat.h"

@interface LiveSocket : NSObject

- (bool)ConnectToTheFuckingFlashSocketServer: (int)roomid;
- (void)setDelegate:(id)del;

@end

#endif
