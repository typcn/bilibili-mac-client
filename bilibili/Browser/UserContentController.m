//
//  UserContentController.m
//  bilibili
//
//  Created by TYPCN on 2016/9/30.
//  Copyright © 2016 TYPCN. All rights reserved.
//

#import "UserContentController.h"

@implementation UserContentController
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
        // TODO: Cloud update block list
        NSString *path = [[NSBundle mainBundle] pathForResource:@"webpage/blocker" ofType:@"js"];
        NSString *str = [[NSString alloc] initWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
        WKUserScript *script = [[WKUserScript alloc] initWithSource:str injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:NO];
        [self addUserScript:script];
        
    }
    return self;
}

@end
