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
    [self.disablebottomComment setState:[settingsController integerForKey:@"disableBottomComment"]];
    [self.playMP4 setState:[settingsController integerForKey:@"playMP4"]];
    [self.DownloadMP4 setState:[settingsController integerForKey:@"DLMP4"]];
    [self.disableKeepAspect setState:[settingsController integerForKey:@"disableKeepAspect"]];
    [self.disableHwDec setState:[settingsController integerForKey:@"enableHW"]];
    
    float trans = [settingsController floatForKey:@"transparency"];
    if(!trans){
        trans = 0.8;
    }
    [self.transparency setFloatValue:trans];
    
    NSString *quality = [settingsController objectForKey:@"quality"];
    if(!quality){
        quality = NSLocalizedStringFromTable(@"UtE-Jc-IKj.ibShadowedObjectValues[3]", @"Main", @"原画");
    }
    [self.qualityBox setStringValue:quality];
    
    NSString *IP = [settingsController objectForKey:@"xff"];
    if([IP length] > 4){
        [self.FakeIP setStringValue:[settingsController objectForKey:@"xff"]];
    }
    
    float fontsize = [settingsController floatForKey:@"fontsize"];
    if(!fontsize){
        fontsize = 25.1;
    }
    [self.fontsize setFloatValue:fontsize];
    
    float moveSpeed = [settingsController floatForKey:@"moveSpeed"];
    if(!moveSpeed){
        moveSpeed = 0.0;
    }
    [self.commentMoveSpeed setFloatValue:moveSpeed];
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
- (IBAction)fontsizeChanged:(id)sender {
    [settingsController setFloat:[self.fontsize floatValue] forKey:@"fontsize"];
    [settingsController synchronize];
}

- (IBAction)disableBottomComment:(id)sender {
    [settingsController setInteger:[self.disablebottomComment state] forKey:@"disableBottomComment"];
    [settingsController synchronize];
}

- (IBAction)playMP4Changed:(id)sender {
    [settingsController setInteger:[self.playMP4 state] forKey:@"playMP4"];
    [settingsController synchronize];
}
- (IBAction)DLMP4Changed:(id)sender {
    [settingsController setInteger:[self.DownloadMP4 state] forKey:@"DLMP4"];
    [settingsController synchronize];
}
- (IBAction)disableKeepAspectRatioChanged:(id)sender {
    [settingsController setInteger:[self.disableKeepAspect state] forKey:@"disableKeepAspect"];
    [settingsController synchronize];
}
- (IBAction)moveSpeedChanged:(id)sender {
    [settingsController setFloat:[self.commentMoveSpeed floatValue] forKey:@"moveSpeed"];
    [settingsController synchronize];
}
- (IBAction)disableHwdec:(id)sender {
    [settingsController setInteger:[self.disableHwDec state] forKey:@"enableHW"];
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
    return min + arc4random_uniform((u_int32_t)max - (u_int32_t)min + 1);
}
@end
