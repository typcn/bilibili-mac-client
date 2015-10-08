//
//  Popover.m
//  bilibili
//
//  Created by TYPCN on 2015/10/8.
//  Copyright © 2015 TYPCN. All rights reserved.
//

#import "Popover.h"

@implementation Popover{
    id monitor;
    NSStatusItem *SBItem;
    NSPopover *popover;
}


- (id)init{
    self = [super init];
    if (self) {
        popover = [[NSPopover alloc] init];
        popover.contentViewController = [[NSViewController alloc] initWithNibName:@"DynamicView" bundle:[NSBundle mainBundle]];
    }
    return self;
}

- (void)startMonitor{
    monitor = [NSEvent addGlobalMonitorForEventsMatchingMask:NSLeftMouseDownMask | NSRightMouseDownMask handler:^(NSEvent* evt){
        if(popover.shown){
            [self hidePopover:evt];
        }
    }];
}

- (void)removeMonitor{
    if(monitor){
        [NSEvent removeMonitor:monitor];
        monitor = nil;
    }
}

- (void)addToStatusBar {
    SBItem = [[NSStatusBar systemStatusBar] statusItemWithLength:-1];
    NSButton *btn = SBItem.button;
    btn.image = [NSImage imageNamed:@"StatusBarImg"];
    btn.action = @selector(toggleBtn:);
}

- (void)toggleBtn:(id)sender{
    if(popover.shown){
       [self hidePopover:sender];
    } else {
       [self showPopover:sender];
    }
}

- (void)showPopover:(id)sender{
    id button = SBItem.button;
    if(button){
        [popover showRelativeToRect:[button bounds] ofView:button preferredEdge:NSRectEdgeMinY];
    }
    [self startMonitor];
}

- (void)hidePopover:(id)sender{
    [popover performClose:sender];
    [self removeMonitor];
}

- (void)dealloc {
    [self removeMonitor];
}

@end
