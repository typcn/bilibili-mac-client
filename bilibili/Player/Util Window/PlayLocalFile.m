//
//  playLocalFile.m
//  bilibili
//
//  Created by TYPCN on 2015/4/5.
//  Copyright (c) 2016 TYPCN. All rights reserved.
//

#import "playLocalFile.h"
#import "VideoAddress.h"
#import "PlayerLoader.h"


@interface playLocalFile ()
@property (weak) IBOutlet NSTextField *videoUrl;
@property (weak) IBOutlet NSTextField *textUrl;
@property (weak) IBOutlet NSTextField *subUrl;
@property (weak) IBOutlet NSButton *playerTrigger;

@end

@implementation playLocalFile{
    VideoAddress *video;
    NSMutableDictionary *attrs;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    video = [[VideoAddress alloc] init];
    attrs = [[NSMutableDictionary alloc] init];
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
            
            if(i == 0){
                [video setFirstFragmentURL:path];
            }
            
            [video addDefaultPlayURL:path];
        }
        
        attrs[@"files"] = [video defaultPlayURL];
        [self.videoUrl setStringValue:[NSString stringWithFormat:@"合并 %lu 个本地文件",(unsigned long)[urls count]]];
    }
}
- (IBAction)setURL:(id)sender {
    if([[self.videoUrl stringValue] containsString:@" 个本地文件"]){
        return;
    }else if([self.videoUrl stringValue]){
        [video setFirstFragmentURL:[self.videoUrl stringValue]];
        [video setDefaultPlayURL:[@[
                                    [self.videoUrl stringValue]
                                    ] mutableCopy]];
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
        NSString* filepath = [NSString stringWithFormat:@"%@",[openDlg URL].path];
        attrs[@"commentFile"] = filepath;
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
        attrs[@"subtitleFile"] = filepath;
        [self.subUrl setStringValue:filepath];
    }
}
- (IBAction)playClick:(id)sender {
    [[PlayerLoader sharedInstance] loadVideo:video withAttrs:attrs];
    [self.view.window close];
}

@end
