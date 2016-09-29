//
//  CloudScript.h
//  bilibili
//
//  Created by TYPCN on 2016/9/30.
//  Copyright © 2016 TYPCN. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CloudScript : NSObject

+ (instancetype)sharedInstance;
- (void)updateScript;
- (NSString *)get;

@end
