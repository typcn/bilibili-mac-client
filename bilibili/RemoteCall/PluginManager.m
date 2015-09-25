//
//  PluginManager.m
//  bilibili
//
//  Created by TYPCN on 2015/9/20.
//  Copyright © 2015 TYPCN. All rights reserved.
//

#import "PluginManager.h"
#import "NSBundle+OBCodeSigningInfo.h"
#import <sys/sysctl.h>

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
    BOOL isDebugger = [self isDebugger];
    if(isDebugger){
        static dispatch_once_t once;
        dispatch_once(&once, ^{
            NSAlert *alert = [[NSAlert alloc] init];
            [alert setMessageText:@"注意：您正在调试器中运行，将允许加载没有数字签名的插件。"];
            [alert runModal];
        });

    }
    
    NSArray *dirFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:sprtdir error:nil];
    availablePlugins = dirFiles;
    
    for(id name in availablePlugins){
        NSString *path = [NSString stringWithFormat:@"%@%@",sprtdir,name];
        NSBundle *pluginBundle = [NSBundle bundleWithPath:path];
        if(!pluginBundle){
            continue;
        }
        if(!isDebugger){
            OBCodeSignState signState = [pluginBundle ob_codeSignState];
            if(signState != OBCodeSignStateSignatureValid){
                NSLog(@"Plugin doesn't have a valid code signature: %@",name);
                continue;
            }else{
                NSLog(@"Plugin %@ has valid codesign",name);
            }
        }
        NSDictionary *dir = [pluginBundle infoDictionary];
        if(!dir){
            NSLog(@"Invalid plugin: %@",name);
            continue;
        }
        NSString *dm = [dir objectForKey:@"Inject Javascript on domain"];
        NSString *js = [dir objectForKey:@"Inject Javascript file prefix"];
        
        if(!dm || !js){
            NSLog(@"Invalid VP-Plugin: %@",name);
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
                NSLog(@"Native plugin load failed: %@",plgName);
                return nil;
            }
            loadedPlugins[plgName] = plgInstance;
        }
        
        return plgInstance;
    }
}

- (void)install:(NSString *)URL{
    // TODO
}

- (void)enable:(NSString *)name{
    // TODO
}

- (void)disable:(NSString *)name{
    // TODO
}

- (BOOL)isDebugger{
    // Only allow to load invalid plugin if in debugger
    static BOOL debuggerIsAttached = NO;
    
    static dispatch_once_t debuggerPredicate;
    dispatch_once(&debuggerPredicate, ^{
        
        struct kinfo_proc info;
        size_t info_size = sizeof(info);
        int name[4];
        
        name[0] = CTL_KERN;
        name[1] = KERN_PROC;
        name[2] = KERN_PROC_PID;
        name[3] = getpid();
        if (sysctl(name, 4, &info, &info_size, NULL, 0) == -1) {
            debuggerIsAttached = false;
        }
        
        if (!debuggerIsAttached && (info.kp_proc.p_flag & P_TRACED) != 0)
            debuggerIsAttached = true;
    });
    return debuggerIsAttached;
}

@end