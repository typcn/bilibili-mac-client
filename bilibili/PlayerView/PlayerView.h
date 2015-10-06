//
//  PlayerView.h
//  bilibili
//
//  Created by TYPCN on 2015/3/30.
//  Copyleft 2015 TYPCN. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PlayerView : NSViewController
@property (weak) IBOutlet NSTextField *textTip;
@property (weak) IBOutlet NSTextField *subtip;
@property (weak) IBOutlet NSImageView *loadingImage;
@property (weak) IBOutlet NSButton *showLiveChat;

- (NSDictionary *) getVideoInfo:(NSString *)url;
- (NSString *) getComments:(NSNumber *)width :(NSNumber *)height;
- (void)LoadVideo;

@end


@interface PlayerWindow : NSWindow <NSWindowDelegate>

@property (strong) NSWindowController* postCommentWindowC;

-(void)keyDown:(NSEvent*)event;

@end