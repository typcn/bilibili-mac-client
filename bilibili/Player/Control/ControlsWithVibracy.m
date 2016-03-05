//
//  ControlsWithVibracy.m
//  bilibili
//
//  Created by TYPCN on 2016/3/6.
//  Copyright © 2016 TYPCN. All rights reserved.
//

#import "ControlsWithVibracy.h"

@implementation NSButtonWithVibracy

- (BOOL)allowsVibrancy{
    return YES;
}

@end


@implementation NSViewWithVibracy

- (BOOL)allowsVibrancy{
    return YES;
}

@end


@implementation NSTextFieldWithVibracy

- (BOOL)allowsVibrancy{
    return YES;
}

@end