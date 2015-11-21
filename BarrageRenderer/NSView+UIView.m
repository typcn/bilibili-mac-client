//
//  NSView+UIView.m
//  MapView
//
//  Created by David Bainbridge on 2/17/13.
//
//

#import "NSView+UIView.h"

@implementation NSView (UIView)

- (void)insertSubview:(NSView *)subview aboveSubview:(NSView *)above
{
    [self addSubview:subview positioned:NSWindowAbove relativeTo:above];
}

- (void)insertSubview:(NSView *)view atIndex:(NSInteger)index
{
    //TODO: use index
    [self addSubview:view];
}

- (void)exchangeSubviewAtIndex:(NSInteger)index1 withSubviewAtIndex:(NSInteger)index2
{
    NSMutableArray *subViews = [self.subviews mutableCopy];
    [subViews exchangeObjectAtIndex:index1 withObjectAtIndex:index2];
    [self setSubviews:subViews];
    
}

- (void) layoutSubviews
{
    [self resizeSubviewsWithOldSize:[self frame].size];
}


@end