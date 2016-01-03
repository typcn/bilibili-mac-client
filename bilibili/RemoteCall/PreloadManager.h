//
//  PreloadManager.h
//  bilibili
//
//  Created by TYPCN on 2015/12/16.
//  Copyright © 2016 TYPCN. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PreloadManager : NSObject

+ (instancetype)sharedInstance;


- (void)preloadComment:(NSString *)cid;
- (NSData *)GetComment:(NSString *)cid;
- (void)removeComment:(NSString *)cid;

@end
