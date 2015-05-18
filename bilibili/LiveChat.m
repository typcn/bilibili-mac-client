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

@interface LiveChat ()
@property (unsafe_unretained) IBOutlet NSTextView *textView;

@end

@implementation LiveChat

- (void)viewDidLoad {
    [super viewDidLoad];
    LiveSocket *socket = [[LiveSocket alloc] init];
    [socket setDelegate:self];
    [socket ConnectToTheFuckingFlashSocketServer:[vCID intValue]];
}

- (void)onNewMessage:(NSDictionary *)data{
    if([[data objectForKey:@"cmd"] isEqualToString:@"DANMU_MSG"]){
        NSArray *info = [data objectForKey:@"info"];
        NSString *cmContent = [info objectAtIndex:1];
        NSString *userName = [[info objectAtIndex:2] objectAtIndex:1];
        [self AppendToTextView:[NSString stringWithFormat:@"%@ : %@\n",userName,cmContent]];
    }
}

- (void)onNewError:(NSString *)str{
    [self AppendToTextView:[NSString stringWithFormat:@"错误指令: %@\n",str]];
}

- (void)AppendToTextView:(NSString *)text{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSAttributedString* attr = [[NSAttributedString alloc] initWithString:text];
        
        [[self.textView textStorage] appendAttributedString:attr];
        [self.textView scrollRangeToVisible:NSMakeRange([[self.textView string] length], 0)];
    });
}


@end
