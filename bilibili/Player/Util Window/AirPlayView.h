//
//  AirPlayView.h
//  bilibili
//
//  Created by TYPCN on 2015/9/16.
//  Copyright © 2016 TYPCN. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AirPlayView : NSViewController < NSTableViewDataSource >

@end


@interface AirPlayWindowController : NSWindowController

@property (nonatomic) NSString *cid;
@property (nonatomic) NSString *url;
@property (nonatomic) NSString *vtitle;

@end