//
//  Common.h
//  bilibili
//
//  Created by TYPCN on 2015/9/4.
//  Copyright (c) 2015 TYPCN. All rights reserved.
//

#ifndef bilibili_Common_h
#define bilibili_Common_h

#import "Browser.h"

#ifdef __cplusplus
#import "downloadWrapper.h"
extern Downloader* DL;
#endif

extern Browser* browser;
extern NSString *vUrl;
extern NSString *vCID;
extern NSString *vTitle;
extern NSString *userAgent;
extern NSWindow *currWindow;

extern BOOL parsing;

extern NSString *cmFile;
extern NSString *subFile;

#endif
