//
//  AddressBar.m
//  bilibili
//
//  Created by TYPCN on 2015/12/16.
//  Copyright © 2016 TYPCN. All rights reserved.
//

#import "AddressBar.h"
#import "Browser.h"
#import "WebTabView.h"

NSString *sharedURLFieldString;

@implementation AddressBar{
    BOOL isLoaded;
    BOOL isEditing;
    NSTableView *ASTable;
    NSTimer *textChangeTimer;
}

- (BOOL)acceptsFirstResponder{
    return TRUE;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    if(!isLoaded){
        [self setDelegate:self];
        [self loadSuggestView];
        isLoaded = true;
    }
}

- (void)loadSuggestView{
    NSArray *tlo;
    BOOL c = [[NSBundle mainBundle] loadNibNamed:@"AutoSuggestTable" owner:ASTable topLevelObjects:&tlo];
    if(c){
        for(int i=0;i<tlo.count;i++){
            NSString *cname = [tlo[i] className];
            if([cname isEqualToString:@"NSScrollView"]){
                ASTable = tlo[i];
            }
        }
    }
}

- (void)controlTextDidChange:(NSNotification *)note {
    if(note && [note object]){
        sharedURLFieldString = [[note object] stringValue];
    }
    if(textChangeTimer){
        [textChangeTimer invalidate];
    }
    textChangeTimer = [NSTimer scheduledTimerWithTimeInterval:(0.5)
                                                                   target:self
                                                                 selector:@selector(updateSuggestContext)
                                                                 userInfo:nil 
                                                                  repeats:NO];
}

- (void)updateSuggestContext{
    WebTabView *tc = (WebTabView *)[browser activeTabContents];
    id tv = [tc GetTWebView];
    if(!tv){
        return;
    }
    id wv = [tv GetWebView];
    if(!wv){
        return;
    }
    if([wv subviews] && [wv subviews][0]){
        id contentView = [wv subviews][0];
        [ASTable setFrameSize:NSMakeSize([contentView frame].size.width, 200)];
        [contentView addSubview:ASTable];
    }
}

- (BOOL)textShouldEndEditing:(NSText *)textObject{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [ASTable removeFromSuperview];
    });
    isEditing = false;
    return YES;
}

@end
