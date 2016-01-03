//
//  SmartBlockSettings.m
//  bilibili
//
//  Created by TYPCN on 2015/6/9.
//  Copyright (c) 2016 TYPCN. All rights reserved.
//

#import "SmartBlockSettings.h"

@interface SmartBlockSettings (){
    NSUserDefaults *settingsController;
}
@property (weak) IBOutlet NSButton *bb;
@property (weak) IBOutlet NSButton *bd;
@property (weak) IBOutlet NSButton *bs;
@property (weak) IBOutlet NSButton *b2b;

@end

@implementation SmartBlockSettings

- (void)viewDidLoad {
    [super viewDidLoad];
    settingsController = [NSUserDefaults standardUserDefaults];
    [self.bb setState:[settingsController integerForKey:@"blcokBadword"]];
    [self.bd setState:[settingsController integerForKey:@"blockDate"]];
    [self.bs setState:[settingsController integerForKey:@"blockSpoilers"]];
    [self.b2b setState:[settingsController integerForKey:@"block2B"]];
}
- (IBAction)blcokBadword:(id)sender {
    [settingsController setInteger:[sender state] forKey:@"blcokBadword"];
    [settingsController synchronize];
}
- (IBAction)blockDate:(id)sender {
    [settingsController setInteger:[sender state] forKey:@"blockDate"];
    [settingsController synchronize];
}
- (IBAction)blockSpoilers:(id)sender {
    [settingsController setInteger:[sender state]forKey:@"blockSpoilers"];
    [settingsController synchronize];
}
- (IBAction)block2B:(id)sender {
    [settingsController setInteger:[sender state] forKey:@"block2B"];
    [settingsController synchronize];
}

@end
