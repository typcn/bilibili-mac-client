//
//  PluginManager.m
//  bilibili
//
//  Created by TYPCN on 2015/9/20.
//  Copyright © 2015 TYPCN. All rights reserved.
//

#import "PluginManager.h"

@implementation PluginManager{
    NSString *sprtdir;
    NSArray *availablePlugins;
    NSMutableDictionary *loadedPlugins;
    int ver;
}

+ (instancetype)sharedInstance {
    static id sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (id) init
{
    if (self = [super init])
    {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
        NSString *applicationSupportDirectory = [paths firstObject];
        NSLog(@"applicationSupportDirectory: '%@'", applicationSupportDirectory);
        sprtdir = [NSString stringWithFormat:@"%@/Plugins/",applicationSupportDirectory];
        loadedPlugins = [[NSMutableDictionary alloc] init];
        
        ver = [[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"] intValue];
    }
    return self;
}

- (void)reloadList{
    NSArray *dirFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:sprtdir error:nil];
    availablePlugins = dirFiles;
}

- (id)loadPlugin:(NSString *)name{
    NSString *path = [NSString stringWithFormat:@"%@%@",sprtdir,name];
    NSBundle *pluginBundle = [NSBundle bundleWithPath:path];
    [pluginBundle load];
    
    Class prinClass = [pluginBundle principalClass];
    if (![prinClass isSubclassOfClass:[VP_Plugin class]]) {
        return nil;
    }else{
        VP_Plugin *plgInstance = [[prinClass alloc] init];
        [plgInstance load:ver];
        return plgInstance;
    }
}

- (id)Get:(NSString *)action{
    NSArray *arr = [action componentsSeparatedByString:@"-"];
    if([arr count] < 2){
        return nil;
    }else{
        NSString *plgName = [arr objectAtIndex:0];
        id plgInstance = loadedPlugins[plgName];
        if(!plgInstance){
            plgInstance = [self loadPlugin:plgName];
            if(!plgInstance){
                NSLog(@"Invalid plugin: %@",plgName);
                return nil;
            }
            loadedPlugins[plgName] = plgInstance;
        }
        
        return plgInstance;
    }
}

- (void)install:(NSString *)URL hash:(NSString *)hash{
    // TODO
}

- (void)enable:(NSString *)name{
    // TODO
}

- (void)disable:(NSString *)name{
    // TODO
}

@end