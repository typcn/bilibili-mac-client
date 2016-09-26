//
//  SocketProvider.h
//  bilibili
//
//  Created by TYPCN on 2016/8/2.
//  Copyright © 2016 TYPCN. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SocketProvider : NSObject

- (void)loadWithPlayer: (id)player;
- (void)setDelegate:(id)del;
- (void)disconnect;
- (void)reconnect;

@end
