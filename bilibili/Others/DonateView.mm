//
//  DonateView.m
//  bilibili
//
//  Created by TYPCN on 2015/9/18.
//  Copyright © 2016 TYPCN. All rights reserved.
//

#import "DonateView.h"
#import "Analytics.h"

@interface DonateView ()
@property (weak) IBOutlet NSTextField *donateCount;

@end

@implementation DonateView

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (IBAction)alipayDonateBtn:(id)sender {
    NSString *url = [NSString stringWithFormat:@"https://typcn.com/pay?type=donate&amount=%d",[_donateCount intValue] ];
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:url]];
    
    [[NSUserDefaults standardUserDefaults] setObject:@"opened" forKey:@"donate"];
    action("App","donate","donate");
}

- (IBAction)hideBtn:(id)sender {
    [[NSUserDefaults standardUserDefaults] setObject:@"hide" forKey:@"donate"];
    action("App","donate","hide");
    [self.view.window close];
}


@end
