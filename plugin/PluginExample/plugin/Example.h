//
//  Example.h
//  PluginExample
//
//  Created by TYPCN on 2015/9/20.
//  Copyright © 2015 TYPCN. All rights reserved.
//

#ifndef Example_h
#define Example_h

#import <Cocoa/Cocoa.h>
#import <VPPlugin/VPPlugin.h>

@interface Example : VP_Plugin

// trigger on load , version is program build number ( eg: 206 )
- (bool)load:(int)version;

// trigger on unload , do cleanup
- (bool)unload;

// trigger when event from javascript , return true or false
- (bool)canHandleEvent:(NSString *)eventName;

// trigger when event from javascript , return video url to play , reutrn NULL won't do anything
- (NSString *)processEvent:(NSString *)eventName :(NSString *)eventData;

@end


#endif /* Example_h */
