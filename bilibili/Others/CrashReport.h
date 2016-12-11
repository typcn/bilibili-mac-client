//
//  CrashReport.h
//  bilibili
//
//  Created by TYPCN on 2016/3/9.
//  Copyright © 2016 TYPCN. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Crashlytics/Crashlytics.h>

@interface CrashReport : NSViewController

- (void)setCallbackHandler:(void (^)(BOOL submit))completionHandler andReport:(CLSReport *)report;

@end
