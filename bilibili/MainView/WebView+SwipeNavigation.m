//
//  WebView+SwipeNavigation.m
//  bilibili
//
//  Created by Carmelo Sui on 6/21/15.
//  Copyright (c) 2015 TYPCN. All rights reserved.
//

#import "WebView+SwipeNavigation.h"

@implementation WebView (SwipeNavigation)

- (void)swipeWithEvent:(NSEvent *)event {
    CGFloat deltaX = [event deltaX];
    if (deltaX > 0) {
        [self goForward];
    } else if (deltaX < 0) {
        [self goBack];
    }
}

@end
