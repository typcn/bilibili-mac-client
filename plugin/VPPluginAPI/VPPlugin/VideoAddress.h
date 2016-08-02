//
//  VideoAddress.h
//  bilibili
//
//  Created by TYPCN on 2016/3/3.
//  Copyright © 2016 TYPCN. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VideoAddress : NSObject

@property NSString *firstFragmentURL; // First fragment of default play url
@property NSMutableArray *defaultPlayURL; // All fragments [Frag1,Frag2,...]
@property NSMutableArray *backupPlayURLs; // Backup URLs [ [B1F1,B1F2,...], [B2F1,B2F2,...], ... ]

@property NSString *userAgent;
@property NSString *cookie;

- (NSString *)nextPlayURL;

- (void)addDefaultPlayURL:(NSString *)URL;

- (void)addBackupURL:(NSArray *)URL; // Multi fragments
- (NSString *)processMultiFragment:(NSArray *)URLs; // Multi fragments

@end
