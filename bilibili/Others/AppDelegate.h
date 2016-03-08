//
//  AppDelegate.h
//  bilibili
//
//  Created by TYPCN on 2015/3/30.
//  Copyleft 2016 TYPCN. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>
#import "Browser.h"

@interface AppDelegate : NSObject <NSApplicationDelegate, CrashlyticsDelegate>

@property (strong) NSWindowController* donatew;
@property (strong) NSWindowController* crashw;

@end

