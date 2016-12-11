//
//  PFAboutWindowController.m
//
//  Copyright (c) 2015 Perceval FARAMAZ (@perfaram). All rights reserved.
//

#import <Cocoa/Cocoa.h>

/**
 *  The about window.
 */
@interface PFAboutWindowController : NSWindowController

/**
 *  The application name.
 *  Default: CFBundleName
 */
@property (copy) NSString *appName;

/**
 *  The application version.
 *  Default: "Version %@ (Build %@)", CFBundleVersion, CFBundleShortVersionString
 */
@property (copy) NSString *appVersion;

/**
 *  The copyright line.
 *  Default: NSHumanReadableCopyright
 */
@property (copy) NSAttributedString *appCopyright;

/**
 *  The credits.
 *  Default: contents of file at [[NSBundle mainBundle] pathForResource:@"Credits" ofType:@"rtf"];
 */
@property (copy) NSAttributedString *appCredits;

/**
 *  The EULA.
 *  Default: contents of file at [[NSBundle mainBundle] pathForResource:@"EULA" ofType:@"rtf"];
 */
@property (copy) NSAttributedString *appEULA;

/**
 *  The URL pointing to the app's website.
 *  Default: none
 */
@property (strong) NSURL *appURL;

/**
 *  The current text shown.
 */
@property (copy) NSAttributedString *textShown;

@property int windowState;

/**
 *  Visit the website.
 *
 *  @param sender The object making the call.
 */
- (IBAction)visitWebsite:(id)sender;

/**
 *  Show credits for libraries used etc.
 *
 *  @param sender The object making the call.
 */
- (IBAction)showCredits:(id)sender;

/**
 *  Show the End User License Agreement for your app.
 *
 *  @param sender The object making the call.
 */
- (IBAction)showEULA:(id)sender;

/**
 *  Show the Copyrights for your app.
 *
 *  @param sender The object making the call.
 */
- (IBAction)showCopyright:(id)sender;

/**
 *  Called when window is about to close.
 *
 *  @param sender The object making the call.
 */
- (BOOL)windowShouldClose:(id)sender;

/**
 *  Specify whether or not the window should use a shadow.
 *  Default: YES
 */
@property (assign) BOOL windowShouldHaveShadow;


@end
