//
//  VP_Bilibili.h
//  bilibili
//
//  Created by TYPCN on 2016/3/3.
//  Copyright © 2016 TYPCN. All rights reserved.
//

#import <VPPlugin/VideoProvider.h>

#ifndef vp_bilibili_h
#define vp_bilibili_h

#define VP_BILI_API_ERROR "Bilibili API Error"
#define VP_BILI_JSON_ERROR "Bilibili API JSON Error"
#define VP_BILI_DYN_PARSER_ERROR "Bilibili Dynamic Parser Error"

#endif

@interface VP_Bilibili : VideoProvider

@property NSString *hwid;
@property NSString *userAgent;

@end
