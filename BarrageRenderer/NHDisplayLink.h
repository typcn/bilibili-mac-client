//
//  NHDisplayLink.h
//  CocoaUtils
//
//  Created by Nick Hutchinson on 01/05/2013.
//
//

#import <Cocoa/Cocoa.h>

@protocol NHDisplayLinkDelegate;

@interface NHDisplayLink : NSObject

@property (nonatomic, weak) id <NHDisplayLinkDelegate> delegate;

/// The queue on which delegate callbacks will be delivered; defaults to the
/// main queue
@property (nonatomic) dispatch_queue_t dispatchQueue;

- (void)start;
- (void)stop;

@end


@protocol NHDisplayLinkDelegate <NSObject>
- (void)displayLink:(NHDisplayLink *)displayLink didRequestFrameForTime:(const CVTimeStamp *)outputTimeStamp;
@end