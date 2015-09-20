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
    NSMutableDictionary *pluginScripts;
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
        sprtdir = [NSString stringWithFormat:@"%@/com.typcn.bilibili/Plugins/",applicationSupportDirectory];
        loadedPlugins = [[NSMutableDictionary alloc] init];
        pluginScripts = [[NSMutableDictionary alloc] init];
        ver = [[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"] intValue];
        
        [self reloadList];
    }
    return self;
}

- (NSString *)javascriptForDomain:(NSString *)domain{
    NSArray *ary = [domain componentsSeparatedByString:@"."];
    int last = (int)[ary count];
    NSString *key = [NSString stringWithFormat:@"%@.%@",[ary objectAtIndex:last-2],[ary objectAtIndex:last-1]];
    return pluginScripts[key];
}

- (void)reloadList{
    
    NSArray *dirFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:sprtdir error:nil];
    availablePlugins = dirFiles;
    
    for(id name in availablePlugins){
        NSString *path = [NSString stringWithFormat:@"%@%@",sprtdir,name];
        NSBundle *pluginBundle = [NSBundle bundleWithPath:path];
        if(!pluginBundle){
            continue;
        }
        NSDictionary *dir = [pluginBundle infoDictionary];
        if(!dir){
            NSLog(@"Invalid plugin:%@",name);
            continue;
        }
        NSString *dm = [dir objectForKey:@"Inject Javascript on domain"];
        NSString *js = [dir objectForKey:@"Inject Javascript file prefix"];
        
        if(!dm || !js){
            NSLog(@"Invalid VP-Plugin:%@",name);
            continue;
        }
        
        NSString *fpath = [pluginBundle pathForResource:js ofType:@"js"];
        NSError *err;
        NSString *str = [NSString stringWithContentsOfFile:fpath
                                                  encoding:NSUTF8StringEncoding
                                                     error:&err];
        if(err || !str){
            NSLog(@"Cannot find javascript file for plugin %@",name);
            continue;
        }
        
        pluginScripts[dm] = str;
        NSLog(@"Loading plugin javascript %@ forDomain %@",name,dm);
    }
}

- (id)loadPlugin:(NSString *)name{
    NSString *path = [NSString stringWithFormat:@"%@%@.bundle",sprtdir,name];
    NSLog(@"Load native plugin at path %@",path);
    NSBundle *pluginBundle = [NSBundle bundleWithPath:path];
    [pluginBundle load];
    
    Class prinClass = [pluginBundle principalClass];
    if (![prinClass isSubclassOfClass:[VP_Plugin class]]) {
        return nil;
    }else{
        NSLog(@"Loading native plugin %@",name);
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