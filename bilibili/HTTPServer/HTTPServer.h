//
//  HTTPServer.h
//  bilibili
//
//  Created by TYPCN on 2015/9/7.
//  Copyright (c) 2015 TYPCN. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PlayerControlView.h"

@interface HTTPServer : NSObject
@property (strong) NSWindowController* playerWindowController;
- (void)startHTTPServer;

@end
