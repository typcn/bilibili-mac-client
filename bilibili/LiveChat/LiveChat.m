//
//  LiveChat.m
//  bilibili
//
//  Created by TYPCN on 2015/5/17.
//  Copyright (c) 2015 TYPCN. All rights reserved.
//

#import "LiveChat.h"
#import "BilibiliSocketClient.h"

extern NSString *vCID;
extern BOOL isTesting;

BOOL hasMsg;

@interface LiveChat (){
    LiveSocket *socket;
}
@property (unsafe_unretained) IBOutlet NSTextView *textView;

@end

@implementation LiveChat

- (void)viewDidLoad {
    [super viewDidLoad];
    socket = [[LiveSocket alloc] init];
    [socket setDelegate:self];
    [socket ConnectToTheFuckingFlashSocketServer:[vCID intValue]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowWillClose:) name:NSWindowWillCloseNotification object:self.view.window];
}

- (void)onNewMessage:(NSDictionary *)data{
    if([[data objectForKey:@"cmd"] isEqualToString:@"DANMU_MSG"]){
        NSArray *info = [data objectForKey:@"info"];
        NSString *cmContent = [info objectAtIndex:1];
        NSString *userName = [[info objectAtIndex:2] objectAtIndex:1];
        [self AppendToTextView:[NSString stringWithFormat:@"%@ : %@\n",userName,cmContent]];
        hasMsg = true;
    }
}

- (void)onNewError:(NSString *)str{
    [self AppendToTextView:[NSString stringWithFormat:NSLocalizedString(@"未知指令: %@\n", nil),str]];
}

- (void)AppendToTextView:(NSString *)text{
    
        NSFont *font = [NSFont fontWithName:@"Helvetica" size:15.0];
        NSDictionary *attrsDictionary = [NSDictionary dictionaryWithObject:font
                                                                    forKey:NSFontAttributeName];
        NSAttributedString* attr = [[NSAttributedString alloc] initWithString:text attributes:attrsDictionary];
        
        [[self.textView textStorage] appendAttributedString:attr];
        [self.textView scrollRangeToVisible:NSMakeRange([[self.textView string] length], 0)];
}

- (void)windowWillClose:(NSNotification *)notification
{
    NSString *name = [notification.object className];
    if([name isEqualToString:@"PostCommentWindow"]){
        return;
    }else if([name isEqualToString:@"PlayerWindow"]){
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        [socket Disconnect];
        [self.view.window close];
    }else{
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        [socket Disconnect];
    }
}

@end
