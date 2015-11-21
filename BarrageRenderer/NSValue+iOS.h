//
//  NSValue+iOS.h
//  MacMapView
//
//  Created by David Bainbridge on 5/14/13.
//  Copyright (c) 2013 David Bainbridge. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSValue (iOS)
+ (NSValue *)valueWithCGPoint:(CGPoint)point;
- (CGPoint)CGPointValue;
+ (NSValue *)valueWithCGRect:(CGRect)rect;
- (CGRect)CGRectValue;
+ (NSValue *)valueWithCGSize:(CGSize)size;
- (CGSize)CGSizeValue;
@end