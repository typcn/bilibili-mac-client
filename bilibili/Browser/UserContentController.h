//
//  UserContentController.h
//  bilibili
//
//  Created by TYPCN on 2016/9/30.
//  Copyright © 2016 TYPCN. All rights reserved.
//

#import <WebKit/WebKit.h>

@interface UserContentController : WKUserContentController

+ (instancetype)sharedInstance;

@end
