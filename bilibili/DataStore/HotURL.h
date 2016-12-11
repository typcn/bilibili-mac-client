//
//  HotURL.h
//  bilibili
//
//  Created by TYPCN on 2016/1/26.
//  Copyright © 2016 TYPCN. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <FMDB/FMDB.h>

@interface HotURL : NSObject

- (instancetype)initWithDatabase:(FMDatabase *)icdb path:(NSString *)path;
- (BOOL)appendURL:(NSString *)URL;
- (void)trimData;

@end
