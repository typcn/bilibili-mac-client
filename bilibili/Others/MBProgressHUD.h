//
//  MBProgressHUD.h
//  Version 0.8 + dismissible + OSX 10.7+ option added by Wayne Fox 21 Apr 2014
//  Created by Matej Bukovinski on 2.4.09.
//

// This code is distributed under the terms and conditions of the MIT license.

// Copyright (c) 2013 Matej Bukovinski
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import <Foundation/Foundation.h>
#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
#import <CoreGraphics/CoreGraphics.h>
#if __IPHONE
#import <UIKit/UIKit.h>
#endif  // __IPHONE
#else   // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
#import <Cocoa/Cocoa.h>
#endif  // (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)

@protocol MBProgressHUDDelegate;

/*
 NSProgressIndicator* indicator = [[[NSProgressIndicator alloc] initWithFrame:NSMakeRect(20, 20, 30, 30)] autorelease];
 [indicator setStyle:NSProgressIndicatorSpinningStyle];
 
 https://developer.apple.com/library/mac/documentation/cocoa/conceptual/ProgIndic/Concepts/AboutProgIndic.html
 
 */

typedef enum {
    /** Progress is shown using an UIActivityIndicatorView. This is the default. */
    MBProgressHUDModeIndeterminate,
    /** Progress is shown using a round, pie-chart like, progress view. */
    MBProgressHUDModeDeterminate,
    /** Progress is shown using a horizontal progress bar */
    MBProgressHUDModeDeterminateHorizontalBar,
    /** Progress is shown using a ring-shaped progress view. */
    MBProgressHUDModeAnnularDeterminate,
    /** Shows a custom view */
    MBProgressHUDModeCustomView,
    /** Shows only labels */
    MBProgressHUDModeText
} MBProgressHUDMode;

typedef enum {
    /** Opacity animation */
    MBProgressHUDAnimationFade,
    /** Opacity + scale animation */
    MBProgressHUDAnimationZoom,
    MBProgressHUDAnimationZoomOut = MBProgressHUDAnimationZoom,
    MBProgressHUDAnimationZoomIn
} MBProgressHUDAnimation;


#ifndef MB_INSTANCETYPE
#if __has_feature(objc_instancetype)
#define MB_INSTANCETYPE instancetype
#else
#define MB_INSTANCETYPE id
#endif
#endif

#ifndef MB_STRONG
#if __has_feature(objc_arc)
#define MB_STRONG strong
#else
#define MB_STRONG retain
#endif
#endif

#ifndef MB_WEAK
#if __has_feature(objc_arc_weak)
#define MB_WEAK weak
#elif __has_feature(objc_arc)
#define MB_WEAK unsafe_unretained
#else
#define MB_WEAK assign
#endif
#endif

#if NS_BLOCKS_AVAILABLE
typedef void (^MBProgressHUDCompletionBlock)(void);
#endif

#if !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)

enum {
    NSViewAutoresizingNone                 = NSViewNotSizable,
    NSViewAutoresizingFlexibleLeftMargin   = NSViewMinXMargin,
    NSViewAutoresizingFlexibleWidth        = NSViewWidthSizable,
    NSViewAutoresizingFlexibleRightMargin  = NSViewMaxXMargin,
    NSViewAutoresizingFlexibleTopMargin    = NSViewMaxYMargin,
    NSViewAutoresizingFlexibleHeight       = NSViewHeightSizable,
    NSViewAutoresizingFlexibleBottomMargin = NSViewMinYMargin
};

#endif

/**
 * Displays a simple HUD window containing a progress indicator and two optional labels for short messages.
 *
 * This is a simple drop-in class for displaying a progress HUD view similar to Apple's private UIProgressHUD class.
 * The MBProgressHUD window spans over the entire space given to it by the initWithFrame constructor and catches all
 * user input on this region, thereby preventing the user operations on components below the view. The HUD itself is
 * drawn centered as a rounded semi-transparent view which resizes depending on the user specified content.
 *
 * This view supports four modes of operation:
 * - MBProgressHUDModeIndeterminate - shows a UIActivityIndicatorView
 * - MBProgressHUDModeDeterminate - shows a custom round progress indicator
 * - MBProgressHUDModeAnnularDeterminate - shows a custom annular progress indicator
 * - MBProgressHUDModeCustomView - shows an arbitrary, user specified view (@see customView)
 *
 * All three modes can have optional labels assigned:
 * - If the labelText property is set and non-empty then a label containing the provided content is placed below the
 *   indicator view.
 * - If also the detailsLabelText property is set then another label is placed below the first label.
 */
#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
@interface MBProgressHUD : UIView
#else   // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
@interface MBProgressHUD : NSView
{
    CGColorRef _cgColorFromNSColor;
}
#endif  // (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)

#pragma mark - Class methods

/**
 * Creates a new HUD, adds it to provided view and shows it. The counterpart to this method is hideHUDForView:animated:.
 *
 * @param view The view that the HUD will be added to
 * @param animated If set to YES the HUD will appear using the current animationType. If set to NO the HUD will not use
 * animations while appearing.
 * @return A reference to the created HUD.
 *
 * @see hideHUDForView:animated:
 * @see animationType
 */
#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
+ (MB_INSTANCETYPE)showHUDAddedTo:(UIView *)view animated:(BOOL)animated;
#else   // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
+ (MB_INSTANCETYPE)showHUDAddedTo:(NSView *)view animated:(BOOL)animated;
#endif  // (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)

/**
 * Finds the top-most HUD subview and hides it. The counterpart to this method is showHUDAddedTo:animated:.
 *
 * @param view The view that is going to be searched for a HUD subview.
 * @param animated If set to YES the HUD will disappear using the current animationType. If set to NO the HUD will not use
 * animations while disappearing.
 * @return YES if a HUD was found and removed, NO otherwise.
 *
 * @see showHUDAddedTo:animated:
 * @see animationType
 */
#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
+ (BOOL)hideHUDForView:(UIView *)view animated:(BOOL)animated;
#else   // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
+ (BOOL)hideHUDForView:(NSView *)view animated:(BOOL)animated;
#endif  // (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)

/**
 * Finds all the HUD subviews and hides them.
 *
 * @param view The view that is going to be searched for HUD subviews.
 * @param animated If set to YES the HUDs will disappear using the current animationType. If set to NO the HUDs will not use
 * animations while disappearing.
 * @return the number of HUDs found and removed.
 *
 * @see hideHUDForView:animated:
 * @see animationType
 */
#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
+ (NSUInteger)hideAllHUDsForView:(UIView *)view animated:(BOOL)animated;
#else   // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
+ (NSUInteger)hideAllHUDsForView:(NSView *)view animated:(BOOL)animated;
#endif  // (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)

/**
 * Finds the top-most HUD subview and returns it.
 *
 * @param view The view that is going to be searched.
 * @return A reference to the last HUD subview discovered.
 */
#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
+ (MB_INSTANCETYPE)HUDForView:(UIView *)view;
#else   // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
+ (MB_INSTANCETYPE)HUDForView:(NSView *)view;
#endif  // (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)

/**
 * Finds all HUD subviews and returns them.
 *
 * @param view The view that is going to be searched.
 * @return All found HUD views (array of MBProgressHUD objects).
 */
#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
+ (NSArray *)allHUDsForView:(UIView *)view;
#else   // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
+ (NSArray *)allHUDsForView:(NSView *)view;
#endif  // (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)

/**
 * OS X Helper method to convert NSColor value to CGColorRef value.
 *
 * @nscolor NSColur instance to convert.
 * @return Converted NSColor to CGColorRef.
 */
#if !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
- (CGColorRef)NSColorToCGColor:(NSColor *)nscolor;
#endif  // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)

#pragma mark - Lifecycle

/**
 * A convenience constructor that initializes the HUD with the window's bounds. Calls the designated constructor with
 * window.bounds as the parameter.
 *
 * @param window The window instance that will provide the bounds for the HUD. Should be the same instance as
 * the HUD's superview (i.e., the window that the HUD will be added to).
 */
#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
- (id)initWithWindow:(UIWindow *)window;
#else   // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
- (id)initWithWindow:(NSWindow *)window;
#endif  // (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)

/**
 * A convenience constructor that initializes the HUD with the view's bounds. Calls the designated constructor with
 * view.bounds as the parameter
 *
 * @param view The view instance that will provide the bounds for the HUD. Should be the same instance as
 * the HUD's superview (i.e., the view that the HUD will be added to).
 */
#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
- (id)initWithView:(UIView *)view;
#else   // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
- (id)initWithView:(NSView *)view;
#endif  // (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)

#pragma mark - Show & hide

/**
 * Display the HUD. You need to make sure that the main thread completes its run loop soon after this method call so
 * the user interface can be updated. Call this method when your task is already set-up to be executed in a new thread
 * (e.g., when using something like NSOperation or calling an asynchronous call like NSURLRequest).
 *
 * @param animated If set to YES the HUD will appear using the current animationType. If set to NO the HUD will not use
 * animations while appearing.
 *
 * @see animationType
 */
- (void)show:(BOOL)animated;

/**
 * Hide the HUD. This still calls the hudWasHidden: delegate. This is the counterpart of the show: method. Use it to
 * hide the HUD when your task completes.
 *
 * @param animated If set to YES the HUD will disappear using the current animationType. If set to NO the HUD will not use
 * animations while disappearing.
 *
 * @see animationType
 */
- (void)hide:(BOOL)animated;

/**
 * Hide the HUD after a delay. This still calls the hudWasHidden: delegate. This is the counterpart of the show: method. Use it to
 * hide the HUD when your task completes.
 *
 * @param animated If set to YES the HUD will disappear using the current animationType. If set to NO the HUD will not use
 * animations while disappearing.
 * @param delay Delay in seconds until the HUD is hidden.
 *
 * @see animationType
 */
- (void)hide:(BOOL)animated afterDelay:(NSTimeInterval)delay;

/**
 * Read Only method that returns TRUE if HUD is no longer visible
 */
- (BOOL)isFinished;

#pragma mark - Threading

/**
 * Shows the HUD while a background task is executing in a new thread, then hides the HUD.
 *
 * This method also takes care of autorelease pools so your method does not have to be concerned with setting up a
 * pool.
 *
 * @param method The method to be executed while the HUD is shown. This method will be executed in a new thread.
 * @param target The object that the target method belongs to.
 * @param object An optional object to be passed to the method.
 * @param animated If set to YES the HUD will (dis)appear using the current animationType. If set to NO the HUD will not use
 * animations while (dis)appearing.
 */
- (void)showWhileExecuting:(SEL)method onTarget:(id)target withObject:(id)object animated:(BOOL)animated;

#if NS_BLOCKS_AVAILABLE

/**
 * Shows the HUD while a block is executing on a background queue, then hides the HUD.
 *
 * @see showAnimated:whileExecutingBlock:onQueue:completionBlock:
 */
- (void)showAnimated:(BOOL)animated whileExecutingBlock:(dispatch_block_t)block;

/**
 * Shows the HUD while a block is executing on a background queue, then hides the HUD.
 *
 * @see showAnimated:whileExecutingBlock:onQueue:completionBlock:
 */
- (void)showAnimated:(BOOL)animated whileExecutingBlock:(dispatch_block_t)block completionBlock:(MBProgressHUDCompletionBlock)completion;

/**
 * Shows the HUD while a block is executing on the specified dispatch queue, then hides the HUD.
 *
 * @see showAnimated:whileExecutingBlock:onQueue:completionBlock:
 */
- (void)showAnimated:(BOOL)animated whileExecutingBlock:(dispatch_block_t)block onQueue:(dispatch_queue_t)queue;

/**
 * Shows the HUD while a block is executing on the specified dispatch queue, executes completion block on the main queue, and then hides the HUD.
 *
 * @param animated If set to YES the HUD will (dis)appear using the current animationType. If set to NO the HUD will
 * not use animations while (dis)appearing.
 * @param block The block to be executed while the HUD is shown.
 * @param queue The dispatch queue on which the block should be executed.
 * @param completion The block to be executed on completion.
 *
 * @see completionBlock
 */
- (void)showAnimated:(BOOL)animated whileExecutingBlock:(dispatch_block_t)block onQueue:(dispatch_queue_t)queue
     completionBlock:(MBProgressHUDCompletionBlock)completion;

#pragma mark - Properties

/**
 * A block that gets called after the HUD was completely hidden.
 */
@property (copy) MBProgressHUDCompletionBlock completionBlock;

#endif  // NS_BLOCKS_AVAILABLE

/**
 * MBProgressHUD operation mode. The default is MBProgressHUDModeIndeterminate.
 *
 * @see MBProgressHUDMode
 */
@property (assign) MBProgressHUDMode mode;

/**
 * The animation type that should be used when the HUD is shown and hidden.
 *
 * @see MBProgressHUDAnimation
 */
@property (assign) MBProgressHUDAnimation animationType;

/**
 * The UIView (e.g., a UIImageView) to be shown when the HUD is in MBProgressHUDModeCustomView.
 * For best results use a 37 by 37 pixel view (so the bounds match the built in indicator bounds).
 */
#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
@property (MB_STRONG) UIView *customView;
#else   // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
@property (MB_STRONG) NSView *customView;
#endif  // (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)

/**
 * The HUD delegate object.
 *
 * @see MBProgressHUDDelegate
 */
@property (MB_WEAK) id<MBProgressHUDDelegate> delegate;

/**
 * An optional short message to be displayed below the activity indicator. The HUD is automatically resized to fit
 * the entire text. If the text is too long it will get clipped by displaying "..." at the end. If left unchanged or
 * set to @"", then no message is displayed.
 */
@property (copy) NSString *labelText;

/**
 * An optional details message displayed below the labelText message. This message is displayed only if the labelText
 * property is also set and is different from an empty string (@""). The details text can span multiple lines.
 */
@property (copy) NSString *detailsLabelText;

/**
 * The opacity of the HUD window. Defaults to 0.8 (80% opacity).
 */
@property (assign) float opacity;

/**
 * The color of the HUD window. Defaults to black. If this property is set, color is set using
 * this NSColor and the opacity property is not used.  using retain because performing copy on
 * NSColor base colors (like [NSColor greenColor]) cause problems with the copyZone.
 */
#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
@property (MB_STRONG) NSColor *color;
#else   // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
@property (MB_STRONG) NSColor *color;
#endif  // (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
/**
 * The x-axis offset of the HUD relative to the centre of the superview.
 */
@property (assign) float xOffset;

/**
 * The y-axis offset of the HUD relative to the centre of the superview.
 */
@property (assign) float yOffset;

/**
 * The size both horizontally and vertically of the spinner
 * Defaults to 37.0 on iOS and to 60.0 for Mac OS X
 */
@property (assign) float spinsize;

/**
 * The amount of space between the HUD edge and the HUD elements (labels, indicators or custom views).
 * Defaults to 20.0
 */
@property (assign) float margin;

/**
 * The corner radius for th HUD
 * Defaults to 10.0
 */
@property (assign) float cornerRadius;

/**
 * Cover the HUD background view with a radial gradient.
 */
@property (assign) BOOL dimBackground;

/**
 * Allow User to dismiss HUD manually by a tap event. This calls the optional hudWasTapped: delegate.
 * Defaults to NO.
 */
@property (assign) BOOL dismissible;


/*
 * Grace period is the time (in seconds) that the invoked method may be run without
 * showing the HUD. If the task finishes before the grace time runs out, the HUD will
 * not be shown at all.
 * This may be used to prevent HUD display for very short tasks.
 * Defaults to 0 (no grace time).
 * Grace time functionality is only supported when the task status is known!
 * @see taskInProgress
 */
@property (assign) float graceTime;

/**
 * The minimum time (in seconds) that the HUD is shown.
 * This avoids the problem of the HUD being shown and than instantly hidden.
 * Defaults to 0 (no minimum show time).
 */
@property (assign) float minShowTime;

/**
 * Indicates that the executed operation is in progress. Needed for correct graceTime operation.
 * If you don't set a graceTime (different than 0.0) this does nothing.
 * This property is automatically set when using showWhileExecuting:onTarget:withObject:animated:.
 * When threading is done outside of the HUD (i.e., when the show: and hide: methods are used directly),
 * you need to set this property when your task starts and completes in order to have normal graceTime
 * functionality.
 */
@property (assign) BOOL taskInProgress;

/**
 * Removes the HUD from its parent view when hidden.
 * Defaults to NO.
 */
@property (assign) BOOL removeFromSuperViewOnHide;

/**
 * Font to be used for the main label. Set this property if the default is not adequate.
 */
#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
@property (MB_STRONG) UIFont* labelFont;
#else   // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
@property (MB_STRONG) NSFont* labelFont;
#endif  // (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)

/**
 * Color to be used for the main label. Set this property if the default is not adequate.
 */
#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
@property (MB_STRONG) NSColor* labelColor;
#else   // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
@property (MB_STRONG) NSColor* labelColor;
#endif  // (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)

/**
 * Font to be used for the details label. Set this property if the default is not adequate.
 */
#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
@property (MB_STRONG) UIFont* detailsLabelFont;
#else   // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
@property (MB_STRONG) NSFont* detailsLabelFont;
#endif  // (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)

/**
 * Color to be used for the details label. Set this property if the default is not adequate.
 */
#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
@property (MB_STRONG) NSColor* detailsLabelColor;
#else   // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
@property (MB_STRONG) NSColor* detailsLabelColor;
#endif  // (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)

/**
 * The progress of the progress indicator, from 0.0 to 1.0. Defaults to 0.0.
 */
@property (assign) float progress;

/**
 * The minimum size of the HUD bezel. Defaults to CGSizeZero (no minimum size).
 */
@property (assign) CGSize minSize;

/**
 * Force the HUD dimensions to be equal if possible.
 */
@property (assign, getter = isSquare) BOOL square;

@end


@protocol MBProgressHUDDelegate <NSObject>

@optional

/**
 * Called after the HUD was fully hidden from the screen.
 */
- (void)hudWasHidden:(MBProgressHUD *)hud;

/**
 * Called after the HUD delay timed out but before HUD was fully hidden from the screen.
 */
- (void)hudWasHiddenAfterDelay:(MBProgressHUD *)hud;

/**
 * Called after the HUD was Tapped with dismissible option enabled.
 */
- (void)hudWasTapped:(MBProgressHUD *)hud;

/**
 * OS X Helper method to convert NSColor value to CGColorRef value.
 *
 * @nscolor NSColur instance to convert.
 * @return Converted NSColor to CGColorRef.
 */
#if !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
- (CGColorRef)NSColorToCGColor:(NSColor *)nscolor;
#endif  // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)

@end


/**
 * A progress view for showing definite progress by filling up a circle (pie chart).
 */
#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
@interface MBRoundProgressView : UIView
#else   // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
@interface MBRoundProgressView : NSView
{
    CGColorRef _cgColorFromNSColor;
}
#endif  // (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)

/**
 * Progress (0.0 to 1.0)
 */
@property (nonatomic, assign) float progress;

/**
 * Indicator progress color.
 * Defaults to white [NSColor whiteColor]
 */
#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
@property (nonatomic, MB_STRONG) NSColor *progressTintColor;
#else   // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
@property (nonatomic, MB_STRONG) NSColor *progressTintColor;
#endif  // (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)

/**
 * Indicator background (non-progress) color.
 * Defaults to translucent white (alpha 0.1)
 */
#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
@property (nonatomic, MB_STRONG) NSColor *backgroundTintColor;
#else   // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
@property (nonatomic, MB_STRONG) NSColor *backgroundTintColor;
#endif  // (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)

/*
 * Display mode - NO = round or YES = annular. Defaults to round.
 */
@property (nonatomic, assign, getter = isAnnular) BOOL annular;

@end


/**
 * A flat bar progress view.
 */
#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
@interface MBBarProgressView : UIView
#else   // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
@interface MBBarProgressView : NSView
{
    CGColorRef _cgColorFromNSColor;
}
#endif  // (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)

/**
 * Progress (0.0 to 1.0)
 */
@property (nonatomic, assign) float progress;

/**
 * Bar border line color.
 * Defaults to white [NSColor whiteColor].
 */
#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
@property (nonatomic, MB_STRONG) NSColor *lineColor;
#else   // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
@property (nonatomic, MB_STRONG) NSColor *lineColor;
#endif  // (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)

/**
 * Bar background color.
 * Defaults to clear [NSColor clearColor];
 */
#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
@property (nonatomic, MB_STRONG) NSColor *progressRemainingColor;
#else   // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
@property (nonatomic, MB_STRONG) NSColor *progressRemainingColor;
#endif  // (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)

/**
 * Bar progress color.
 * Defaults to white [NSColor whiteColor].
 */
#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
@property (nonatomic, MB_STRONG) NSColor *progressColor;
#else   // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
@property (nonatomic, MB_STRONG) NSColor *progressColor;
#endif  // (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)

/**
 * OS X Helper method to convert NSColor value to CGColorRef value.
 *
 * @nscolor NSColur instance to convert.
 * @return Converted NSColor to CGColorRef.
 */
#if !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
- (CGColorRef)NSColorToCGColor:(NSColor *)nscolor;
#endif  // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)

@end

#if !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
/**
 * A Spinner indefinite progress view modifying look of NSProgressIndicator.
 */
@interface MBSpinnerProgressView : NSProgressIndicator

@end

//
//  YRKSpinningProgressIndicator.h
//
//  Copyright 2009 Kelan Champagne. All rights reserved.
//
//  Modified for ObjC-ARC compatibility by Wayne Fox 2014

@interface YRKSpinningProgressIndicator : NSView {
    int _position;
    int _numFins;
#if __has_feature(objc_arc)
    NSMutableArray *_finColors;
#else
    NSColor **_finColors;
#endif
    
    BOOL _isAnimating;
    BOOL _isFadingOut;
    NSTimer *_animationTimer;
    NSThread *_animationThread;
    
    NSColor *_foreColor;
    NSColor *_backColor;
    BOOL _drawsBackground;
    
    BOOL _displayedWhenStopped;
    BOOL _usesThreadedAnimation;
    
    // For determinate mode
    BOOL _isIndeterminate;
    double _currentValue;
    double _maxValue;
}

@property (nonatomic, retain) NSColor *color;
@property (nonatomic, retain) NSColor *backgroundColor;
@property (nonatomic, assign) BOOL drawsBackground;

@property (nonatomic, assign, getter=isDisplayedWhenStopped) BOOL displayedWhenStopped;
@property (nonatomic, assign) BOOL usesThreadedAnimation;

@property (nonatomic, assign, getter=isIndeterminate) BOOL indeterminate;
@property (nonatomic, assign) double doubleValue;
@property (nonatomic, assign) double maxValue;

- (void)stopAnimation:(id)sender;
- (void)startAnimation:(id)sender;

@end

#endif  // !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
