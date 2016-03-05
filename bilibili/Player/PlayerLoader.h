//
//  PlayerLoader.h
//  bilibili
//
//  Created by TYPCN on 2016/3/4.
//  Copyright © 2016 TYPCN. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "VideoProvider.h"

@class Player;

@interface PlayerLoader : NSWindowController

+ (instancetype)sharedInstance;

- (void)loadVideoFrom:(VideoProvider *)provider withPageUrl:(NSString *)url;
- (void)loadVideoFrom:(VideoProvider *)provider withData:(NSDictionary *)params;
- (void)loadVideoWithLocalFiles:(NSArray *)files;
- (void)loadVideo:(VideoAddress *)video;
- (void)loadVideo:(VideoAddress *)video withAttrs:(NSDictionary *)attrs;
- (NSString *)lastPlayerId;

@end