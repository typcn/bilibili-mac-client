//
//  LiveChat.h
//  bilibili
//
//  Created by TYPCN on 2015/5/17.
//  Copyright (c) 2016 TYPCN. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Player.h"

@interface LiveChat : NSViewController

- (id)initWithPlayer:(Player *)player;

- (void)onNewMessage:(NSDictionary *)data;
- (void)onNewError:(NSString *)str;

@end
