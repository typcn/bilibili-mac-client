//
//  BilibiliSocketProvider.h
//  bilibili
//
//  Created by TYPCN on 2015/5/17.
//  Copyright (c) 2016 TYPCN. All rights reserved.
//

#ifndef bilibili_BilibiliSocketClient_h
#define bilibili_BilibiliSocketClient_h

#import <Foundation/Foundation.h>
#import "LiveChat.h"

@interface BilibiliSocketProvider : NSObject

- (void)loadWithPlayer: (Player *)player;
- (void)setDelegate:(id)del;
- (void)disconnect;

@end

#endif
