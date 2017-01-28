//
//  OtherBlockSettings.m
//  bilibili
//
//  Created by TYPCN on 2015/6/9.
//  Copyright (c) 2016 TYPCN. All rights reserved.
//

#import "OtherBlockSettings.h"

@interface OtherBlockSettings (){
    NSUserDefaults *settingsController;
}
@property (weak) IBOutlet NSButton *bb;
@property (weak) IBOutlet NSButton *bd;
@property (weak) IBOutlet NSButton *bs;
@property (weak) IBOutlet NSButton *b2b;

@property (weak) IBOutlet NSButton *removeTop;
@property (weak) IBOutlet NSButton *removeScroll;
@property (weak) IBOutlet NSButton *removeBottom;

@end

@implementation OtherBlockSettings

- (void)viewDidLoad {
    [super viewDidLoad];
    settingsController = [NSUserDefaults standardUserDefaults];
    [self.bb setState:[settingsController integerForKey:@"blcokBadword"]];
    [self.bd setState:[settingsController integerForKey:@"blockDate"]];
    [self.bs setState:[settingsController integerForKey:@"blockSpoilers"]];
    [self.b2b setState:[settingsController integerForKey:@"block2B"]];

    [self.removeTop setState:[settingsController integerForKey:@"disableTopComment"]];
    [self.removeScroll setState:[settingsController integerForKey:@"disableScrollComment"]];
    [self.removeBottom setState:[settingsController integerForKey:@"disableBottomComment"]];
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
- (IBAction)removeTop:(id)sender {
    [settingsController setInteger:[self.removeTop state] forKey:@"disableTopComment"];
    [settingsController synchronize];
}
- (IBAction)removeScroll:(id)sender {
    [settingsController setInteger:[self.removeScroll state] forKey:@"disableScrollComment"];
    [settingsController synchronize];
}
- (IBAction)removeBottom:(id)sender {
    [settingsController setInteger:[self.removeBottom state] forKey:@"disableBottomComment"];
    [settingsController synchronize];
}


@end
