//
//  playLocalFile.m
//  bilibili
//
//  Created by TYPCN on 2015/4/5.
//  Copyright (c) 2015 TYPCN. All rights reserved.
//

#import "playLocalFile.h"


extern NSString *vUrl;
extern NSString *vCID;
NSString *cmFile;
NSString *subFile;

@interface playLocalFile ()
@property (weak) IBOutlet NSTextField *videoUrl;
@property (weak) IBOutlet NSTextField *textUrl;
@property (weak) IBOutlet NSTextField *subUrl;

@end

@implementation playLocalFile

- (void)viewDidLoad {
    [super viewDidLoad];
    vCID = @"LOCALVIDEO";
}
- (IBAction)selectVideo:(id)sender {
    NSOpenPanel* openDlg = [NSOpenPanel openPanel];
    [openDlg setCanChooseFiles:YES];
    [openDlg setAllowsMultipleSelection:NO];
    [openDlg setCanChooseDirectories:NO];
    [openDlg setPrompt:NSLocalizedString(@"选择视频", @"Choose Video")];
    
    if ( [openDlg runModal] == NSModalResponseOK )
    {
        NSString* filepath = [openDlg URL].path;
        vUrl = filepath;
        [self.videoUrl setStringValue:filepath];
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

@end
