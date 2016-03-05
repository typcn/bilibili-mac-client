//
//  TimeSliderCell.h
//  bilibili
//
//  Created by TYPCN on 2016/3/5.
//  Copyright © 2016 TYPCN. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BGHUDSliderCell.h"

typedef enum
{
    kTSDragStopped  = 0,
    kTSDragStarted  = 1,
    kTSDragContinue = 2
} TSDRAG_STATE;

@interface TimeSliderCell : BGHUDSliderCell
{
    BOOL dragging;
    TSDRAG_STATE dragState;
}

@property (readonly, getter=isDragging) BOOL dragging;

@end