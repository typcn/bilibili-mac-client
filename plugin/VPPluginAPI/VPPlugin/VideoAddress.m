//
//  VideoAddress.m
//  bilibili
//
//  Created by TYPCN on 2016/3/3.
//  Copyright © 2016 TYPCN. All rights reserved.
//

#import "VideoAddress.h"

@implementation VideoAddress{
    int currentURLIndex;
}

- (id)init{
    self = [super init];
    if(self){
        self.defaultPlayURL = [[NSMutableArray alloc] init];
        self.backupPlayURLs = [[NSMutableArray alloc] init];
    }
    return self;
}

- (NSString *)nextPlayURL{
    if(!currentURLIndex){
        currentURLIndex = 1;
        return [self processMultiFragment:self.defaultPlayURL];
    }else{
        int backupIdx = currentURLIndex - 1;
        int backupCount = (int)[self.backupPlayURLs count];
        if(backupCount > backupIdx){
            id urls = [self.backupPlayURLs objectAtIndex:backupIdx];
            self.firstFragmentURL = [urls objectAtIndex:0];
            return [self processMultiFragment:urls];
        }else{
            return NULL;
        }
    }
}

- (void)addDefaultPlayURL:(NSString *)URL{
    [self.defaultPlayURL addObject:URL];
}

- (void)addBackupURL:(NSArray *)URL{
    [self.backupPlayURLs addObject:URL];
}

- (NSString *)processMultiFragment:(NSArray *)URLs{
    if([URLs count] == 1){
        return [URLs objectAtIndex:0];
    }
    NSString *edlUrl;
    for (NSString *url in URLs) {
        unsigned long realLength = strlen([url UTF8String]);
        if(![edlUrl length]){
            edlUrl = [NSString stringWithFormat:@"%@%@%lu%@%@%@", @"edl://", @"%",realLength, @"%" , url ,@";"];
        }else{
            edlUrl = [NSString stringWithFormat:@"%@%@%lu%@%@%@",  edlUrl  , @"%",realLength, @"%" , url ,@";"];
        }
    }
    return edlUrl;
}

@end
