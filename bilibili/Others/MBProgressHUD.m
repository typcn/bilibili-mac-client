//
// MBProgressHUD.m
// Version 0.8 + dismissible + OSX 10.7+ option added by Wayne Fox 21 Apr 2014
// Created by Matej Bukovinski on 2.4.09.
//

#import "MBProgressHUD.h"
#import <tgmath.h>


#if __has_feature(objc_arc)
#define MB_AUTORELEASE(exp) exp
#define MB_RELEASE(exp) exp
#define MB_RETAIN(exp) exp
#else
#define MB_AUTORELEASE(exp) [exp autorelease]
#define MB_RELEASE(exp) [exp release]
#define MB_RETAIN(exp) [exp retain]
#endif

#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)

#if __IPHONE_OS_VERSION_MIN_REQUIRED >= 60000
#define MBLabelAlignmentCenter NSTextAlignmentCenter
#else
#define MBLabelAlignmentCenter UITextAlignmentCenter
#endif

#if __IPHONE_OS_VERSION_MIN_REQUIRED >= 70000
#define MB_TEXTSIZE(text, font) [text length] > 0 ? [text \
sizeWithAttributes:@{NSFontAttributeName:font}] : CGSizeZero;
#else
#define MB_TEXTSIZE(text, font) [text length] > 0 ? [text sizeWithFont:font] : CGSizeZero;
#endif

#if __IPHONE_OS_VERSION_MIN_REQUIRED >= 70000
#define MB_MULTILINE_TEXTSIZE(text, font, maxSize, mode) [text length] > 0 ? [text \
boundingRectWithSize:maxSize options:(NSStringDrawingUsesLineFragmentOrigin) \
attributes:@{NSFontAttributeName:font} context:nil].size : CGSizeZero;
#else
#define MB_MULTILINE_TEXTSIZE(text, font, maxSize, mode) [text length] > 0 ? [text \
sizeWithFont:font constrainedToSize:maxSize lineBreakMode:mode] : CGSizeZero;
#endif

#else   // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)

#define MBLabelAlignmentCenter NSCenterTextAlignment
#define MB_TEXTSIZE(text, font) [text length] > 0 ? [text \
sizeWithAttributes:@{NSFontAttributeName:font}] : CGSizeZero;
#define MB_MULTILINE_TEXTSIZE(text, font, maxSize, mode) [text length] > 0 ? [text \
boundingRectWithSize:maxSize options:(NSStringDrawingUsesLineFragmentOrigin) \
attributes:@{NSFontAttributeName:font} context:nil].size : CGSizeZero;

#endif  // (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)


static const CGFloat kPadding = 4.0f;
static const CGFloat kLabelFontSize = 16.0f;
static const CGFloat kDetailsLabelFontSize = 12.0f;


@interface MBProgressHUD ()

- (void)setupLabels;
- (void)registerForKVO;
- (void)unregisterFromKVO;
- (NSArray *)observableKeypaths;
- (void)registerForNotifications;
- (void)unregisterFromNotifications;
- (void)updateUIForKeypath:(NSString *)keyPath;
- (void)hideUsingAnimation:(BOOL)animated;
- (void)showUsingAnimation:(BOOL)animated;
- (void)done;
#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
- (void)singleTap:(UITapGestureRecognizer*)sender;
#else   // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
- (void)mouseDown:(NSEvent *)theEvent;
#endif  // (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
- (void)updateIndicators;
- (void)handleGraceTimer:(NSTimer *)theTimer;
- (void)handleMinShowTimer:(NSTimer *)theTimer;
- (void)setTransformForCurrentOrientation:(BOOL)animated;
- (void)cleanUp;
- (void)launchExecution;
- (void)deviceOrientationDidChange:(NSNotification *)notification;
- (void)hideDelayed:(NSNumber *)animated;

#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
@property (atomic, MB_STRONG) UIView *indicator;
#else   // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
@property (atomic, MB_STRONG) NSView *indicator;    // YRKSpinningProgressIndicator
#endif  // (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
@property (atomic, MB_STRONG) NSTimer *graceTimer;
@property (atomic, MB_STRONG) NSTimer *minShowTimer;
@property (atomic, MB_STRONG) NSDate *showStarted;
@property (atomic, assign) CGSize size;

@end


@implementation MBProgressHUD {
    BOOL useAnimation;
    SEL methodForExecution;
    id targetForExecution;
    id objectForExecution;
#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
    UILabel *label;
    UILabel *detailsLabel;
#else   // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
    NSText *label;
    NSText *detailsLabel;
#endif  // (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
    BOOL isFinished;
    CGAffineTransform rotationTransform;
}

#pragma mark - Properties

@synthesize animationType;
@synthesize delegate;
@synthesize opacity;
@synthesize color;
@synthesize labelFont;
@synthesize labelColor;
@synthesize detailsLabelFont;
@synthesize detailsLabelColor;
@synthesize indicator;
@synthesize xOffset;
@synthesize yOffset;
@synthesize minSize;
@synthesize square;
@synthesize spinsize;
@synthesize margin;
@synthesize dimBackground;
@synthesize dismissible;
@synthesize graceTime;
@synthesize minShowTime;
@synthesize graceTimer;
@synthesize minShowTimer;
@synthesize taskInProgress;
@synthesize removeFromSuperViewOnHide;
@synthesize customView;
@synthesize showStarted;
@synthesize mode;
@synthesize labelText;
@synthesize detailsLabelText;
@synthesize progress;
@synthesize size;
#if NS_BLOCKS_AVAILABLE
@synthesize completionBlock;
#endif

#pragma mark - Class methods

#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
+ (MB_INSTANCETYPE)showHUDAddedTo:(UIView *)view animated:(BOOL)animated
#else   // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
+ (MB_INSTANCETYPE)showHUDAddedTo:(NSView *)view animated:(BOOL)animated
#endif  // (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
{
    NSAssert(view, @"View must not be nil.");
    MBProgressHUD *hud = [[self alloc] initWithView:view];
    [view addSubview:hud];
    [hud show:animated];
    return MB_AUTORELEASE(hud);
}

#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
+ (BOOL)hideHUDForView:(UIView *)view animated:(BOOL)animated
#else   // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
+ (BOOL)hideHUDForView:(NSView *)view animated:(BOOL)animated
#endif  // (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
{
    NSAssert(view, @"View must not be nil.");
    MBProgressHUD *hud = [self HUDForView:view];
    if (hud != nil) {
        hud.removeFromSuperViewOnHide = YES;
        [hud hide:animated];
        return YES;
    }
    return NO;
}

#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
+ (NSUInteger)hideAllHUDsForView:(UIView *)view animated:(BOOL)animated
#else   // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
+ (NSUInteger)hideAllHUDsForView:(NSView *)view animated:(BOOL)animated
#endif  // (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
{
    NSAssert(view, @"View must not be nil.");
    NSArray *huds = [MBProgressHUD allHUDsForView:view];
    for (MBProgressHUD *hud in huds) {
        hud.removeFromSuperViewOnHide = YES;
        [hud hide:animated];
    }
    return [huds count];
}

#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
+ (MB_INSTANCETYPE)HUDForView:(UIView *)view
#else   // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
+ (MB_INSTANCETYPE)HUDForView:(NSView *)view
#endif  // (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
{
    NSAssert(view, @"View must not be nil.");
    NSEnumerator *subviewsEnum = [view.subviews reverseObjectEnumerator];
#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
    for (UIView *subview in subviewsEnum)
#else   // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
        for (NSView *subview in subviewsEnum)
#endif  // (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
        {
            if ([subview isKindOfClass:self]) {
                return (MBProgressHUD *)subview;
            }
        }
    return nil;
}

#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
+ (NSArray *)allHUDsForView:(UIView *)view
#else   // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
+ (NSArray *)allHUDsForView:(NSView *)view
#endif  // (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
{
    NSAssert(view, @"View must not be nil.");
    NSMutableArray *huds = [NSMutableArray array];
    NSArray *subviews = view.subviews;
#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
    for (UIView *aView in subviews)
#else   // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
        for (NSView *aView in subviews)
#endif  // (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
        {
            if ([aView isKindOfClass:self]) {
                [huds addObject:aView];
            }
        }
    return [NSArray arrayWithArray:huds];
}

#if !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
- (CGColorRef)NSColorToCGColor:(NSColor *)nscolor
{
    NSInteger numberOfComponents = [nscolor numberOfComponents];
    CGFloat components[numberOfComponents];
    CGColorSpaceRef colorSpace = [[nscolor colorSpace] CGColorSpace];
    [nscolor getComponents:(CGFloat *)&components];
    if (_cgColorFromNSColor) {
        CGColorRelease(_cgColorFromNSColor);
        _cgColorFromNSColor = nil;
    }
    _cgColorFromNSColor = CGColorCreate(colorSpace, components);
    return _cgColorFromNSColor;
}
#endif  // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)

#pragma mark - Lifecycle

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Set default values for properties
        self.animationType = MBProgressHUDAnimationFade;
        self.mode = MBProgressHUDModeIndeterminate;
        self.labelText = nil;
        self.detailsLabelText = nil;
        self.opacity = 0.8f;
        self.color = nil;
#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
        self.labelFont = [UIFont boldSystemFontOfSize:kLabelFontSize];
        self.labelColor = [NSColor whiteColor];
        self.detailsLabelFont = [UIFont boldSystemFontOfSize:kDetailsLabelFontSize];
        self.detailsLabelColor = [NSColor whiteColor];
#else   // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
        self.labelFont = [NSFont boldSystemFontOfSize:kLabelFontSize];
        self.labelColor = [NSColor whiteColor];
        self.detailsLabelFont = [NSFont boldSystemFontOfSize:kDetailsLabelFontSize];
        self.detailsLabelColor = [NSColor whiteColor];
#endif  // (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
        self.xOffset = 0.0f;
        self.yOffset = 0.0f;
        self.dimBackground = NO;
        self.dismissible = NO;
#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
        self.spinsize = 37.0f;
#else   // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
        self.spinsize = 60.0f;      // Applicable to Mac OS X ONLY
#endif  // (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
        self.margin = 20.0f;
        self.cornerRadius = 10.0f;
        self.graceTime = 0.0f;
        self.minShowTime = 0.0f;
        self.removeFromSuperViewOnHide = NO;
        self.minSize = CGSizeZero;
        self.square = NO;
#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
        self.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin
        | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
#else   // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
        /*
         typedef NS_OPTIONS(NSUInteger, UIViewAutoresizing) {
         UIViewAutoresizingNone                 = 0,         // 0
         UIViewAutoresizingFlexibleLeftMargin   = 1 << 0,    // 1
         UIViewAutoresizingFlexibleWidth        = 1 << 1,    // 2
         UIViewAutoresizingFlexibleRightMargin  = 1 << 2,    // 4
         UIViewAutoresizingFlexibleTopMargin    = 1 << 3,    // 8
         UIViewAutoresizingFlexibleHeight       = 1 << 4,    // 16
         UIViewAutoresizingFlexibleBottomMargin = 1 << 5     // 32
         };
         enum {
         NSViewNotSizable			=  0,
         NSViewMinXMargin			=  1,
         NSViewWidthSizable			=  2,
         NSViewMaxXMargin			=  4,
         NSViewMinYMargin			=  8,
         NSViewHeightSizable			= 16,
         NSViewMaxYMargin			= 32
         };
         enum {
         NSViewAutoresizingNone                 = NSViewNotSizable,
         NSViewAutoresizingFlexibleLeftMargin   = NSViewMinXMargin,
         NSViewAutoresizingFlexibleWidth        = NSViewWidthSizable,
         NSViewAutoresizingFlexibleRightMargin  = NSViewMaxXMargin,
         NSViewAutoresizingFlexibleTopMargin    = NSViewMaxYMargin,
         NSViewAutoresizingFlexibleHeight       = NSViewHeightSizable,
         NSViewAutoresizingFlexibleBottomMargin = NSViewMinYMargin
         };
         */
        self.autoresizingMask = NSViewAutoresizingFlexibleTopMargin | NSViewAutoresizingFlexibleBottomMargin
        | NSViewAutoresizingFlexibleLeftMargin | NSViewAutoresizingFlexibleRightMargin;
#endif  // (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
        
        // Transparent background
#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
        self.opaque = NO;
        self.backgroundColor = [NSColor clearColor];
        // Make it invisible for now
        self.alpha = 0.0f;
#else   // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
        self.layer.opaque = NO;
        self.layer.backgroundColor = [self NSColorToCGColor:[NSColor clearColor]];
        CGColorRelease(_cgColorFromNSColor), _cgColorFromNSColor = nil;
        // Make it invisible for now
        self.alphaValue = 0.0f;
#endif  // (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
        
        taskInProgress = NO;
        rotationTransform = CGAffineTransformIdentity;
        
        [self setupLabels];
        // [self updateIndicators];
        [self registerForKVO];
        [self registerForNotifications];
    }
    return self;
}

#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
- (id)initWithView:(UIView *)view
#else   // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
- (id)initWithView:(NSView *)view
#endif  // (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
{
    NSAssert(view, @"View must not be nil.");
    CGRect bounds = view.frame;
    bounds.origin.x = 0.0f;
    bounds.origin.y = 0.0f;
    return [self initWithFrame:bounds];
}

#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
- (id)initWithWindow:(UIWindow *)window
{
    return [self initWithView:(UIView *)window];
}
#else   // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
- (id)initWithWindow:(NSWindow *)window
{
    return [self initWithView:(NSView *)window];
}
#endif  // (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)

- (void)dealloc
{
    [self unregisterFromNotifications];
    [self unregisterFromKVO];
#if !__has_feature(objc_arc)
    [color release];
    [indicator release];
    [label release];
    [detailsLabel release];
    [labelText release];
    [detailsLabelText release];
    [graceTimer release];
    [minShowTimer release];
    [showStarted release];
    [customView release];
    [labelFont release];
    [labelColor release];
    [detailsLabelFont release];
    [detailsLabelColor release];
#if !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
    if (_cgColorFromNSColor) CGColorRelease(_cgColorFromNSColor);
#endif
#if NS_BLOCKS_AVAILABLE
    [completionBlock release];
#endif
    
    [super dealloc];
#endif  // !__has_feature(objc_arc)
}

#pragma mark - Show & hide

- (void)show:(BOOL)animated
{
    [self updateIndicators];    // allow self.spinsize to be effective
    
    useAnimation = animated;
    // If the grace time is set postpone the HUD display
    if (self.graceTime > 0.0) {
        self.graceTimer = [NSTimer scheduledTimerWithTimeInterval:self.graceTime target:self
                                                         selector:@selector(handleGraceTimer:) userInfo:nil repeats:NO];
    }
    // ... otherwise show the HUD imediately
    else {
#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
        [self setNeedsDisplay];
#else   // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
        [self setNeedsDisplay:YES];
#endif  // (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
        [self showUsingAnimation:useAnimation];
    }
}

- (void)hide:(BOOL)animated
{
    useAnimation = animated;
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    // If the minShow time is set, calculate how long the hud was shown,
    // and pospone the hiding operation if necessary
    if (self.minShowTime > 0.0 && showStarted) {
        NSTimeInterval interv = [[NSDate date] timeIntervalSinceDate:showStarted];
        if (interv < self.minShowTime) {
            self.minShowTimer = [NSTimer scheduledTimerWithTimeInterval:(self.minShowTime - interv) target:self
                                                               selector:@selector(handleMinShowTimer:) userInfo:nil repeats:NO];
            return;
        }
    }
    // ... otherwise hide the HUD immediately
    [self hideUsingAnimation:useAnimation];
}

- (void)hide:(BOOL)animated afterDelay:(NSTimeInterval)delay
{
    [self performSelector:@selector(hideDelayed:) withObject:[NSNumber numberWithBool:animated] afterDelay:delay];
}

- (void)hideDelayed:(NSNumber *)animated
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    if (self.delegate) {
        if ([self.delegate respondsToSelector:@selector(hudWasHiddenAfterDelay:)]) {
            [self.delegate performSelector:@selector(hudWasHiddenAfterDelay:) withObject:self];
        }
    }
    
    [self hide:[animated boolValue]];
}

- (BOOL)isFinished
{
    return isFinished;
}

#pragma mark - Timer callbacks

- (void)handleGraceTimer:(NSTimer *)theTimer
{
    // Show the HUD only if the task is still running
    if (taskInProgress) {
#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
        [self setNeedsDisplay];
#else   // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
        [self setNeedsDisplay:YES];
#endif  // (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
        [self showUsingAnimation:useAnimation];
    }
}

- (void)handleMinShowTimer:(NSTimer *)theTimer
{
    [self hideUsingAnimation:useAnimation];
}

#pragma mark - View Hierrarchy

- (void)didMoveToSuperview
{
    // We need to take care of rotation ourselfs if we're adding the HUD to a window
#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
    if ([self.superview isKindOfClass:[UIWindow class]])
#else   // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
        if ([self.superview isKindOfClass:[NSWindow class]])
#endif  // (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
        {
            [self setTransformForCurrentOrientation:NO];
        }
}

#pragma mark - Internal show & hide operations

- (void)showUsingAnimation:(BOOL)animated
{
#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
    if (animated && animationType == MBProgressHUDAnimationZoomIn) {
        self.transform = CGAffineTransformConcat(rotationTransform, CGAffineTransformMakeScale(0.5f, 0.5f));
    } else if (animated && animationType == MBProgressHUDAnimationZoomOut) {
        self.transform = CGAffineTransformConcat(rotationTransform, CGAffineTransformMakeScale(1.5f, 1.5f));
    }
#else   // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
    if (animated && animationType == MBProgressHUDAnimationZoomIn) {
        self.layer.affineTransform = CGAffineTransformConcat(rotationTransform, CGAffineTransformMakeScale(0.5f, 0.5f));
    } else if (animated && animationType == MBProgressHUDAnimationZoomOut) {
        self.layer.affineTransform = CGAffineTransformConcat(rotationTransform, CGAffineTransformMakeScale(1.5f, 1.5f));
    }
#endif  // (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
    self.showStarted = [NSDate date];
    
    // Fade in
#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
    if (animated) {
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:0.30];
        self.alpha = 1.0f;
        if (animationType == MBProgressHUDAnimationZoomIn || animationType == MBProgressHUDAnimationZoomOut) {
            self.transform = rotationTransform;
        }
        [UIView commitAnimations];
    }
    else {
        self.alpha = 1.0f;
    }
#else   // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
    self.hidden = NO;
    if (animated) {
        [NSAnimationContext beginGrouping];
        [[NSAnimationContext currentContext] setDuration:0.30];
        [[self animator] setAlphaValue:1.0f];
        if (animationType == MBProgressHUDAnimationZoomIn || animationType == MBProgressHUDAnimationZoomOut) {
            [(CALayer *)[self animator] setAffineTransform:rotationTransform];
        }
        [NSAnimationContext endGrouping];
    }
    else {
        self.alphaValue = 1.0f;
    }
#endif  // (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
}

- (void)hideUsingAnimation:(BOOL)animated
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    // Fade out
#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
    if (animated && showStarted) {
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:0.30];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDidStopSelector:@selector(animationFinished:finished:context:)];
        // 0.02 prevents the hud from passing through touches during the animation the hud will get completely hidden
        // in the done method
        if (animationType == MBProgressHUDAnimationZoomIn) {
            self.transform = CGAffineTransformConcat(rotationTransform, CGAffineTransformMakeScale(1.5f, 1.5f));
        } else if (animationType == MBProgressHUDAnimationZoomOut) {
            self.transform = CGAffineTransformConcat(rotationTransform, CGAffineTransformMakeScale(0.5f, 0.5f));
        }
        
        self.alpha = 0.02f;
        [UIView commitAnimations];
    }
    else {
        self.alpha = 0.0f;
        [self done];
    }
#else   // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
    if (animated && showStarted) {
        [NSAnimationContext beginGrouping];
        [[NSAnimationContext currentContext] setDuration:0.30];
        [[NSAnimationContext currentContext] setCompletionHandler:^{
            [self done];
        }];
        [(NSView *)[self animator] setAlphaValue:0.2f];
        if (animationType == MBProgressHUDAnimationZoomIn) {
            [(CALayer *)[self animator] setAffineTransform:CGAffineTransformConcat(rotationTransform, CGAffineTransformMakeScale(1.5f, 1.5f))];
        } else if (animationType == MBProgressHUDAnimationZoomOut) {
            [(CALayer *)[self animator] setAffineTransform:CGAffineTransformConcat(rotationTransform, CGAffineTransformMakeScale(0.5f, 0.5f))];
        }
        [NSAnimationContext endGrouping];
    }
    else {
        self.alphaValue = 0.0f;
        [self done];
    }
#endif  // (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
    self.showStarted = nil;
}

- (void)animationFinished:(NSString *)animationID finished:(BOOL)finished context:(void*)context
{
    [self done];
}

- (void)done
{
    isFinished = YES;
#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
    self.alpha = 0.0f;
#else   // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
    self.alphaValue = 0.0f;
    // self.acceptsTouchEvents = NO;
    self.hidden = YES;
#endif  // (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
    if (self.removeFromSuperViewOnHide) {
        [self removeFromSuperview];
    }
#if NS_BLOCKS_AVAILABLE
    if (self.completionBlock) {
        self.completionBlock();
        self.completionBlock = NULL;
    }
#endif
    
    if ([self.delegate class]) {
        if ([self.delegate respondsToSelector:@selector(hudWasHidden:)]) {
            [self.delegate performSelector:@selector(hudWasHidden:) withObject:self];
        }
    }
}

#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
- (void)singleTap:(UITapGestureRecognizer*)sender
#else   // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
- (void)mouseDown:(NSEvent *)theEvent
#endif  // (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
{
#if !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
    if (isFinished) {
        [super mouseDown:theEvent];
        return;
    }
#endif  // (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
    if (self.dismissible) {
        [self performSelectorOnMainThread:@selector(cleanUp) withObject:nil waitUntilDone:YES];
        if (self.delegate) {
            if ([self.delegate respondsToSelector:@selector(hudWasTapped:)]) {
                [self.delegate performSelector:@selector(hudWasTapped:) withObject:self];
            }
        }
    }
}

#pragma mark - Threading

- (void)showWhileExecuting:(SEL)method onTarget:(id)target withObject:(id)object animated:(BOOL)animated
{
    methodForExecution = method;
    targetForExecution = MB_RETAIN(target);
    objectForExecution = MB_RETAIN(object);
    // Launch execution in new thread
    self.taskInProgress = YES;
    [NSThread detachNewThreadSelector:@selector(launchExecution) toTarget:self withObject:nil];
    // Show HUD view
    [self show:animated];
}

#if NS_BLOCKS_AVAILABLE

- (void)showAnimated:(BOOL)animated whileExecutingBlock:(dispatch_block_t)block
{
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    [self showAnimated:animated whileExecutingBlock:block onQueue:queue completionBlock:NULL];
}

- (void)showAnimated:(BOOL)animated whileExecutingBlock:(dispatch_block_t)block completionBlock:(void (^)())completion
{
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    [self showAnimated:animated whileExecutingBlock:block onQueue:queue completionBlock:completion];
}

- (void)showAnimated:(BOOL)animated whileExecutingBlock:(dispatch_block_t)block onQueue:(dispatch_queue_t)queue
{
    [self showAnimated:animated whileExecutingBlock:block onQueue:queue	completionBlock:NULL];
}

- (void)showAnimated:(BOOL)animated whileExecutingBlock:(dispatch_block_t)block onQueue:(dispatch_queue_t)queue
     completionBlock:(MBProgressHUDCompletionBlock)completion
{
    self.taskInProgress = YES;
    self.completionBlock = completion;
    dispatch_async(queue, ^(void) {
        block();
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            [self cleanUp];
        });
    });
    [self show:animated];
}

#endif

- (void)launchExecution
{
    @autoreleasepool {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        // Start executing the requested task
        [targetForExecution performSelector:methodForExecution withObject:objectForExecution];
#pragma clang diagnostic pop
        // Task completed, update view in main thread (note: view operations should
        // be done only in the main thread)
        [self performSelectorOnMainThread:@selector(cleanUp) withObject:nil waitUntilDone:NO];
    }
}

- (void)cleanUp
{
    taskInProgress = NO;
#if !__has_feature(objc_arc)
    [targetForExecution release];
    [objectForExecution release];
#endif
    targetForExecution = nil;
    objectForExecution = nil;
    
    [self hide:useAnimation];
}

#pragma mark - UI

- (void)setupLabels
{
#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
    UITapGestureRecognizer *singleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTap:)];
    label = [[UILabel alloc] initWithFrame:self.bounds];
    label.adjustsFontSizeToFitWidth = NO;
    label.textAlignment = MBLabelAlignmentCenter;
    label.opaque = NO;
    label.backgroundColor = [NSColor clearColor];
    label.textColor = self.labelColor;
    label.font = self.labelFont;
    label.text = self.labelText;
    [label addGestureRecognizer:singleTapGesture];
#else   // (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
    label = [[NSText alloc] initWithFrame:self.bounds];
    // label.adjustsFontSizeToFitWidth = NO;
    label.editable = NO;
    // label.bezeled = NO;  // if NSTextView
    label.alignment = MBLabelAlignmentCenter;
    label.layer.opaque = NO;
    label.backgroundColor = [NSColor clearColor];
    label.textColor = self.labelColor;
    label.font = self.labelFont;
    if (self.labelText) label.string = self.labelText;
#endif  // (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
    [self addSubview:label];
    
#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
    detailsLabel = [[UILabel alloc] initWithFrame:self.bounds];
    detailsLabel.font = self.detailsLabelFont;
    detailsLabel.adjustsFontSizeToFitWidth = NO;
    detailsLabel.textAlignment = MBLabelAlignmentCenter;
    detailsLabel.opaque = NO;
    detailsLabel.backgroundColor = [NSColor clearColor];
    detailsLabel.textColor = self.detailsLabelColor;
    detailsLabel.numberOfLines = 0;
    detailsLabel.font = self.detailsLabelFont;
    detailsLabel.text = self.detailsLabelText;
    [detailsLabel addGestureRecognizer:singleTapGesture];
#else   // (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
    detailsLabel = [[NSText alloc] initWithFrame:self.bounds];
    detailsLabel.font = self.detailsLabelFont;
    // detailsLabel.adjustsFontSizeToFitWidth = NO;
    detailsLabel.editable = NO;
    // detailsLabel.bezeled = NO;  // if NSTextView
    detailsLabel.alignment = MBLabelAlignmentCenter;
    detailsLabel.layer.opaque = NO;
    detailsLabel.backgroundColor = [NSColor clearColor];
    detailsLabel.textColor = self.detailsLabelColor;
    // detailsLabel.numberOfLines = 0;
    detailsLabel.font = self.detailsLabelFont;
    if (self.detailsLabelText) detailsLabel.string = self.detailsLabelText;
#endif  // (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
    [self addSubview:detailsLabel];
    
#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
    [self addGestureRecognizer:singleTapGesture];
#endif  // (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
}

- (void)updateIndicators
{
#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
    BOOL isActivityIndicator = [indicator isKindOfClass:[UIActivityIndicatorView class]];
#else   // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
    BOOL isActivityIndicator = [indicator isKindOfClass:[YRKSpinningProgressIndicator class]];
#endif  // (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
    BOOL isRoundIndicator = [indicator isKindOfClass:[MBRoundProgressView class]];
    
    if (mode == MBProgressHUDModeIndeterminate &&  !isActivityIndicator) {
        // Update to indeterminate indicator
        [indicator removeFromSuperview];
#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
        self.indicator = MB_AUTORELEASE([[UIActivityIndicatorView alloc]
                                         initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge]);
        [(UIActivityIndicatorView *)indicator startAnimating];
#else   // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
        self.indicator = MB_AUTORELEASE([[YRKSpinningProgressIndicator alloc] initWithFrame:NSMakeRect(20, 20, self.spinsize, self.spinsize)]);
        // [(YRKSpinningProgressIndicator *)self.indicator setStyle:NSProgressIndicatorSpinningStyle];
        [(YRKSpinningProgressIndicator *)self.indicator setColor:[NSColor whiteColor]];
        [(YRKSpinningProgressIndicator *)self.indicator setUsesThreadedAnimation:NO];
        [(YRKSpinningProgressIndicator *)self.indicator startAnimation:self];
#endif  // (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
        [self addSubview:indicator];
    }
    else if (mode == MBProgressHUDModeDeterminateHorizontalBar) {
        // Update to bar determinate indicator
        [indicator removeFromSuperview];
        self.indicator = MB_AUTORELEASE([[MBBarProgressView alloc] init]);
        [self addSubview:indicator];
    }
    else if (mode == MBProgressHUDModeDeterminate || mode == MBProgressHUDModeAnnularDeterminate) {
        if (!isRoundIndicator) {
            // Update to determinante indicator
            [indicator removeFromSuperview];
            // self.indicator = [MB_AUTORELEASE([[MBRoundProgressView alloc] init]);
            self.indicator = MB_AUTORELEASE([[MBRoundProgressView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.spinsize, self.spinsize)]);
            [self addSubview:indicator];
        }
        if (mode == MBProgressHUDModeAnnularDeterminate) {
            [(MBRoundProgressView *)indicator setAnnular:YES];
        }
    }
    else if (mode == MBProgressHUDModeCustomView && customView != indicator) {
        // Update custom view indicator
        [indicator removeFromSuperview];
        self.indicator = customView;
        [self addSubview:indicator];
    } else if (mode == MBProgressHUDModeText) {
        [indicator removeFromSuperview];
        self.indicator = nil;
    }
}

#pragma mark - Layout

- (void)layoutSubviews
{
    
    // Entirely cover the parent view
#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
    UIView *parent = self.superview;
#else   // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
    NSView *parent = self.superview;
#endif  // (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
    if (parent) {
        self.frame = parent.bounds;
    }
    CGRect bounds = self.bounds;
    
    // Determine the total widt and height needed
    CGFloat maxWidth = bounds.size.width - 4 * margin;
    CGSize totalSize = CGSizeZero;
    
    CGRect indicatorF = indicator.bounds;
    indicatorF.size.width = MIN(indicatorF.size.width, maxWidth);
    totalSize.width = MAX(totalSize.width, indicatorF.size.width);
    totalSize.height += indicatorF.size.height;
    
#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
    CGSize labelSize = MB_TEXTSIZE(label.text, label.font);
#else   // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
    CGSize labelSize = MB_TEXTSIZE(label.string, label.font);
    if (labelSize.width > 0.0f) labelSize.width += 10.0f;
#endif  // (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
    labelSize.width = MIN(labelSize.width, maxWidth);
    totalSize.width = MAX(totalSize.width, labelSize.width);
    totalSize.height += labelSize.height;
    if (labelSize.height > 0.0f && indicatorF.size.height > 0.0f) {
        totalSize.height += kPadding;
    }
    
#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
    CGFloat remainingHeight = bounds.size.height - totalSize.height - kPadding - 4 * margin;
   	CGSize maxSize = CGSizeMake(maxWidth, remainingHeight);
    CGSize detailsLabelSize = MB_MULTILINE_TEXTSIZE(detailsLabel.text, detailsLabel.font, maxSize, detailsLabel.lineBreakMode);
#else   // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
    CGSize detailsLabelSize = MB_TEXTSIZE(detailsLabel.string, detailsLabel.font);
    if (detailsLabelSize.width > 0.0f) detailsLabelSize.width += 10.0f;
#endif  // (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
    detailsLabelSize.width = MIN(detailsLabelSize.width, maxWidth);
    totalSize.width = MAX(totalSize.width, detailsLabelSize.width);
    totalSize.height += detailsLabelSize.height;
    if (detailsLabelSize.height > 0.0f && (indicatorF.size.height > 0.0f || labelSize.height > 0.0f)) {
        totalSize.height += kPadding;
    }
    
    totalSize.width += 2 * margin;
    totalSize.height += 2 * margin;
    
    // Position elements
#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
   	CGFloat yPos = round(((bounds.size.height - totalSize.height) / 2)) + margin + yOffset;
#else
    // in OS X yAxis is inverted! So Top Down Must build from bottom up...
    CGFloat yPos = round(((bounds.size.height - totalSize.height) / 2)) + margin - yOffset;
    if (labelSize.height > 0.0f && indicatorF.size.height > 0.0f) {
        yPos += kPadding + labelSize.height;
    }
    if (detailsLabelSize.height > 0.0f && (indicatorF.size.height > 0.0f || labelSize.height > 0.0f)) {
        yPos += kPadding + detailsLabelSize.height;
    }
#endif
    CGFloat xPos = xOffset;
    indicatorF.origin.y = yPos;
    indicatorF.origin.x = round((bounds.size.width - indicatorF.size.width) / 2) + xPos;
    indicator.frame = indicatorF;
#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
    yPos += indicatorF.size.height;
    
    if (labelSize.height > 0.0f && indicatorF.size.height > 0.0f) {
        yPos += kPadding;
    }
#else
    // in OS X yAxis is inverted! So Top Down Must build from bottom up...
    if (labelSize.height > 0.0f && indicatorF.size.height > 0.0f) {
        yPos -= (kPadding + labelSize.height);
    }
#endif
    CGRect labelF;
    labelF.origin.y = yPos;
    labelF.origin.x = round((bounds.size.width - labelSize.width) / 2) + xPos;
    labelF.size = labelSize;
    label.frame = labelF;
#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
    yPos += labelF.size.height;
    
    if (detailsLabelSize.height > 0.0f && (indicatorF.size.height > 0.0f || labelSize.height > 0.0f)) {
        yPos += kPadding;
    }
#else
    // in OS X yAxis is inverted! So Top Down Must build from bottom up...
    if (detailsLabelSize.height > 0.0f && (indicatorF.size.height > 0.0f || labelSize.height > 0.0f)) {
        yPos -= (kPadding + detailsLabelSize.height);
    }
#endif
    CGRect detailsLabelF;
    detailsLabelF.origin.y = yPos;
    detailsLabelF.origin.x = round((bounds.size.width - detailsLabelSize.width) / 2) + xPos;
    detailsLabelF.size = detailsLabelSize;
    detailsLabel.frame = detailsLabelF;
    
    // Enforce minsize and quare rules
    if (square) {
        CGFloat max = MAX(totalSize.width, totalSize.height);
        if (max <= bounds.size.width - 2 * margin) {
            totalSize.width = max;
        }
        if (max <= bounds.size.height - 2 * margin) {
            totalSize.height = max;
        }
    }
    if (totalSize.width < minSize.width) {
        totalSize.width = minSize.width;
    }
    if (totalSize.height < minSize.height) {
        totalSize.height = minSize.height;
    }
    
    self.size = totalSize;
}

#pragma mark - BG Drawing

- (void)drawRect:(CGRect)rect
{
#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
    CGContextRef context = UIGraphicsGetCurrentContext();
#else   // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
    [self layoutSubviews];
    //CGContextRef context =  [[NSGraphicsContext currentContext] graphicsPort];
#endif  // (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
    
#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
    UIGraphicsPushContext(context);
    context = UIGraphicsGetCurrentContext();
#else   // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
    [NSGraphicsContext saveGraphicsState];
    CGContextRef context =  [[NSGraphicsContext currentContext] graphicsPort];
#endif  // (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
    
    if (self.dimBackground) {
        //Gradient colours
        size_t gradLocationsNum = 2;
        CGFloat gradLocations[2] = {0.0f, 1.0f};
        CGFloat gradColors[8] = {0.0f,0.0f,0.0f,0.0f,0.0f,0.0f,0.0f,0.75f};
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGGradientRef gradient = CGGradientCreateWithColorComponents(colorSpace, gradColors, gradLocations, gradLocationsNum);
        CGColorSpaceRelease(colorSpace);
        //Gradient center
        CGPoint gradCenter= CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
        //Gradient radius
        float gradRadius = MIN(self.bounds.size.width , self.bounds.size.height) ;
        //Gradient draw
        CGContextDrawRadialGradient (context, gradient, gradCenter,
                                     0, gradCenter, gradRadius,
                                     kCGGradientDrawsAfterEndLocation);
        CGGradientRelease(gradient);
    }
    
    // Set background rect color
    if (self.color) {
        if (context > 0) {
#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
            CGContextSetFillColorWithColor(context, self.color.CGColor);
#else   // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
            CGContextSetFillColorWithColor(context, [self NSColorToCGColor:self.color]);
            CGColorRelease(_cgColorFromNSColor), _cgColorFromNSColor = nil;
#endif  // (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
        }
    } else {
        if (context > 0) {
            CGContextSetGrayFillColor(context, 0.0f, self.opacity);
        }
    }
    
    
    // Center HUD
    CGRect allRect = self.bounds;
    
    // Draw rounded HUD backgroud rect
#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
    CGRect boxRect = CGRectMake(round((allRect.size.width - size.width) / 2) + self.xOffset,
                                round((allRect.size.height - size.height) / 2) + self.yOffset, size.width, size.height);
#else
    CGRect boxRect = CGRectMake(round((allRect.size.width - size.width) / 2) + self.xOffset,
                                round((allRect.size.height - size.height) / 2) - self.yOffset, size.width, size.height);
#endif
    
    float radius = self.cornerRadius;
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, CGRectGetMinX(boxRect) + radius, CGRectGetMinY(boxRect));
    CGContextAddArc(context, CGRectGetMaxX(boxRect) - radius, CGRectGetMinY(boxRect) + radius, radius, 3 * (float)M_PI / 2, 0, 0);
    CGContextAddArc(context, CGRectGetMaxX(boxRect) - radius, CGRectGetMaxY(boxRect) - radius, radius, 0, (float)M_PI / 2, 0);
    CGContextAddArc(context, CGRectGetMinX(boxRect) + radius, CGRectGetMaxY(boxRect) - radius, radius, (float)M_PI / 2, (float)M_PI, 0);
    CGContextAddArc(context, CGRectGetMinX(boxRect) + radius, CGRectGetMinY(boxRect) + radius, radius, (float)M_PI, 3 * (float)M_PI / 2, 0);
    CGContextClosePath(context);
    CGContextFillPath(context);
    
#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
    UIGraphicsPopContext();
#else   // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
    [NSGraphicsContext restoreGraphicsState];
#endif  // (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
}

#pragma mark - KVO

- (void)registerForKVO
{
    for (NSString *keyPath in [self observableKeypaths]) {
        [self addObserver:self forKeyPath:keyPath options:NSKeyValueObservingOptionNew context:NULL];
    }
}

- (void)unregisterFromKVO
{
    for (NSString *keyPath in [self observableKeypaths]) {
        [self removeObserver:self forKeyPath:keyPath];
    }
}

- (NSArray *)observableKeypaths
{
    return [NSArray arrayWithObjects:@"mode", @"customView", @"labelText", @"labelFont", @"labelColor",
            @"detailsLabelText", @"detailsLabelFont", @"detailsLabelColor", @"progress", nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(updateUIForKeypath:) withObject:keyPath waitUntilDone:NO];
    } else {
        [self updateUIForKeypath:keyPath];
    }
}

- (void)updateUIForKeypath:(NSString *)keyPath
{
    if ([keyPath isEqualToString:@"mode"] || [keyPath isEqualToString:@"customView"]) {
        [self updateIndicators];
    } else if ([keyPath isEqualToString:@"labelText"]) {
#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
        label.text = self.labelText;
#else   // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
        label.string = self.labelText;
#endif  // (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
    } else if ([keyPath isEqualToString:@"labelFont"]) {
        label.font = self.labelFont;
    } else if ([keyPath isEqualToString:@"labelColor"]) {
        label.textColor = self.labelColor;
    } else if ([keyPath isEqualToString:@"detailsLabelText"]) {
#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
        detailsLabel.text = self.detailsLabelText;
#else   // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
        detailsLabel.string = self.detailsLabelText;
#endif  // (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
    } else if ([keyPath isEqualToString:@"detailsLabelFont"]) {
        detailsLabel.font = self.detailsLabelFont;
    } else if ([keyPath isEqualToString:@"detailsLabelColor"]) {
        detailsLabel.textColor = self.detailsLabelColor;
    } else if ([keyPath isEqualToString:@"progress"]) {
        if ([indicator respondsToSelector:@selector(setProgress:)]) {
            [(id)indicator setValue:@(progress) forKey:@"progress"];
        }
        return;
    }
#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
    [self setNeedsLayout];
    [self setNeedsDisplay];
#else   // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
    [self setNeedsLayout:YES];
    [self setNeedsDisplay:YES];
#endif  // (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
}

#pragma mark - Notifications

- (void)registerForNotifications
{
#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(deviceOrientationDidChange:)
               name:UIDeviceOrientationDidChangeNotification object:nil];
#endif  // (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
}

- (void)unregisterFromNotifications
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)deviceOrientationDidChange:(NSNotification *)notification
{
#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
    UIView *superview = self.superview;
    if (!superview) {
        return;
    } else if ([superview isKindOfClass:[UIWindow class]]) {
        [self setTransformForCurrentOrientation:YES];
    } else {
        self.frame = self.superview.bounds;
        [self setNeedsDisplay];
    }
#endif  // (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
}

- (void)setTransformForCurrentOrientation:(BOOL)animated
{
#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
    // Stay in sync with the superview
    if (self.superview) {
        self.bounds = self.superview.bounds;
        [self setNeedsDisplay];
    }
    
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    CGFloat radians = 0;
    if (UIInterfaceOrientationIsLandscape(orientation)) {
        if (orientation == UIInterfaceOrientationLandscapeLeft) { radians = -(CGFloat)M_PI_2; }
        else { radians = (CGFloat)M_PI_2; }
        // Window coordinates differ!
        self.bounds = CGRectMake(0, 0, self.bounds.size.height, self.bounds.size.width);
    } else {
        if (orientation == UIInterfaceOrientationPortraitUpsideDown) { radians = (CGFloat)M_PI; }
        else { radians = 0; }
    }
    rotationTransform = CGAffineTransformMakeRotation(radians);
    
    if (animated) {
        [UIView beginAnimations:nil context:nil];
    }
    [self setTransform:rotationTransform];
    if (animated) {
        [UIView commitAnimations];
    }
#endif  // (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
}

@end


@implementation MBRoundProgressView

#pragma mark - Lifecycle

- (id)init
{
    return [self initWithFrame:CGRectMake(0.0f, 0.0f, 37.0f, 37.0f)];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
        self.backgroundColor = [NSColor clearColor];
        self.opaque = NO;
        _progress = 0.0f;
        _annular = NO;
        _progressTintColor = [[NSColor alloc] initWithWhite:1.0f alpha:1.0f];
        _backgroundTintColor = [[NSColor alloc] initWithWhite:1.0f alpha:0.1f];
#else   // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
        self.layer.backgroundColor = [self NSColorToCGColor:[NSColor clearColor]];
        CGColorRelease(_cgColorFromNSColor), _cgColorFromNSColor = nil;
        self.layer.opaque = NO;
        _progress = 0.0f;
        _annular = NO;
        _progressTintColor = [NSColor colorWithDeviceWhite:1.0f alpha:1.0f];
        _backgroundTintColor = [NSColor colorWithDeviceWhite:1.0f alpha:0.1f];
#endif  // (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
        [self registerForKVO];
    }
    return self;
}

- (void)dealloc
{
    [self unregisterFromKVO];
#if !__has_feature(objc_arc)
    [_progressTintColor release];
    [_backgroundTintColor release];
#if !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
    if (_cgColorFromNSColor) CGColorRelease(_cgColorFromNSColor);
#endif
    
    [super dealloc];
#endif
}

#if !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
- (CGColorRef)NSColorToCGColor:(NSColor *)nscolor
{
    NSInteger numberOfComponents = [nscolor numberOfComponents];
    CGFloat components[numberOfComponents];
    CGColorSpaceRef colorSpace = [[nscolor colorSpace] CGColorSpace];
    [nscolor getComponents:(CGFloat *)&components];
    if (_cgColorFromNSColor) {
        CGColorRelease(_cgColorFromNSColor);
        _cgColorFromNSColor = nil;
    }
    _cgColorFromNSColor = CGColorCreate(colorSpace, components);
    return _cgColorFromNSColor;
}
#endif  // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)

#pragma mark - Drawing

- (void)drawRect:(CGRect)rect
{
    
    CGRect allRect = self.bounds;
    CGRect circleRect = CGRectInset(allRect, 2.0f, 2.0f);
    
#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
    CGContextRef context = UIGraphicsGetCurrentContext();
#else   // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
    CGContextRef context =  [[NSGraphicsContext currentContext] graphicsPort];
#endif  // (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
    
    if (_annular) {
        // Draw background
        CGFloat lineWidth = 5.0f;
#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
        UIBezierPath *processBackgroundPath = [UIBezierPath bezierPath];
#else   // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
        NSBezierPath *processBackgroundPath = [NSBezierPath bezierPath];
#endif  // (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
        processBackgroundPath.lineWidth = lineWidth;
        processBackgroundPath.lineCapStyle = kCGLineCapRound;
        CGPoint center = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
        CGFloat radius = (self.bounds.size.width - lineWidth)/2;
#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
        CGFloat startAngle = - ((float)M_PI / 2); // 90 degrees
        CGFloat endAngle = (2 * (float)M_PI) + startAngle;
        [processBackgroundPath addArcWithCenter:center radius:radius startAngle:startAngle endAngle:endAngle clockwise:YES];
#else   // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
        CGFloat startAngle = ((float)M_PI / 2); // 90 degrees
        CGFloat endAngle = startAngle - (2 * (float)M_PI);
        [processBackgroundPath appendBezierPathWithArcWithCenter:center radius:radius startAngle:startAngle endAngle:endAngle clockwise:NO];
#endif  // (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
        [_backgroundTintColor set];
        [processBackgroundPath stroke];
        // Draw progress
#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
        UIBezierPath *processPath = [UIBezierPath bezierPath];
#else   // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
        NSBezierPath *processPath = [NSBezierPath bezierPath];
#endif  // (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
        processPath.lineCapStyle = kCGLineCapRound;
        processPath.lineWidth = lineWidth;
#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
        endAngle = (self.progress * 2 * (float)M_PI) + startAngle;
        [processPath addArcWithCenter:center radius:radius startAngle:startAngle endAngle:endAngle clockwise:YES];
#else   // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
        endAngle = startAngle - (self.progress * 2 * (float)M_PI);
        [processPath appendBezierPathWithArcWithCenter:center radius:radius startAngle:startAngle endAngle:endAngle clockwise:YES];
#endif  // (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
        [_progressTintColor set];
        [processPath stroke];
    } else {
        // Draw background
        [_progressTintColor setStroke];
        [_backgroundTintColor setFill];
        CGContextSetLineWidth(context, 2.0f);
        CGContextFillEllipseInRect(context, circleRect);
        CGContextStrokeEllipseInRect(context, circleRect);
        // Draw progress
        CGPoint center = CGPointMake(allRect.size.width / 2, allRect.size.height / 2);
        CGFloat radius = (allRect.size.width - 4) / 2;
#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
        CGFloat startAngle = - ((float)M_PI / 2); // 90 degrees
        CGFloat endAngle = (self.progress * 2 * (float)M_PI) + startAngle;
#else
        CGFloat startAngle = ((float)M_PI / 2); // 90 degrees
        CGFloat endAngle = startAngle - (self.progress * 2 * (float)M_PI);
#endif
        CGContextSetRGBFillColor(context, 1.0f, 1.0f, 1.0f, 1.0f); // white
        CGContextMoveToPoint(context, center.x, center.y);
#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
        CGContextAddArc(context, center.x, center.y, radius, startAngle, endAngle, 0);
#else
        CGContextAddArc(context, center.x, center.y, radius, startAngle, endAngle, 1);
#endif
        CGContextClosePath(context);
        CGContextFillPath(context);
    }
}

#pragma mark - KVO

- (void)registerForKVO
{
    for (NSString *keyPath in [self observableKeypaths]) {
        [self addObserver:self forKeyPath:keyPath options:NSKeyValueObservingOptionNew context:NULL];
    }
}

- (void)unregisterFromKVO
{
    for (NSString *keyPath in [self observableKeypaths]) {
        [self removeObserver:self forKeyPath:keyPath];
    }
}

- (NSArray *)observableKeypaths
{
    return [NSArray arrayWithObjects:@"progressTintColor", @"backgroundTintColor", @"progress", @"annular", nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
    [self setNeedsDisplay];
#else   // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
    [self setNeedsDisplay:YES];
#endif  // (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
}

@end


@implementation MBBarProgressView

#pragma mark - Lifecycle

- (id)init
{
    return [self initWithFrame:CGRectMake(0.0f, 0.0f, 120.0f, 20.0f)];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _progress = 0.0f;
#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
        _lineColor = [NSColor whiteColor];
        _progressColor = [NSColor whiteColor];
        _progressRemainingColor = [NSColor clearColor];
        self.backgroundColor = [NSColor clearColor];
        self.opaque = NO;
#else   // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
        _lineColor = [NSColor whiteColor];
        _progressColor = [NSColor whiteColor];
        _progressRemainingColor = [NSColor clearColor];
        self.layer.backgroundColor = [self NSColorToCGColor:[NSColor clearColor]];
        CGColorRelease(_cgColorFromNSColor), _cgColorFromNSColor = nil;
        self.layer.opaque = NO;
#endif  // (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
        [self registerForKVO];
    }
    return self;
}

- (void)dealloc
{
    [self unregisterFromKVO];
#if !__has_feature(objc_arc)
    [_lineColor release];
    [_progressColor release];
    [_progressRemainingColor release];
#if !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
    if (_cgColorFromNSColor) CGColorRelease(_cgColorFromNSColor);
#endif
    
    [super dealloc];
#endif
}

#if !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
- (CGColorRef)NSColorToCGColor:(NSColor *)nscolor
{
    NSInteger numberOfComponents = [nscolor numberOfComponents];
    CGFloat components[numberOfComponents];
    CGColorSpaceRef colorSpace = [[nscolor colorSpace] CGColorSpace];
    [nscolor getComponents:(CGFloat *)&components];
    if (_cgColorFromNSColor) {
        CGColorRelease(_cgColorFromNSColor);
        _cgColorFromNSColor = nil;
    }
    _cgColorFromNSColor = CGColorCreate(colorSpace, components);
    return _cgColorFromNSColor;
}
#endif  // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)

#pragma mark - Drawing

- (void)drawRect:(CGRect)rect
{
#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // setup properties
    CGContextSetLineWidth(context, 2);
    CGContextSetStrokeColorWithColor(context,[_lineColor CGColor]);
    CGContextSetFillColorWithColor(context, [_progressRemainingColor CGColor]);
#else   // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
    CGContextRef context =  [[NSGraphicsContext currentContext] graphicsPort];
    
    // setup properties
    CGContextSetLineWidth(context, 2);
    CGContextSetStrokeColorWithColor(context,[self NSColorToCGColor:_lineColor]);
    CGColorRelease(_cgColorFromNSColor), _cgColorFromNSColor = nil;
    CGContextSetFillColorWithColor(context, [self NSColorToCGColor:_progressRemainingColor]);
    CGColorRelease(_cgColorFromNSColor), _cgColorFromNSColor = nil;
#endif  // (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
    
    // draw line border
    float radius = (rect.size.height / 2) - 2;
    CGContextMoveToPoint(context, 2, rect.size.height/2);
    CGContextAddArcToPoint(context, 2, 2, radius + 2, 2, radius);
    CGContextAddLineToPoint(context, rect.size.width - radius - 2, 2);
    CGContextAddArcToPoint(context, rect.size.width - 2, 2, rect.size.width - 2, rect.size.height / 2, radius);
    CGContextAddArcToPoint(context, rect.size.width - 2, rect.size.height - 2, rect.size.width - radius - 2, rect.size.height - 2, radius);
    CGContextAddLineToPoint(context, radius + 2, rect.size.height - 2);
    CGContextAddArcToPoint(context, 2, rect.size.height - 2, 2, rect.size.height/2, radius);
    CGContextFillPath(context);
    
    // draw progress background
    CGContextMoveToPoint(context, 2, rect.size.height/2);
    CGContextAddArcToPoint(context, 2, 2, radius + 2, 2, radius);
    CGContextAddLineToPoint(context, rect.size.width - radius - 2, 2);
    CGContextAddArcToPoint(context, rect.size.width - 2, 2, rect.size.width - 2, rect.size.height / 2, radius);
    CGContextAddArcToPoint(context, rect.size.width - 2, rect.size.height - 2, rect.size.width - radius - 2, rect.size.height - 2, radius);
    CGContextAddLineToPoint(context, radius + 2, rect.size.height - 2);
    CGContextAddArcToPoint(context, 2, rect.size.height - 2, 2, rect.size.height/2, radius);
    CGContextStrokePath(context);
    
    // setup to draw progress color
#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
    CGContextSetFillColorWithColor(context, [_progressColor CGColor]);
#else   // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
    CGContextSetFillColorWithColor(context, [self NSColorToCGColor:_progressColor]);
    CGColorRelease(_cgColorFromNSColor), _cgColorFromNSColor = nil;
#endif  // (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
    radius = radius - 2;
    float amount = self.progress * rect.size.width;
    
    // if progress is in the middle area
    if (amount >= radius + 4 && amount <= (rect.size.width - radius - 4)) {
        // top
        CGContextMoveToPoint(context, 4, rect.size.height/2);
        CGContextAddArcToPoint(context, 4, 4, radius + 4, 4, radius);
        CGContextAddLineToPoint(context, amount, 4);
        CGContextAddLineToPoint(context, amount, radius + 4);
        
        // bottom
        CGContextMoveToPoint(context, 4, rect.size.height/2);
        CGContextAddArcToPoint(context, 4, rect.size.height - 4, radius + 4, rect.size.height - 4, radius);
        CGContextAddLineToPoint(context, amount, rect.size.height - 4);
        CGContextAddLineToPoint(context, amount, radius + 4);
        
        CGContextFillPath(context);
    }
    
    // progress is in the right arc
    else if (amount > radius + 4) {
        float x = amount - (rect.size.width - radius - 4);
        
        // top
        CGContextMoveToPoint(context, 4, rect.size.height/2);
        CGContextAddArcToPoint(context, 4, 4, radius + 4, 4, radius);
        CGContextAddLineToPoint(context, rect.size.width - radius - 4, 4);
        float angle = -acos(x/radius);
        if (isnan(angle)) angle = 0;
        CGContextAddArc(context, rect.size.width - radius - 4, rect.size.height/2, radius, M_PI, angle, 0);
        CGContextAddLineToPoint(context, amount, rect.size.height/2);
        
        // bottom
        CGContextMoveToPoint(context, 4, rect.size.height/2);
        CGContextAddArcToPoint(context, 4, rect.size.height - 4, radius + 4, rect.size.height - 4, radius);
        CGContextAddLineToPoint(context, rect.size.width - radius - 4, rect.size.height - 4);
        angle = acos(x/radius);
        if (isnan(angle)) angle = 0;
        CGContextAddArc(context, rect.size.width - radius - 4, rect.size.height/2, radius, -M_PI, angle, 1);
        CGContextAddLineToPoint(context, amount, rect.size.height/2);
        
        CGContextFillPath(context);
    }
    
    // progress is in the left arc
    else if (amount < radius + 4 && amount > 0) {
        // top
        CGContextMoveToPoint(context, 4, rect.size.height/2);
        CGContextAddArcToPoint(context, 4, 4, radius + 4, 4, radius);
        CGContextAddLineToPoint(context, radius + 4, rect.size.height/2);
        
        // bottom
        CGContextMoveToPoint(context, 4, rect.size.height/2);
        CGContextAddArcToPoint(context, 4, rect.size.height - 4, radius + 4, rect.size.height - 4, radius);
        CGContextAddLineToPoint(context, radius + 4, rect.size.height/2);
        
        CGContextFillPath(context);
    }
}

#pragma mark - KVO

- (void)registerForKVO
{
    for (NSString *keyPath in [self observableKeypaths]) {
        [self addObserver:self forKeyPath:keyPath options:NSKeyValueObservingOptionNew context:NULL];
    }
}

- (void)unregisterFromKVO
{
    for (NSString *keyPath in [self observableKeypaths]) {
        [self removeObserver:self forKeyPath:keyPath];
    }
}

- (NSArray *)observableKeypaths
{
    return [NSArray arrayWithObjects:@"lineColor", @"progressRemainingColor", @"progressColor", @"progress", nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
    [self setNeedsDisplay];
#else   // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
    [self setNeedsDisplay:YES];
#endif  // (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
}

@end

#if !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)

@implementation MBSpinnerProgressView

// Create subclass of NSProgressIndicator inside method do like this

#pragma mark - Drawing

- (void)drawRect:(NSRect)dirtyRect
{
    // Drawing code here.
    [self setControlTint:NSGraphiteControlTint];
    CGContextSetBlendMode((CGContextRef)[[NSGraphicsContext currentContext] graphicsPort], kCGBlendModeSoftLight);
    [[[NSColor whiteColor] colorWithAlphaComponent:1] set];
    [NSBezierPath fillRect:dirtyRect];
    [super drawRect:dirtyRect];
}

@end

//
//  YRKSpinningProgressIndicator.m
//
//  Copyright 2009 Kelan Champagne. All rights reserved.
//
//  Modified for ObjC-ARC compatibility by Wayne Fox 2014

// Some constants to control the animation
#define kAlphaWhenStopped   0.15
#define kFadeMultiplier     0.85


@interface YRKSpinningProgressIndicator ()

- (void)updateFrame:(NSTimer *)timer;
- (void)animateInBackgroundThread;
- (void)actuallyStartAnimation;
- (void)actuallyStopAnimation;
- (void)generateFinColorsStartAtPosition:(int)startPosition;

@end


@implementation YRKSpinningProgressIndicator

@synthesize color = _foreColor;
@synthesize backgroundColor = _backColor;
@synthesize drawsBackground = _drawsBackground;
@synthesize displayedWhenStopped = _displayedWhenStopped;
@synthesize usesThreadedAnimation = _usesThreadedAnimation;
@synthesize indeterminate = _isIndeterminate;
@synthesize doubleValue = _currentValue;
@synthesize maxValue = _maxValue;


#pragma mark Init

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _position = 0;
        _numFins = 12;
#if __has_feature(objc_arc)
        _finColors = [NSMutableArray arrayWithCapacity:_numFins];
        for (int i=0; i < _numFins; i++) {
            [_finColors addObject:[NSColor whiteColor]];
        }
#else
        _finColors = calloc(_numFins, sizeof(NSColor*));
#endif
        
        _isAnimating = NO;
        _isFadingOut = NO;
        
        _foreColor = MB_RETAIN([NSColor blackColor]);
        _backColor = MB_RETAIN([NSColor clearColor]);
        _drawsBackground = NO;
        
        _displayedWhenStopped = YES;
        _usesThreadedAnimation = YES;
        
        _isIndeterminate = YES;
        _currentValue = 0.0;
        _maxValue = 100.0;
    }
    return self;
}

- (void) dealloc
{
#if !__has_feature(objc_arc)
    for (int i=0; i<_numFins; i++) {
        [_finColors[i] release];
    }
    free(_finColors);
    [_foreColor release];
    [_backColor release];
#endif
    if (_isAnimating) [self stopAnimation:self];
#if !__has_feature(objc_arc)
    [super dealloc];
#endif
}

# pragma mark NSView overrides

- (void)viewDidMoveToWindow
{
    [super viewDidMoveToWindow];
    
    if ([self window] == nil) {
        // No window?  View hierarchy may be going away.  Dispose timer to clear circular retain of timer to self to timer.
        [self actuallyStopAnimation];
    }
    else if (_isAnimating) {
        [self actuallyStartAnimation];
    }
}

- (void)drawRect:(NSRect)rect
{
    // Determine size based on current bounds
    NSSize size = [self bounds].size;
    CGFloat theMaxSize;
    if(size.width >= size.height)
        theMaxSize = size.height;
    else
        theMaxSize = size.width;
    
    // fill the background, if set
    if(_drawsBackground) {
        [_backColor set];
        [NSBezierPath fillRect:[self bounds]];
    }
    
    CGContextRef currentContext = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
    [NSGraphicsContext saveGraphicsState];
    
    // Move the CTM so 0,0 is at the center of our bounds
    CGContextTranslateCTM(currentContext,[self bounds].size.width/2,[self bounds].size.height/2);
    
    if (_isIndeterminate) {
        NSBezierPath *path = [[NSBezierPath alloc] init];
        CGFloat lineWidth = 0.0859375 * theMaxSize; // should be 2.75 for 32x32
        CGFloat lineStart = 0.234375 * theMaxSize; // should be 7.5 for 32x32
        CGFloat lineEnd = 0.421875 * theMaxSize;  // should be 13.5 for 32x32
        [path setLineWidth:lineWidth];
        [path setLineCapStyle:NSRoundLineCapStyle];
        [path moveToPoint:NSMakePoint(0,lineStart)];
        [path lineToPoint:NSMakePoint(0,lineEnd)];
        
        for (int i=0; i<_numFins; i++) {
            if(_isAnimating) {
#if __has_feature(objc_arc)
                [(NSColor *)[_finColors objectAtIndex:i] set];  // Sets the fill and stroke colors in the current drawing context.
#else
                [_finColors[i] set];
#endif
            }
            else {
                [[_foreColor colorWithAlphaComponent:kAlphaWhenStopped] set];
            }
            
            [path stroke];
            
            // we draw all the fins by rotating the CTM, then just redraw the same segment again
            CGContextRotateCTM(currentContext, 6.282185/_numFins);
        }
#if !__has_feature(objc_arc)
        [path release];
#endif
    }
    else {
        CGFloat lineWidth = 1 + (0.01 * theMaxSize);
        CGFloat circleRadius = (theMaxSize - lineWidth) / 2.1;
        NSPoint circleCenter = NSMakePoint(0, 0);
        [_foreColor set];
        NSBezierPath *path = [[NSBezierPath alloc] init];
        [path setLineWidth:lineWidth];
        [path appendBezierPathWithOvalInRect:NSMakeRect(-circleRadius, -circleRadius, circleRadius*2, circleRadius*2)];
        [path stroke];
#if !__has_feature(objc_arc)
        [path release];
#endif
        path = [[NSBezierPath alloc] init];
        [path appendBezierPathWithArcWithCenter:circleCenter radius:circleRadius startAngle:90 endAngle:90-(360*(_currentValue/_maxValue)) clockwise:YES];
        [path lineToPoint:circleCenter] ;
        [path fill];
#if !__has_feature(objc_arc)
        [path release];
#endif
    }
    
    [NSGraphicsContext restoreGraphicsState];
}


#pragma mark NSProgressIndicator API

- (void)startAnimation:(id)sender
{
    if (!_isIndeterminate) return;
    if (_isAnimating && !_isFadingOut) return;
    
    [self actuallyStartAnimation];
}

- (void)stopAnimation:(id)sender
{
    // animate to stopped state
    _isFadingOut = YES;
}

/// Only the spinning style is implemented
- (void)setStyle:(NSProgressIndicatorStyle)style
{
    if (NSProgressIndicatorSpinningStyle != style) {
        NSAssert(NO, @"Non-spinning styles not available.");
    }
}


# pragma mark Custom Accessors

- (void)setColor:(NSColor *)value
{
    if (_foreColor != value) {
#if !__has_feature(objc_arc)
        [_foreColor release];
#endif
        _foreColor = MB_RETAIN(value);
        
        // generate all the fin colors, with the alpha components
        // they already have
        for (int i=0; i<_numFins; i++) {
#if __has_feature(objc_arc)
            CGFloat alpha = [[_finColors objectAtIndex:i] alphaComponent];
#else
            CGFloat alpha = [_finColors[i] alphaComponent];
#endif
#if __has_feature(objc_arc)
            [_finColors replaceObjectAtIndex:i withObject:[_foreColor colorWithAlphaComponent:alpha]];
#else
            [_finColors[i] release];
            _finColors[i] = MB_RETAIN([_foreColor colorWithAlphaComponent:alpha]);
#endif
        }
        
        [self setNeedsDisplay:YES];
    }
}

- (void)setBackgroundColor:(NSColor *)value
{
    if (_backColor != value) {
#if !__has_feature(objc_arc)
        [_backColor release];
#endif
        _backColor = MB_RETAIN(value);
        [self setNeedsDisplay:YES];
    }
}

- (void)setDrawsBackground:(BOOL)value
{
    if (_drawsBackground != value) {
        _drawsBackground = value;
    }
    [self setNeedsDisplay:YES];
}

- (void)setIndeterminate:(BOOL)isIndeterminate
{
    _isIndeterminate = isIndeterminate;
    if (!_isIndeterminate && _isAnimating) [self stopAnimation:self];
    [self setNeedsDisplay:YES];
}

- (void)setDoubleValue:(double)doubleValue
{
    // Automatically put it into determinate mode if it's not already.
    if (_isIndeterminate) {
        [self setIndeterminate:NO];
    }
    _currentValue = doubleValue;
    [self setNeedsDisplay:YES];
}

- (void)setMaxValue:(double)maxValue
{
    _maxValue = maxValue;
    [self setNeedsDisplay:YES];
}

- (void)setUsesThreadedAnimation:(BOOL)useThreaded
{
    if (_usesThreadedAnimation != useThreaded) {
        _usesThreadedAnimation = useThreaded;
        
        if (_isAnimating) {
            // restart the timer to use the new mode
            [self stopAnimation:self];
            [self startAnimation:self];
        }
    }
}

- (void)setDisplayedWhenStopped:(BOOL)displayedWhenStopped
{
    _displayedWhenStopped = displayedWhenStopped;
    
    // Show/hide ourself if necessary
    if (!_isAnimating) {
        if (_displayedWhenStopped && [self isHidden]) {
            [self setHidden:NO];
        }
        else if (!_displayedWhenStopped && ![self isHidden]) {
            [self setHidden:YES];
        }
    }
}


#pragma mark Private

- (void)updateFrame:(NSTimer *)timer
{
    if(_position > 0) {
        _position--;
    }
    else {
        _position = _numFins - 1;
    }
    
    // update the colors
    CGFloat minAlpha = _displayedWhenStopped ? kAlphaWhenStopped : 0.01;
    for (int i=0; i<_numFins; i++) {
        // want each fin to fade exponentially over _numFins frames of animation
#if __has_feature(objc_arc)
        CGFloat newAlpha = [[_finColors objectAtIndex:i] alphaComponent] * kFadeMultiplier;
#else
        CGFloat newAlpha = [_finColors[i] alphaComponent] * kFadeMultiplier;
#endif
        if (newAlpha < minAlpha)
            newAlpha = minAlpha;
#if !__has_feature(objc_arc)
        NSColor *oldColor = _finColors[i];
#endif
#if __has_feature(objc_arc)
        [_finColors replaceObjectAtIndex:i withObject:[_foreColor colorWithAlphaComponent:newAlpha]];
#else
        _finColors[i] = MB_RETAIN([_foreColor colorWithAlphaComponent:newAlpha]);
        [oldColor release];
#endif
    }
    
    if (_isFadingOut) {
        // check if the fadeout is done
        BOOL done = YES;
        for (int i=0; i<_numFins; i++) {
#if __has_feature(objc_arc)
            if (fabs([[_finColors objectAtIndex:i] alphaComponent] - minAlpha) > 0.01) {
                done = NO;
                break;
            }
#else
            if (fabs([_finColors[i] alphaComponent] - minAlpha) > 0.01) {
                done = NO;
                break;
            }
#endif
        }
        if (done) {
            [self actuallyStopAnimation];
        }
    }
    else {
        // "light up" the next fin (with full alpha)
#if !__has_feature(objc_arc)
        NSColor *oldColor = _finColors[_position];
#endif
#if __has_feature(objc_arc)
        [_finColors replaceObjectAtIndex:_position withObject:_foreColor];
#else
        _finColors[_position] = MB_RETAIN(_foreColor);
        [oldColor release];
#endif
    }
    
    if (_usesThreadedAnimation) {
        // draw now instead of waiting for setNeedsDisplay (that's the whole reason
        // we're animating from background thread)
        [self display];
    }
    else {
        [self setNeedsDisplay:YES];
    }
}

- (void)actuallyStartAnimation
{
    // Just to be safe kill any existing timer.
    [self actuallyStopAnimation];
    
    _isAnimating = YES;
    _isFadingOut = NO;
    
    // always start from the top
    _position = 1;
    
    if (!_displayedWhenStopped)
        [self setHidden:NO];
    
    if ([self window]) {
        // Why animate if not visible?  viewDidMoveToWindow will re-call this method when needed.
        if (_usesThreadedAnimation) {
            _animationThread = [[NSThread alloc] initWithTarget:self selector:@selector(animateInBackgroundThread) object:nil];
            [_animationThread start];
        }
        else {
            _animationTimer = MB_RETAIN([NSTimer timerWithTimeInterval:(NSTimeInterval)0.05
                                                                target:self
                                                              selector:@selector(updateFrame:)
                                                              userInfo:nil
                                                               repeats:YES]);
            
            [[NSRunLoop currentRunLoop] addTimer:_animationTimer forMode:NSRunLoopCommonModes];
            [[NSRunLoop currentRunLoop] addTimer:_animationTimer forMode:NSDefaultRunLoopMode];
            [[NSRunLoop currentRunLoop] addTimer:_animationTimer forMode:NSEventTrackingRunLoopMode];
        }
    }
}

- (void)actuallyStopAnimation
{
    _isAnimating = NO;
    _isFadingOut = NO;
    
    if (!_displayedWhenStopped)
        [self setHidden:YES];
    
    if (_animationThread) {
        // we were using threaded animation
        [_animationThread cancel];
        if (![_animationThread isFinished]) {
            [[NSRunLoop currentRunLoop] runMode:NSModalPanelRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
        }
#if !__has_feature(objc_arc)
        [_animationThread release];
#endif
        _animationThread = nil;
    }
    else if (_animationTimer) {
        // we were using timer-based animation
        [_animationTimer invalidate];
#if !__has_feature(objc_arc)
        [_animationTimer release];
#endif
        _animationTimer = nil;
    }
    [self setNeedsDisplay:YES];
}

- (void)generateFinColorsStartAtPosition:(int)startPosition
{
    for (int i=0; i<_numFins; i++) {
#if __has_feature(objc_arc)
        NSColor *oldColor = [_finColors objectAtIndex:i];
#else
        NSColor *oldColor = _finColors[i];
#endif
        CGFloat alpha = [oldColor alphaComponent];
#if __has_feature(objc_arc)
        [_finColors replaceObjectAtIndex:i withObject:[_foreColor colorWithAlphaComponent:alpha]];
#else
        _finColors[i] = MB_RETAIN([_foreColor colorWithAlphaComponent:alpha]);
        [oldColor release];
#endif
    }
}

- (void)animateInBackgroundThread
{
#if __has_feature(objc_arc)
    @autoreleasepool {
#else
        NSAutoreleasePool *animationPool = [[NSAutoreleasePool alloc] init];
#endif
        // Set up the animation speed to subtly change with size > 32.
        // int animationDelay = 38000 + (2000 * ([self bounds].size.height / 32));
        
        // Set the rev per minute here
        int omega = 100; // RPM
        int animationDelay = 60*1000000/omega/_numFins;
        int poolFlushCounter = 0;
        
        do {
            [self updateFrame:nil];
            usleep(animationDelay);
            poolFlushCounter++;
            if (poolFlushCounter > 256) {
#if !__has_feature(objc_arc)
                [animationPool drain];
                animationPool = [[NSAutoreleasePool alloc] init];
#endif
                poolFlushCounter = 0;
            }
        } while (![[NSThread currentThread] isCancelled]); 
#if __has_feature(objc_arc)
    }
#else
    [animationPool release];
#endif
}

@end

#endif  // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)