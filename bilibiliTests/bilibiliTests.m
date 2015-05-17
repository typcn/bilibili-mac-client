//
//  bilibiliTests.m
//  bilibiliTests
//
//  Created by TYPCN on 2015/3/30.
//  Copyright (c) 2015 TYPCN. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>
#import "PlayerView.h"
#import "LiveChat.h"
#import "CommentFilter.h"

extern NSString *vCID;
extern NSString *vUrl;
extern BOOL isTesting;
extern BOOL isPlaying;

@interface bilibiliTests : XCTestCase{
    PlayerView *pv;
}

@end

@implementation bilibiliTests

- (void)setUp {
    [super setUp];
    isTesting = true;
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testVideoPlayback {
    XCTestExpectation *videoPlayExpectation = [self expectationWithDescription:@"Video Playing"];
    
    NSStoryboard *storyBoard = [NSStoryboard storyboardWithName:@"Main" bundle:nil]; // get a reference to the storyboard
    NSWindowController *myController = [storyBoard instantiateControllerWithIdentifier:@"MainWindowController"]; // instantiate your window controller
    [myController showWindow:self]; // show the window
    [[NSRunningApplication currentApplication] hide];
    dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        while(!isPlaying){
            [[NSRunningApplication currentApplication] hide];
            sleep(0.3);
        }
        
        NSLog(@"Will exit");

        [videoPlayExpectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        
    }];
}

- (void)testLiveChat {
    vCID = @"1029";
    XCTestExpectation *videoPlayExpectation = [self expectationWithDescription:@"Video Playing"];
    NSStoryboard *storyBoard = [NSStoryboard storyboardWithName:@"Main" bundle:nil]; // get a reference to the storyboard
    NSWindowController *myController = [storyBoard instantiateControllerWithIdentifier:@"LiveChatWindow"]; // instantiate your window controller
    [myController showWindow:self]; // show the window
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        
    }];
}

@end
