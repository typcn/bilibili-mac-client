/*
 * MPlayerX - TimeSliderCell.m
 *
 * Copyright (C) 2009 - 2011, Zongyao QU
 *
 * MPlayerX is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * MPlayerX is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with MPlayerX; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */
// Updated by TYPCN on 3/5/16

#import "TimeSliderCell.h"

@implementation TimeSliderCell

@synthesize dragging;

-(id) initWithCoder:(NSCoder*) decoder
{
    self = [super initWithCoder:decoder];
    
    if (self) {
        dragging = NO;
        dragState = kTSDragStopped;
    }
    return self;
}

-(BOOL) startTrackingAt:(NSPoint)startPoint inView:(NSView*)controlView
{
    // MPLog(@"Start Trackinng");
    dragState = kTSDragStarted;
    
    return [super startTrackingAt:startPoint inView:controlView];
}

- (void)stopTracking:(NSPoint)lastPoint at:(NSPoint)stopPoint inView:(NSView *)controlView mouseIsUp:(BOOL)flag
{
    // MPLog(@"Stop Tracking\n");
    dragState = kTSDragStopped;
    
    [super stopTracking:lastPoint at:stopPoint inView:controlView mouseIsUp:flag];
}

- (BOOL)continueTracking:(NSPoint)lastPoint at:(NSPoint)currentPoint inView:(NSView *)controlView
{
    // MPLog(@"Conti Tracking\n");
    switch (dragState) {
            // stopped
        case kTSDragStopped:
            dragging = NO;
            break;
            // started
        case kTSDragStarted:
            dragState = kTSDragContinue;
            break;
            // continue
        default:
            dragging = YES;
            break;
    }
    
    return [super continueTracking:lastPoint at:currentPoint inView:controlView];
}

- (void)drawBarInside:(NSRect)aRect flipped:(BOOL)flipped {
    
    if([self sliderType] == NSLinearSlider) {
        
        if(![self isVertical]) {
            
            [self drawHorizontalBarInFrame: aRect];
            return;
        } else {
            // [self drawVerticalBarInFrame: aRect];
        }
    } else {
        //Placeholder for when I figure out how to draw NSCircularSlider
    }
    [super drawBarInside:aRect flipped:flipped];
}

- (void)drawKnob:(NSRect)aRect {
    
    if([self sliderType] == NSLinearSlider) {
        
        if(![self isVertical]) {
            
            [self drawHorizontalKnobInFrame: aRect];
            return;
        } else {
            // [self drawVerticalKnobInFrame: aRect];
        }
    } else {
        //Place holder for when I figure out how to draw NSCircularSlider
    }
    [super drawKnob:aRect];
}

- (void)drawHorizontalBarInFrame:(NSRect)frame {
    
    // Adjust frame based on ControlSize
    switch ([self controlSize]) {
            
        case NSSmallControlSize:
            
            if([self numberOfTickMarks] != 0) {
                
                if([self tickMarkPosition] == NSTickMarkBelow) {
                    
                    frame.origin.y += 2;
                } else {
                    
                    frame.origin.y += frame.size.height - 8;
                }
            } else {
                
                frame.origin.y = frame.origin.y + (((frame.origin.y + frame.size.height) /2) - 2.5f);
            }
            
            frame.origin.x += 0.5f;
            frame.origin.y -= 2.0f;
            frame.size.width -= 1.0f;
            frame.size.height = 3.0f;
            break;
        default:
            [super drawHorizontalBarInFrame:frame];
            return;
    }
    
    //Draw Bar
    NSBezierPath *path = [[NSBezierPath alloc] init];
    
    [path appendBezierPathWithRoundedRect:frame xRadius:1 yRadius:1];
    
    if([self isEnabled]) {
        [[NSColor colorWithDeviceWhite:1.00 alpha:0.20] set];
        [path fill];
    } else {
        [[NSColor colorWithDeviceWhite:0.04 alpha:0.20] set];
        [path fill];
    }
}

- (void)drawHorizontalKnobInFrame:(NSRect)frame {
    
    NSRect rcBounds = [[self controlView] bounds];
    NSBezierPath *path, *line;
    
    switch ([self controlSize]) {
            
        case NSSmallControlSize:
            rcBounds.origin.y = rcBounds.origin.y + (((rcBounds.origin.y + rcBounds.size.height) /2) - 2.5f);
            rcBounds.origin.x += 0.5f;
            rcBounds.origin.y -= 0.0f;
            rcBounds.size.width -= 0.5f;
            rcBounds.size.height = 3.0f;
            
            rcBounds.size.width *= ([self floatValue]/[self maxValue]);
            
            path = [[NSBezierPath alloc] init];
            [path appendBezierPathWithRoundedRect:rcBounds xRadius:1 yRadius:1];
            
            line  = [[NSBezierPath alloc] init];
            CGFloat left = rcBounds.size.width - 3;
            if(left < 0){
                left = 0;
            }
            [line appendBezierPathWithRect:NSMakeRect(left, rcBounds.origin.y - 4, 3, 14)];
            
            if([self isEnabled]) {
                [[NSColor colorWithDeviceWhite:0.6 alpha:1.0] set];
                [path fill];
            } else {
                [[NSColor colorWithDeviceWhite:0.3 alpha:1.0] set];
                [path fill];
            }
            
//            [[NSColor colorWithDeviceWhite:0.0 alpha:0.3] set];
//            [path stroke];
            
            [[NSColor whiteColor] set];
            [line fill];
            
            break;
        default:
            [super drawHorizontalKnobInFrame:frame];
            break;
    }
}
@end