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

- (NSString *)nextPlayURL{
    if(!currentURLIndex){
        currentURLIndex = 1;
        return self.defaultPlayURL;
    }else{
        int backupIdx = currentURLIndex - 1;
        int backupCount = (int)[self.backupPlayURLs count];
        if(backupCount > backupIdx){
            return [self.backupPlayURLs objectAtIndex:backupIdx];
        }else{
            return NULL;
        }
    }
}

@end
