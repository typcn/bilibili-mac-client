//
//  HTTPServer.h
//  bilibili
//
//  Created by TYPCN on 2015/9/7.
//  Copyright (c) 2015 TYPCN. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PlayerControlView.h"
#import "AirPlayView.h"
#import "PluginManager.h"
#import "BrowserExtInterface.h"

@interface HTTPServer : NSObject
@property (strong) NSWindowController* playerWindowController;
@property (strong) NSWindowController* airplayWindowController;
@property (strong) NSWindowController* settingsWindowController;
- (void)startHTTPServer;

@end
