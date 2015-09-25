//
//  PluginManager.h
//  bilibili
//
//  Created by TYPCN on 2015/9/20.
//  Copyright © 2015 TYPCN. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <VPPlugin/VPPlugin.h>

@interface PluginManager : NSObject

+ (instancetype)sharedInstance;
- (void)reloadList;
- (id)Get:(NSString *)action;
- (void)install:(NSString *)URL;
- (void)enable:(NSString *)name;
- (void)disable:(NSString *)name;


- (NSString *)javascriptForDomain:(NSString *)domain;

@end
