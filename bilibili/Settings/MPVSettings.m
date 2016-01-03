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
    
    NSString *settings = [[NSUserDefaults standardUserDefaults] objectForKey:@"mpvSettings"];
    if(settings && [settings length] > 1){
        [self.textView setString:settings];
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowWillClose:) name:NSWindowWillCloseNotification object:self.view.window];
}

- (void)windowWillClose:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    if(![[self.textView string] length]){
        return;
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:[self.textView string] forKey:@"mpvSettings"];
}

@end
