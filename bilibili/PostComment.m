//
//  PostComment.m
//  bilibili
//
//  Created by TYPCN on 2015/4/4.
//  Copyright (c) 2015 TYPCN. All rights reserved.
//

#import "PostComment.h"

@interface PostComment ()

@end

@implementation PostComment


- (void)viewDidLoad {
    [super viewDidLoad];
    //[self.view.window makeKeyWindow];
    [self.view.window makeFirstResponder:self];
}

@end

@interface PostCommentWindow : NSWindow <NSWindowDelegate>

@end

@implementation PostCommentWindow{
    
}

- (BOOL)canBecomeMainWindow { return YES; }
- (BOOL)canBecomeKeyWindow { return YES; }
- (BOOL) becomeFirstResponder { return YES; }
- (BOOL) resignFirstResponder { return YES; }

@end