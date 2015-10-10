//
//  vp_bilibili.h
//  bilibili
//
//  Created by TYPCN on 2015/9/17.
//  Copyright © 2015 TYPCN. All rights reserved.
//

#ifndef vp_bilibili_h
#define vp_bilibili_h

#import <Cocoa/Cocoa.h>

enum
{
    k_biliVideoType_flv         = 1,
    k_biliVideoType_mp4         = 2,
    k_biliVideoType_live_flv    = 3,
    k_biliVideoType_live_m3u8   = 4 // not supported now
    
};

NSArray *vp_bili_get_url(int cid,NSString *aid,NSString *pid,int vType);
NSArray *vp_bili_get_live_url(int cid,int vType);


#endif /* vp_bilibili_h */
