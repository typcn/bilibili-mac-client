//
//  BrowserExtInterface.h
//  bilibili
//
//  Created by TYPCN on 2015/10/12.
//  Copyright © 2016 TYPCN. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BrowserExtInterface : NSObject

- (NSArray *)GetScriptList;
- (NSArray *)GetHistory:(int)page;
- (BOOL)DelHistory:(NSString *)ids;

@end
