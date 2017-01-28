//
//  NHDisplayLink.m
//  CocoaUtils
//
//  Created by Nick Hutchinson on 01/05/2013.
//
//

#import "NHDisplayLink.h"

#if OS_OBJECT_USE_OBJC_RETAIN_RELEASE
static void
NHDispatchRelease(__strong dispatch_object_t *var) {
    *var = nil;
}

#else

static void
NHDispatchRelease(dispatch_object_t *var) {
    dispatch_release(*var);
    *var = NULL;
}
#endif

typedef enum : unsigned {
    // We don't want to naively schedule the callback from the displaylink
    // thread, because this will likely happen faster than the main thread
    // can process it. Instead, we try to only schedule the callback if the
    // callback isn't already executing.
    kNHDisplayLinkIsRendering = 1u << 0
} NHDisplayLinkAtomicFlags;


@interface NHDisplayLink () {
    CVDisplayLinkRef _displayLink;
    CVTimeStamp _timeStamp;
    
    NHDisplayLinkAtomicFlags _atomicFlags;
    bool _isRunning;
    
    /// Serial dispatch queue that has client's queue as its target
    dispatch_queue_t _internalDispatchQueue;
    
    /// Queue that serialises calls to -start and -stop.
    dispatch_queue_t _stateChangeQueue;
}

@end

@implementation NHDisplayLink

/// Client's dispatch queue. Unretained.
@synthesize dispatchQueue = _clientDispatchQueue;

- (id)init {
    if ((self = [super init])) {
        CVReturn status =
        CVDisplayLinkCreateWithActiveCGDisplays(&_displayLink);
        assert(status == kCVReturnSuccess);
        
        _stateChangeQueue = dispatch_queue_create("NHDisplayLink.stateChange",
                                                  NULL);
        _clientDispatchQueue = dispatch_get_main_queue();
        _internalDispatchQueue = dispatch_queue_create("NHDisplayLink", NULL);
        dispatch_set_target_queue(_internalDispatchQueue, _clientDispatchQueue);
        
        CVDisplayLinkSetOutputCallback(_displayLink, NHDisplayLinkCallback,
                                       (__bridge void*)self);
    }
    
    return self;
}

- (void)dealloc {
    CVDisplayLinkRelease(_displayLink);
    NHDispatchRelease(&_internalDispatchQueue);
    NHDispatchRelease(&_stateChangeQueue);
}

- (void)setDispatchQueue:(dispatch_queue_t)dispatchQueue {
    dispatch_set_target_queue(_internalDispatchQueue, dispatchQueue);
    _clientDispatchQueue = dispatchQueue;
}

- (void)start {
    dispatch_async(_stateChangeQueue, ^{
        if (_isRunning)
            return;
        
        _isRunning = true;
        
        // We CFRetain self while the displaylink thread is active, to ensure it
        // always has a valid 'self' pointer. The CFRetain is undone by [1].
        CFRetain((__bridge CFTypeRef)self);
        
        CVDisplayLinkStart(_displayLink);
    });
}

- (void)stop {
    dispatch_async(_stateChangeQueue, ^{
        if (!_isRunning)
            return;
        
        _isRunning = false;
        // The displaylink thread resumes the queue at [2]
        dispatch_suspend(_stateChangeQueue);
    });
}

static CVReturn
NHDisplayLinkCallback(CVDisplayLinkRef displayLink,
                      const CVTimeStamp *inNow,
                      const CVTimeStamp *inOutputTime,
                      CVOptionFlags flagsIn,
                      CVOptionFlags *flagsOut,
                      void *ctx) {
    NHDisplayLink *self = (__bridge NHDisplayLink*)ctx;
    
    if (!self->_isRunning) {
        CVDisplayLinkStop(displayLink);
        dispatch_resume(self->_stateChangeQueue); // See [2]
        CFRelease(ctx); // See [1]
        
    } else if (!__sync_fetch_and_or(&self->_atomicFlags,
                                    kNHDisplayLinkIsRendering)) {
        self->_timeStamp = *inOutputTime;
        dispatch_async_f(self->_internalDispatchQueue,
                         (void*)CFBridgingRetain(self),
                         NHDisplayLinkRender);
    }
    
    return kCVReturnSuccess;
}

static void
NHDisplayLinkRender(void *ctx) {
    NHDisplayLink *self = CFBridgingRelease(ctx);
    if (self->_isRunning) {
        [self->_delegate displayLink:self
              didRequestFrameForTime:&self->_timeStamp];
    }
    __sync_fetch_and_and(&self->_atomicFlags, ~kNHDisplayLinkIsRendering);
}

@end
