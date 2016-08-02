//
//  VP_Local.m
//  bilibili
//
//  Created by TYPCN on 2016/3/6.
//  Copyright © 2016 TYPCN. All rights reserved.
//

#import "VP_Local.h"

@implementation VP_Local

+ (instancetype)sharedInstance {
    static id sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (NSDictionary *)generateParamsFromURL: (NSString *)URL{
    return NULL;
}

- (VideoAddress *) getVideoAddress: (NSDictionary *)params{
    if(!params[@"files"]){
        [NSException raise:@VP_PARAM_ERROR format:@"Files cannot be empty"];
        return NULL;
    }
    
    NSArray *selectedFiles = params[@"files"];

    VideoAddress *video = [[VideoAddress alloc] init];
    
    for(int i = 0; i < [selectedFiles count]; i++ )
    {
        NSString *path = [selectedFiles objectAtIndex:i];
        
        if(![[path pathExtension] isEqualToString:@"xml"] &&
           ![[path pathExtension] isEqualToString:@"ass"]){
            
            if(![video firstFragmentURL]){
                [video setFirstFragmentURL:path];
            }
            
            [video addDefaultPlayURL:path];
        }
    }
    
    return video;
}

@end
