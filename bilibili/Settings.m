//
//  Settings.m
//  bilibili
//
//  Created by TYPCN on 2015/4/6.
//  Copyright (c) 2015 TYPCN. All rights reserved.
//

#import "Settings.h"

@interface Settings (){
    NSUserDefaults *settingsController;
}

@end

@implementation Settings

- (void)viewDidLoad {
    [super viewDidLoad];
    settingsController = [NSUserDefaults standardUserDefaults];
    
    [self.autoPlay setState:[settingsController integerForKey:@"autoPlay"]];
    [self.RealTimeComment setState:[settingsController integerForKey:@"RealTimeComment"]];
    
    float trans = [settingsController floatForKey:@"transparency"];
    if(!trans){
        trans = 0.8;
    }
    [self.transparency setFloatValue:trans];
    
    NSString *quality = [settingsController objectForKey:@"quality"];
    if([quality length] != 2){
        quality = @"原画";
    }
    [self.qualityBox setStringValue:quality];
    NSString *IP = [settingsController objectForKey:@"xff"];
    if([IP length] > 4){
        [self.FakeIP setStringValue:[settingsController objectForKey:@"xff"]];
    }
}

- (IBAction)autoPlay:(id)sender {
    [settingsController setInteger:[self.autoPlay state] forKey:@"autoPlay"];
    [settingsController synchronize];
}
- (IBAction)disableRealTimeComment:(id)sender {
    [settingsController setInteger:[self.RealTimeComment state] forKey:@"RealTimeComment"];
    [settingsController synchronize];
}
- (IBAction)qualityChanged:(id)sender {
    [settingsController setObject:[self.qualityBox stringValue] forKey:@"quality"];
    [settingsController synchronize];
}
- (IBAction)transparencyChanged:(id)sender {
    [settingsController setFloat:[self.transparency floatValue] forKey:@"transparency"];
    [settingsController synchronize];

}
- (IBAction)FakeIPChanged:(id)sender {
    NSString *rand = [NSString stringWithFormat:@"%ld", (long)[self randomNumberBetween:1 maxNumber:254]];
    NSString *str = [[self.FakeIP stringValue] stringByReplacingOccurrencesOfString:@"[RANDOM]"
                                                                         withString:rand];
    [settingsController setObject:str forKey:@"xff"];
    [settingsController synchronize];
    NSLog(@"IP Changed to: %@",str);
}

- (NSInteger)randomNumberBetween:(NSInteger)min maxNumber:(NSInteger)max
{
    return min + arc4random_uniform(max - min + 1);
}
@end
