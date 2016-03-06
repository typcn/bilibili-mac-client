//
//  MPVSettings.m
//  bilibili
//
//  Created by TYPCN on 2015/10/31.
//  Copyright © 2016 TYPCN. All rights reserved.
//

#import "MPVSettings.h"

@interface MPVSettings ()
@property (unsafe_unretained) IBOutlet NSTextView *textView;

@end

@implementation MPVSettings

- (void)viewDidLoad {
    [super viewDidLoad];

}

- (void)windowWillClose:(NSNotification *)notification
{

}

- (IBAction)openMpvConfDir:(id)sender {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *applicationSupportDirectory = [paths firstObject];
    NSString *confDir = [NSString stringWithFormat:@"%@/com.typcn.bilibili/conf/",applicationSupportDirectory];
    
    BOOL isDir = NO;
    BOOL isExist = [[NSFileManager defaultManager] fileExistsAtPath:confDir isDirectory:&isDir];
    if(!isExist){
        [[NSFileManager defaultManager] createDirectoryAtPath:confDir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    [[NSWorkspace sharedWorkspace] openFile:confDir withApplication:@"Finder"];
}


@end
