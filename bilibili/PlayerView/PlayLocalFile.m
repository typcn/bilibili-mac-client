//
//  playLocalFile.m
//  bilibili
//
//  Created by TYPCN on 2015/4/5.
//  Copyright (c) 2016 TYPCN. All rights reserved.
//

#import "playLocalFile.h"


extern NSString *vUrl;
extern NSString *vCID;
extern NSString *vAID;
NSString *cmFile;
NSString *subFile;

@interface playLocalFile ()
@property (weak) IBOutlet NSTextField *videoUrl;
@property (weak) IBOutlet NSTextField *textUrl;
@property (weak) IBOutlet NSTextField *subUrl;
@property (weak) IBOutlet NSButton *playerTrigger;

@end

@implementation playLocalFile

- (void)viewDidLoad {
    [super viewDidLoad];
    vCID = @"LOCALVIDEO";
    vUrl = @"";
    vAID = @"";
    cmFile = @"";
    subFile = @"";
}
- (IBAction)selectVideo:(id)sender {
    NSOpenPanel* openDlg = [NSOpenPanel openPanel];
    [openDlg setCanChooseFiles:YES];
    [openDlg setAllowsMultipleSelection:YES];
    [openDlg setCanChooseDirectories:NO];
    [openDlg setPrompt:NSLocalizedString(@"选择视频（多选自动合并）", @"Choose Video ( Auto Concat )")];
    
    if ( [openDlg runModal] == NSModalResponseOK )
    {
        NSArray* urls = [openDlg URLs];
        for(int i = 0; i < [urls count]; i++ )
        {
            NSString *path = [[urls objectAtIndex:i] path];
            unsigned long realLength = strlen([path UTF8String]);
            
            if(i == 0){
                vUrl = [NSString stringWithFormat:@"%@%@%lu%@%@%@", @"edl://", @"%",realLength, @"%" , path ,@";"];
                vAID = path; // Store first video to vAID
            }else{
                vUrl = [NSString stringWithFormat:@"%@%@%lu%@%@%@",   vUrl   , @"%",realLength, @"%" , path ,@";"];
            }
        }
        
        [self.videoUrl setStringValue:vUrl];
    }
}
- (IBAction)setURL:(id)sender {
    if([self.videoUrl stringValue] && [[self.videoUrl stringValue] length] > 5){
        vUrl = [self.videoUrl stringValue];
    }
}
- (IBAction)selectComment:(id)sender {
    NSOpenPanel* openDlg = [NSOpenPanel openPanel];
    [openDlg setCanChooseFiles:YES];
    [openDlg setAllowsMultipleSelection:NO];
    [openDlg setCanChooseDirectories:NO];
    [openDlg setPrompt:NSLocalizedString(@"选择弹幕", @"Select Comment")];
    
    if ( [openDlg runModal] == NSModalResponseOK )
    {
        NSString* filepath = [NSString stringWithFormat:@"%@",[openDlg URL]];
        cmFile = filepath;
        [self.textUrl setStringValue:filepath];
    }
}
- (IBAction)selectSubtitle:(id)sender {
    NSOpenPanel* openDlg = [NSOpenPanel openPanel];
    [openDlg setCanChooseFiles:YES];
    [openDlg setAllowsMultipleSelection:NO];
    [openDlg setCanChooseDirectories:NO];
    [openDlg setPrompt:NSLocalizedString(@"选择字幕", @"Select Subtitle")];
    
    if ( [openDlg runModal] == NSModalResponseOK )
    {
        NSString* filepath = [NSString stringWithFormat:@"%@",[openDlg URL].path];
        subFile = filepath;
        [self.subUrl setStringValue:filepath];
    }
}
- (IBAction)playClick:(id)sender {
    [self.playerTrigger performClick:sender];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.view.window close];
    });
}

@end
