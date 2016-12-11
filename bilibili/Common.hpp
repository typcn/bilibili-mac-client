//
//  Common.h
//  bilibili
//
//  Created by TYPCN on 2015/9/4.
//  Copyright (c) 2016 TYPCN. All rights reserved.
//

#ifndef bilibili_Common_h
#define bilibili_Common_h

#import "Browser.h"

#ifdef __cplusplus
#import "downloadWrapper.h"
extern Downloader* DL;
#endif

extern Browser* browser;
extern NSString *userAgent;

#endif
