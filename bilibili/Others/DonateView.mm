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
@property (weak) IBOutlet NSTextField *PPdonateCount;
@property (weak) IBOutlet NSTextField *alipayDonateCount;

@end

@implementation DonateView

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (IBAction)PPdonateBtn:(id)sender {
    NSString *base = @"https://www.paypal.com/cgi-bin/webscr?cmd=_xclick&business=donate%40typcn%2ecom&lc=C2&item_name=Bilibili%20for%20mac%20%2d%20Donation&amount=";
    NSString *after = @"%2e00&currency_code=USD&button_subtype=services&no_note=0&tax_rate=0%2e000&shipping=0%2e00&bn=PP%2dBuyNowBF%3abtn_buynowCC_LG%2egif%3aNonHostedGuest";
    
    int count = [self.PPdonateCount intValue];
    
    NSString *url = [NSString stringWithFormat:@"%@%d%@",base, count , after];
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:url]];
    
    [[NSUserDefaults standardUserDefaults] setObject:@"opened" forKey:@"donate"];
    action("App","donate","paypal");
}

- (IBAction)alipayDonateBtn:(id)sender {
    int count = [self.alipayDonateCount intValue];
    
    NSString *url = [NSString stringWithFormat:@"https://secure.eqoe.cn/tpaymentGateway.typ?type=donate&platform=bilimac&amount=%d",count];
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:url]];
    
    [[NSUserDefaults standardUserDefaults] setObject:@"opened" forKey:@"donate"];
    action("App","donate","alipay");
}

- (IBAction)copyBitcoinAddr:(id)sender {
    NSPasteboard *pasteBoard = [NSPasteboard generalPasteboard];
    [pasteBoard declareTypes:[NSArray arrayWithObjects:NSStringPboardType, nil] owner:nil];
    [pasteBoard setString:@"1EprnUzBwcF52SZAnPZKRrj4rRaS6yhtQW" forType:NSStringPboardType];
    
    [[NSUserDefaults standardUserDefaults] setObject:@"copied" forKey:@"donate"];
    action("App","donate","bitcoin");
}

- (IBAction)hideBtn:(id)sender {
    [[NSUserDefaults standardUserDefaults] setObject:@"hidede" forKey:@"donate"];
    action("App","donate","hide");
    [self.view.window close];
}


@end
