//
//  AboutView.m
//  bilibili
//
//  Created by TYPCN on 2015/3/31.
//  Copyright (c) 2015 TYPCN. All rights reserved.
//

#import "AboutView.h"

@interface NSAttributedString (Hyperlink)
+(id)hyperlinkFromString:(NSString*)inString withURL:(NSURL*)aURL;
@end

@implementation NSAttributedString (Hyperlink)
+(id)hyperlinkFromString:(NSString*)inString withURL:(NSURL*)aURL
{
    NSMutableAttributedString* attrString = [[NSMutableAttributedString alloc] initWithString: inString];
    NSRange range = NSMakeRange(0, [attrString length]);
    
    [attrString beginEditing];
    [attrString addAttribute:NSLinkAttributeName value:[aURL absoluteString] range:range];
    
    // make the text appear in blue
    [attrString addAttribute:NSForegroundColorAttributeName value:[NSColor blueColor] range:range];
    
    // next make the text appear with an underline
    [attrString addAttribute:
     NSUnderlineStyleAttributeName value:[NSNumber numberWithInt:NSUnderlineStyleSingle] range:range];
    
    [attrString endEditing];
    
    return attrString;
}
@end

@interface AboutView ()

@end

@implementation AboutView


- (void)loadView {
    [super loadView];
    [self.aboutText setAllowsEditingTextAttributes: YES];
    [self.aboutText setSelectable: YES];
    
    NSMutableAttributedString* string = [[NSMutableAttributedString alloc] init];
    
    [string appendAttributedString: [[NSAttributedString alloc] initWithString: @"开发者: typcn\n博客:"]];
    [string appendAttributedString: [NSAttributedString hyperlinkFromString:@"http://blog.eqoe.cn" withURL:[NSURL URLWithString:@"http://blog.eqoe.cn/?from=bilimac"]]];
    
    [string appendAttributedString: [[NSAttributedString alloc] initWithString: @"\n源代码:"]];
    [string appendAttributedString: [NSAttributedString hyperlinkFromString:@"https://github.com/typcn/bilibili-mac-client" withURL:[NSURL URLWithString:@"https://github.com/typcn/bilibili-mac-client"]]];
    
    [string appendAttributedString: [[NSAttributedString alloc] initWithString: @"\n许可协议: GPLv2\n\n感谢：\n"]];
    [string appendAttributedString: [NSAttributedString hyperlinkFromString:@"Bilidan" withURL:[NSURL URLWithString:@"https://github.com/m13253/BiliDan"]]];
    
    [string appendAttributedString: [[NSAttributedString alloc] initWithString: @"\n\n使用以下开源项目:\n"]];
    [string appendAttributedString: [NSAttributedString hyperlinkFromString:@"mpv\n" withURL:[NSURL URLWithString:@"https://github.com/mpv-player/mpv"]]];
    [string appendAttributedString: [NSAttributedString hyperlinkFromString:@"ISSoundAdditions\n" withURL:[NSURL URLWithString:@"https://github.com/InerziaSoft/ISSoundAdditions"]]];
    [string appendAttributedString: [NSAttributedString hyperlinkFromString:@"Sparkle\n" withURL:[NSURL URLWithString:@"https://github.com/sparkle-project/Sparkle"]]];
    [string appendAttributedString: [NSAttributedString hyperlinkFromString:@"Danmaku2ass\n" withURL:[NSURL URLWithString:@"https://github.com/m13253/danmaku2ass"]]];
    [string appendAttributedString: [NSAttributedString hyperlinkFromString:@"FFmpeg\n" withURL:[NSURL URLWithString:@"https://www.ffmpeg.org/"]]];
    
    [string appendAttributedString: [[NSAttributedString alloc] initWithString: @"\n\nCopyleft 2015 TYPCN"]];
    
    [self.aboutText setAttributedStringValue: string];
}

@end
