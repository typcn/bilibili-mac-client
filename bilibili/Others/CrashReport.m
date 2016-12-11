//
//  CrashReport.m
//  bilibili
//
//  Created by TYPCN on 2016/3/9.
//  Copyright © 2016 TYPCN. All rights reserved.
//

#import "CrashReport.h"

@interface CrashReport ()

@property (nonatomic, copy) void (^handler)(BOOL submit);
@property (nonatomic) CLSReport *creport;

@property (unsafe_unretained) IBOutlet NSTextView *textView;
@property (weak) IBOutlet NSTextField *emailField;
@end

@implementation CrashReport

@synthesize handler;
@synthesize creport;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

- (void)setCallbackHandler:(void (^)(BOOL submit))completionHandler andReport:(CLSReport *)report{
    handler = completionHandler;
    creport = report;
}

- (IBAction)doNotSend:(id)sender {
    handler(NO);
    [self.view.window close];
}


- (IBAction)sendCrashReport:(id)sender {
    NSString *customText = self.textView.textStorage.string;
    if(customText && customText.length){
        [creport setObjectValue:customText forKey:@"userCustomText"];
    }
    NSString *userEmail = self.emailField.stringValue;
    if(userEmail && userEmail.length){
        [creport setUserEmail:userEmail];
    }
    handler(YES);
    [self.view.window close];
}

@end
