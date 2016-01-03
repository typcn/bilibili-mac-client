//
//  Plugin common API
//  VPPlugin
//
//  Created by TYPCN on 2015/9/21.
//  Copyright © 2016 TYPCN. All rights reserved.
//

#import <Cocoa/Cocoa.h>

//! Project version number for VPPlugin.
FOUNDATION_EXPORT double VPPluginVersionNumber;

//! Project version string for VPPlugin.
FOUNDATION_EXPORT const unsigned char VPPluginVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <VPPlugin/PublicHeader.h>


#ifndef vp_plg_api
#define vp_plg_api 0.1
#endif

@interface VP_Plugin : NSObject

// trigger on load , version is program build number ( eg: 206 )
- (bool)load:(int)version;

// trigger on unload , do cleanup
- (bool)unload;

// trigger when event from javascript , return true or false
- (bool)canHandleEvent:(NSString *)eventName;

// trigger when event from javascript , return video url to play , reutrn NULL won't do anything
- (NSString *)processEvent:(NSString *)eventName :(NSString *)eventData;

// trigger when user click "settings"
- (void)openSettings;

@end
