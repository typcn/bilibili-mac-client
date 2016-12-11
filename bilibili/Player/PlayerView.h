//
//  PlayerView.h
//  bilibili
//
//  Created by TYPCN on 2015/3/30.
//  Copyleft 2016 TYPCN. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "WebTabView.h"

@class Player;

@interface PlayerView : NSViewController

@property (weak) IBOutlet NSTextField *textTip;
@property (weak) IBOutlet NSTextField *subtip;
@property (weak) IBOutlet NSImageView *loadingImage;
@property (strong) NSWindowController* liveChatWC;
@property (weak, nonatomic) Player *player;
@property (nonatomic) BOOL windowSetup;

- (void)loadWithPlayer:(Player *)m_player;
- (void)loadVideo:(VideoAddress *)video;

@end