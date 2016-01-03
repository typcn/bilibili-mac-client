//
//  PluginManager.m
//  bilibili
//
//  Created by TYPCN on 2015/9/20.
//  Copyright © 2016 TYPCN. All rights reserved.
//

#import "PluginManager.h"
#import "NSBundle+OBCodeSigningInfo.h"
#import <sys/sysctl.h>
#import "MBProgressHUD.h"

@implementation PluginManager{
    NSString *sprtdir;
    NSURLSession* bgsession;
    MBProgressHUD *hud;
    NSMutableArray *availablePlugins;
    NSMutableDictionary *loadedPlugins;
    NSMutableDictionary *pluginScripts;
    int ver;
    int lastInstType;
    bool isRunning;
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
    if(last < 2){
        return nil;
    }
    NSString *key = [NSString stringWithFormat:@"%@.%@",[ary objectAtIndex:last-2],[ary objectAtIndex:last-1]];
    return pluginScripts[key];
}

- (NSArray *)getList{
    return availablePlugins;
}

- (NSDictionary *)getScript{
    return pluginScripts;
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
    availablePlugins = [[NSMutableArray alloc] init];
    
    for(id name in dirFiles){
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
        [availablePlugins addObject:@{
                                      @"file":name,
                                      @"ver":[dir objectForKey:@"CFBundleVersion"],
                                      @"domain":dm
                                      }];
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

- (void)install:(NSString *)name :(id)view :(int)instType{
    if(isRunning){
        return;
    }
    lastInstType = instType;
    isRunning = true;
    hud = [MBProgressHUD showHUDAddedTo:view animated:YES];
    hud.mode = MBProgressHUDModeIndeterminate;
    if(instType == 1){
        hud.labelText = NSLocalizedString(@"正在连接服务器", nil);
    }else{
        hud.labelText = NSLocalizedString(@"正在载入插件信息", nil);
    }
    
    hud.removeFromSuperViewOnHide = YES;
    NSString *pluginHubUrl  = @"http://vp-hub.eqoe.cn";
    NSString *pluginManifest = [NSString stringWithFormat:@"%@/api/manifest/%@.json?t=%ld",
                                                                    pluginHubUrl,name,time(0)];
    NSLog(@"Get manifest from %@",pluginManifest);
    
    NSURLSessionConfiguration* sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    bgsession = [NSURLSession sessionWithConfiguration:sessionConfig delegate:nil delegateQueue:nil];
    
    NSURL* URL = [NSURL URLWithString:pluginManifest];

    /* Start a new Task */
    NSURLSessionDataTask* task = [bgsession dataTaskWithURL:URL completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error == nil) {
            if(!data){
                hud.labelText = NSLocalizedString(@"插件信息解析失败，返回内容为空", nil);
                [self hidehud];
                return;
            }
            // Success
            NSLog(@"URL Session Task Succeeded: HTTP %ld", ((NSHTTPURLResponse*)response).statusCode);
            NSError *err;
            id object = [NSJSONSerialization JSONObjectWithData:data options:0 error:&err];
            if(!object || err){
                hud.labelText = NSLocalizedString(@"插件信息解析失败，连接可能被劫持", nil);
                [self hidehud];
                return;
            }
            
            if (![object respondsToSelector:@selector(integerForKey:)]) {
                hud.labelText = NSLocalizedString(@"插件信息解析失败，返回内容错误", nil);
                [self hidehud];
                return;
            }
            
            NSInteger minver = [object integerForKey:@"minver"];
            if(ver < minver){
                hud.labelText = NSLocalizedString(@"您的客户端版本过旧，无法安装该插件", nil);
                [self hidehud];
                return;
            }
            NSInteger maxver = [object integerForKey:@"maxver"];
            if(ver > maxver){
                hud.labelText = NSLocalizedString(@"该插件无法兼容，请等待作者更新", nil);
                [self hidehud];
                return;
            }

            NSString *downloadAddr = [object objectForKey:@"download"];
            if(!downloadAddr){
                hud.labelText = NSLocalizedString(@"没有找到下载地址", nil);
                [self hidehud];
                return;
            }
            
            if(instType == 1){
                hud.labelText = NSLocalizedString(@"正在更新解析模块", nil);
            }else{
                hud.labelText = NSLocalizedString(@"正在下载插件", nil);
            }
            hud.mode =  MBProgressHUDModeAnnularDeterminate;
            
            bgsession = [NSURLSession sessionWithConfiguration:sessionConfig delegate:self delegateQueue:nil];
            NSLog(@"Plugin download address: %@",downloadAddr);
            NSURLSessionDownloadTask *downloadTask = [bgsession downloadTaskWithURL:[NSURL URLWithString:downloadAddr]];
            [downloadTask resume];
        } else {
            if(instType == 1){
                hud.labelText = NSLocalizedString(@"解析模块更新失败", nil);
            }else{
                hud.labelText = NSLocalizedString(@"插件安装失败，无法连接到服务器", nil);
            }
            
            [self hidehud];
            NSLog(@"URL Session Task Failed: %@", [error localizedDescription]);
        }
    }];
    [task resume];
    
    
}

- (void)hidehud{
    dispatch_async(dispatch_get_main_queue(), ^(void){
        if(lastInstType == 1){
            [hud hide:YES afterDelay:0.5];
        }else{
            [hud hide:YES afterDelay:1.5];
        }
        hud.mode = MBProgressHUDModeText;
        isRunning = false;
    });
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


-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location
{
    hud.mode = MBProgressHUDModeIndeterminate;
    hud.labelText = NSLocalizedString(@"正在安装", nil);
    
    NSFileManager* fm = [NSFileManager defaultManager];
    NSString* zipPath = [location path];
    
    NSString* targetFolder = sprtdir;
    
    [fm createDirectoryAtPath:targetFolder withIntermediateDirectories:YES
                   attributes:nil error:NULL];
    
    NSArray *arguments = [NSArray arrayWithObjects:@"-o",zipPath,nil];
    NSTask *unzipTask = [[NSTask alloc] init];
    [unzipTask setLaunchPath:@"/usr/bin/unzip"];
    [unzipTask setCurrentDirectoryPath:targetFolder];
    [unzipTask setArguments:arguments];
    [unzipTask launch];
    [unzipTask waitUntilExit];
    
    if ([unzipTask terminationStatus] == 0){
        if(lastInstType == 1){
            hud.labelText = NSLocalizedString(@"解析模块更新成功", nil);
        }else{
            hud.labelText = NSLocalizedString(@"安装成功", nil);
        }
        
        loadedPlugins = [[NSMutableDictionary alloc] init];
        [self hidehud];
        [self reloadList];
    }else{
        hud.labelText = NSLocalizedString(@"插件下载失败，网络被劫持或服务器错误", nil);
        [self hidehud];
        return;
    }
}

-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    double process = (double)totalBytesWritten / totalBytesExpectedToWrite;
    dispatch_async(dispatch_get_main_queue(), ^(void){
        hud.progress = process;
    });
}

-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes
{
    NSLog(@"Session %@ download task %@ resumed at offset %lld bytes out of an expected %lld bytes.\n",
          session, downloadTask, fileOffset, expectedTotalBytes);
}

@end