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

@interface playLocalFile ()

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
    [openDlg setPrompt:@"选择视频"];
    
    if ( [openDlg runModal] == NSModalResponseOK )
    {
        NSString* filepath = [openDlg URL].path;
        vUrl = filepath;
    }
}
- (IBAction)selectComment:(id)sender {
    NSOpenPanel* openDlg = [NSOpenPanel openPanel];
    [openDlg setCanChooseFiles:YES];
    [openDlg setAllowsMultipleSelection:NO];
    [openDlg setCanChooseDirectories:NO];
    [openDlg setPrompt:@"选择弹幕"];
    
    if ( [openDlg runModal] == NSModalResponseOK )
    {
        NSString* filepath = [NSString stringWithFormat:@"%@",[openDlg URL]];
        cmFile = filepath;
    }
}

@end
