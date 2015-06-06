//
//  Bugsnag.h
//
//  Created by Conrad Irwin on 2014-10-01.
//
//  Copyright (c) 2014 Bugsnag, Inc. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall remain in place
// in this source code.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//
#import <Foundation/Foundation.h>

#import "BugsnagMetaData.h"
#import "BugsnagConfiguration.h"

static NSString* BugsnagSeverityError   = @"error";
static NSString* BugsnagSeverityWarning = @"warning";
static NSString* BugsnagSeverityInfo    = @"info";

@interface Bugsnag : NSObject

/** Get the current Bugsnag configuration.
 *
 * This method returns nil if called before +startBugsnagWIthApiKey: or
 * +startBugsnagWithConfiguration:, and otherwise returns the current
 * configuration for Bugsnag.
 *
 * @return The configuration, or nil.
 */
+ (BugsnagConfiguration*) configuration;

/** Start listening for crashes.
 *
 * This method initializes Bugsnag with the default configuration. Any uncaught
 * NSExceptions, C++ exceptions, mach exceptions or signals will be logged to
 * disk before your app crashes. The next time your app boots, we send any such
 * reports to Bugsnag.
 *
 * @param apiKey  The API key from your Bugsnag dashboard.
 */
+ (void)startBugsnagWithApiKey:(NSString*) apiKey;

/** Start listening for crashes.
 *
 * This method initializes Bugsnag. Any uncaught NSExceptions, uncaught
 * C++ exceptions, mach exceptions or signals will be logged to disk before
 * your app crashes. The next time your app boots, we send any such
 * reports to Bugsnag.
 *
 * @param configuration  The configuration to use.
 */
+ (void)startBugsnagWithConfiguration:(BugsnagConfiguration*) configuration;

/** Send a custom or caught exception to Bugsnag.
 *
 * The exception will be sent to Bugsnag in the background allowing your
 * app to continue running.
 *
 * @param exception  The exception.
 */
+ (void) notify:(NSException *) exception;

/** Send a custom or caught exception to Bugsnag.
 *
 * The exception will be sent to Bugsnag in the background allowing your
 * app to continue running.
 *
 * @param exception  The exception.
 *
 * @param metaData   Any additional information you want to send with the report.
 */
+ (void) notify:(NSException *) exception withData:(NSDictionary*) metaData;

/** Send a custom or caught exception to Bugsnag.
 *
 * The exception will be sent to Bugsnag in the background allowing your
 * app to continue running.
 *
 * @param exception  The exception.
 *
 * @param metaData   Any additional information you want to send with the report.
 *
 * @param severity   The severity level (default: BugsnagSeverityWarning)
 */
+ (void) notify:(NSException *) exception withData:(NSDictionary*) metaData atSeverity:(NSString*) severity;

/** Add custom data to send to Bugsnag with every exception.
 *
 * See also [Bugsnag configuration].metaData;
 *
 * @param attributeName  The name of the data.
 *
 * @param value          It's value.
 *
 * @param tabName        The tab to show it on on the Bugsnag dashboard.
 */
+ (void) addAttribute:(NSString*) attributeName withValue:(id) value toTabWithName:(NSString*) tabName;

/** Remove custom data from Bugsnag reports.
 *
 * @param tabName        The tab to clear.
 */
+ (void) clearTabWithName:(NSString*) tabName;

@end
