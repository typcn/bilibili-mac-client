//
//  Popover.h
//  bilibili
//
//  Created by TYPCN on 2015/10/8.
//  Copyright © 2015 TYPCN. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DynamicView.h"

@interface Popover : NSObject

- (void)addToStatusBar;
- (void)startMonitor;
- (void)removeMonitor;

@end
