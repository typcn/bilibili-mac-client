//
//  ViewController.h
//  bilibili
//
//  Created by TYPCN on 2015/3/30.
//  Copyleft 2015 TYPCN. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@interface ViewController : NSViewController

@property (weak) IBOutlet NSTextField *urlField;


@end

@interface WebController : NSObject
{
    IBOutlet WebView* webView;
}
@property (weak) IBOutlet NSButton *switchButton;
@end