//
//  DownloadWrapper.h
//  bilibili
//
//  Created by TYPCN on 2015/6/6.
//  Copyright (c) 2016 TYPCN. All rights reserved.
//

#ifndef bilibili__downloadWrapper
#define bilibili__downloadWrapper


#import <Cocoa/Cocoa.h>

class Downloader {
public:
    BOOL newTask(int cid,NSString* aid,NSString *pid,NSString *name);
    BOOL downloadComment(int cid,NSString *name);
};

#endif /* defined(__bilibili__downloadWrapper__) */
