//
//  Settings.h
//  bilibili
//
//  Created by TYPCN on 2015/4/6.
//  Copyright (c) 2016 TYPCN. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface Settings : NSViewController

@property (weak) IBOutlet NSButton *autoPlay;
@property (weak) IBOutlet NSComboBox *qualityBox;
@property (weak) IBOutlet NSButton *RealTimeComment;
@property (weak) IBOutlet NSSlider *transparency;
@property (weak) IBOutlet NSComboBox *FakeIP;
@property (weak) IBOutlet NSTextField *fontsize;
@property (weak) IBOutlet NSTextField *fontName;
@property (weak) IBOutlet NSButton *disablebottomComment;
@property (weak) IBOutlet NSButton *playMP4;
@property (weak) IBOutlet NSButton *DownloadMP4;
@property (weak) IBOutlet NSButton *disableKeepAspect;
@property (weak) IBOutlet NSSlider *commentMoveSpeed;
@property (weak) IBOutlet NSButton *disableHwDec;
@property (weak) IBOutlet NSButton *disableWriteHistory;
@property (weak) IBOutlet NSTextField *maxBufferSize;
@property (weak) IBOutlet NSButton *changeGestureDirection;

@end
