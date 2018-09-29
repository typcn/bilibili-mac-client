//
//  LiveChat.m
//  bilibili
//
//  Created by TYPCN on 2015/5/17.
//  Copyright (c) 2016 TYPCN. All rights reserved.
//

#import "LiveChat.h"
#import "BarrageHeader.h"
#import "SocketProvider.h"

@interface LiveChat (){
    id socket;
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
    socket = [player getAttr:@"SocketProvider"];
    if(!socket){
        return;
    }
    [socket setDelegate:self];
    [socket loadWithPlayer:player];
    
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

- (void)onNewMessage:(NSString *)cmContent :(NSString *)userName :(int)ftype :(int)fsize :(NSColor *)color{
    dispatch_async(dispatch_get_main_queue(), ^(void){
        bool isBlocked = false;
        if([self->blockwords count] > 0){
            for (NSString* string in self->blockwords) {
                if([cmContent containsString:string]){
                    isBlocked = true;
                }
            }
        }
        if(isBlocked){
            [self AppendToTextView:[NSString stringWithFormat:@"%@ : 1条被屏蔽的弹幕\n",userName]];
        }else{
            [self addSpritToVideo:ftype content:cmContent size:fsize color:color];
            [self AppendToTextView:[NSString stringWithFormat:@"%@ : %@\n",userName,cmContent]];
        }
    });
}

- (void)onNewError:(NSString *)str{
    dispatch_async(dispatch_get_main_queue(), ^(void){
        [self AppendToTextView:[NSString stringWithFormat:NSLocalizedString(@"错误: %@\n", nil),str]];
    });
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
    [socket disconnect];
    [self.view.window close];
    NSLog(@"[LiveChat] Dealloc");
}

@end
