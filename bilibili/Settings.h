//
//  Settings.h
//  bilibili
//
//  Created by TYPCN on 2015/4/6.
//  Copyright (c) 2015 TYPCN. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface Settings : NSViewController

@property (weak) IBOutlet NSButton *autoPlay;
@property (weak) IBOutlet NSComboBox *qualityBox;
@property (weak) IBOutlet NSButton *RealTimeComment;
@property (weak) IBOutlet NSSlider *transparency;

@end
