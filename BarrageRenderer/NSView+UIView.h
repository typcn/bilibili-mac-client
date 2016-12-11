//
//  NSView+UIView.h
//  MapView
//
//  Created by David Bainbridge on 2/17/13.
//
//

#import <Cocoa/Cocoa.h>

@interface NSView (UIView)
- (void)insertSubview:(NSView *)subview aboveSubview:(NSView *)above;
- (void)insertSubview:(NSView *)view atIndex:(NSInteger)index;
- (void)exchangeSubviewAtIndex:(NSInteger)index1 withSubviewAtIndex:(NSInteger)index2;
- (void)layoutSubviews;
@end