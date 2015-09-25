//
//  Example.m
//  PluginExample
//
//  Created by TYPCN on 2015/9/20.
//  Copyright © 2015 TYPCN. All rights reserved.
//

#import "Example.h"

@interface Example ()

@property (strong) NSWindowController* examplePanel;

@end

@implementation Example

@synthesize examplePanel;

- (bool)load:(int)version{
    
    NSLog(@"oh! This plugin is loaded");
    
    return true;
}


- (bool)unload{
    
    NSLog(@"Unloading now");
    
    return true;
}


- (bool)canHandleEvent:(NSString *)eventName{
    // Eventname format is pluginName-str
    if([eventName isEqualToString:@"Example-ShowExamplePanel"]){
        return true;
    }
    return false;
}

- (NSString *)processEvent:(NSString *)eventName :(NSString *)eventData{
    
    if([eventName isEqualToString:@"Example-ShowExamplePanel"]){
        dispatch_async(dispatch_get_main_queue(), ^(void){
            
            NSString *path = [[NSBundle bundleForClass:[self class]]
                              pathForResource:@"ExamplePanel" ofType:@"nib"];
            examplePanel =[[NSWindowController alloc] initWithWindowNibPath:path owner:self];
            [examplePanel showWindow:self];
        });
    }
    
    return NULL; // return video url to play
}

- (void)openSettings{
    return;
}
@end