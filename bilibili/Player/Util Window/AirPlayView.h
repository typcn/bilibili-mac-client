//
//  AirPlayView.h
//  bilibili
//
//  Created by TYPCN on 2015/9/16.
//  Copyright © 2016 TYPCN. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AirPlayView : NSViewController < NSTableViewDataSource >

- (id)initWithCID:(NSString *)CID title:(NSString *)Title andURL:(NSString *)URL;

@end
