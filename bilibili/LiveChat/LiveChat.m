//
//  LiveChat.m
//  bilibili
//
//  Created by TYPCN on 2015/5/17.
//  Copyright (c) 2016 TYPCN. All rights reserved.
//

#import "LiveChat.h"
#import "BilibiliSocketClient.h"
#import "BarrageHeader.h"

@interface LiveChat (){
    LiveSocket *socket;
    NSArray *blockwords;
    BOOL renderDisabled;

    BarrageRenderer *renderer;
}
@property (unsafe_unretained) IBOutlet NSTextView *textView;

@end

@implementation LiveChat

- (void)setPlayerAndInit:(Player *)player{
    self.player = player;
    renderDisabled = false;
    socket = [[LiveSocket alloc] init];
    [socket setDelegate:self];
    [socket ConnectToTheFuckingFlashSocketServer:[[self.player getAttr:@"cid"] intValue]];
    NSString *block = [[NSUserDefaults standardUserDefaults] objectForKey:@"blockKeywords"];
    NSArray *blocks = [block componentsSeparatedByString:@"|"];
    if([block length] > 0 && [blocks count] > 0){
        blockwords = blocks;
    }
    renderer = self.player.barrageRenderer;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)onNewMessage:(NSDictionary *)data{
    if([[data objectForKey:@"cmd"] isEqualToString:@"DANMU_MSG"]){
        NSArray *info = [data objectForKey:@"info"];
        NSString *cmContent = [info objectAtIndex:1];
        NSString *userName = [[info objectAtIndex:2] objectAtIndex:1];
        int ftype = [[[info objectAtIndex:0] objectAtIndex:1] intValue];
        int fsize = [[[info objectAtIndex:0] objectAtIndex:2] intValue];
        unsigned int intColor = [[[info objectAtIndex:0] objectAtIndex:3] intValue];
        NSColor  *Color  = [NSColor colorWithRed:((float)((intColor & 0xFF0000) >> 16))/255.0 \
                                           green:((float)((intColor & 0x00FF00) >>  8))/255.0 \
                                            blue:((float)((intColor & 0x0000FF) >>  0))/255.0 \
                                           alpha:1.0];
        
        bool isBlocked = false;
        if([blockwords count] > 0){
            for (NSString* string in blockwords) {
                if([cmContent containsString:string]){
                    isBlocked = true;
                }
            }
        }
        if(isBlocked){
            [self AppendToTextView:[NSString stringWithFormat:@"%@ : 1条被屏蔽的弹幕\n",userName]];
        }else{
            [self addSpritToVideo:ftype content:cmContent size:fsize color:Color];
            [self AppendToTextView:[NSString stringWithFormat:@"%@ : %@\n",userName,cmContent]];
        }
    }
}

- (void)onNewError:(NSString *)str{
   // [self AppendToTextView:[NSString stringWithFormat:NSLocalizedString(@"未知指令: %@\n", nil),str]];
}

- (void)AppendToTextView:(NSString *)text{
    
        NSFont *font = [NSFont fontWithName:@"Helvetica" size:15.0];
        NSDictionary *attrsDictionary = [NSDictionary dictionaryWithObject:font
                                                                    forKey:NSFontAttributeName];
        NSAttributedString* attr = [[NSAttributedString alloc] initWithString:text attributes:attrsDictionary];
        
        [[self.textView textStorage] appendAttributedString:attr];
        [self.textView scrollRangeToVisible:NSMakeRange([[self.textView string] length], 0)];
}

- (void)addSpritToVideo:(int)type content:(NSString*)content size:(int)size color:(NSColor *)color
{
    BarrageDescriptor * descriptor = [[BarrageDescriptor alloc]init];
    descriptor.spriteName = NSStringFromClass([BarrageWalkTextSprite class]);
    descriptor.params[@"text"] = content;
    descriptor.params[@"textColor"] = color;
    descriptor.params[@"fontSize"] = @(size);
    descriptor.params[@"speed"] = @(100);
    
    // type is not supported right
    descriptor.params[@"direction"] = @(BarrageWalkDirectionR2L);
    [renderer receive:descriptor];
}

- (IBAction)disableRender:(id)sender {
    if(renderDisabled){
        renderDisabled = false;
        [sender setTitle:@"关闭弹幕渲染"];
        [renderer start];
    }else{
        renderDisabled = true;
        [sender setTitle:@"开启弹幕渲染"];
        [renderer stop];
    }
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.player.barrageRenderer stop];
    [socket Disconnect];
    [self.view.window close];
    NSLog(@"[LiveChat] Dealloc");
}

@end
