//
//  Browser.h
//  bilibili
//
//  Created by TYPCN on 2015/9/3.
//  Copyright (c) 2015 TYPCN. All rights reserved.
//

#import <ChromiumTabs/ChromiumTabs.h>
#import "AppDelegate.h"
#import <WebKit/WebKit.h>
#import "MBProgressHUD.h"

@interface Browser : CTBrowser

-(CTTabContents*)createTabBasedOn:(CTTabContents*)baseContents withUrl:(NSString*) url;

@end
