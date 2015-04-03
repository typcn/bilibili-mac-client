//
//  PostComment.m
//  bilibili
//
//  Created by TYPCN on 2015/4/4.
//  Copyright (c) 2015 TYPCN. All rights reserved.
//

#import "PostComment.h"
#import "client.h"

extern NSString *vAID;
extern NSString *vPID;
extern NSString *vCID;
extern NSString *userAgent;
extern mpv_handle *mpv;

@interface PostComment (){
    BOOL posted;
}

@end

@implementation PostComment

- (void)viewDidLoad {
    [super viewDidLoad];
    //[self.view.window makeKeyWindow];
    //[self.view.window makeFirstResponder:self];
    posted = false;
}
- (IBAction)Send:(id)sender {
    if(posted){
        return;
    }
    
    posted = true;
    
    NSString *text = [sender stringValue];
    if([text length] > 0){
        char *time = mpv_get_property_string(mpv,"playback-time");
        NSString *playTime = [NSString stringWithCString:time encoding:NSUTF8StringEncoding];
        NSLog(@"Posting comment in %@",playTime);
        
        
        NSURL* URL = [NSURL URLWithString:[NSString stringWithFormat:@"http://interface.bilibili.com/dmpost?cid=%@&aid=%@&pid=%@",vCID,vAID,vPID]];
        NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:URL];
        request.HTTPMethod = @"POST";
        request.timeoutInterval = 5;
        
        // Get Date
        
        NSDateFormatter *format = [[NSDateFormatter alloc] init];
        [format setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        NSDate *now = [[NSDate alloc] init];
        NSString *dateString = [format stringFromDate:now];
        
        // Body
        
        NSDictionary* bodyParameters = @{
                                         @"cid": vCID,
                                         @"color": @"16777215",
                                         @"mode": @"1",
                                         @"pool": @"0",
                                         @"fontsize": @"25",
                                         @"date": dateString,
                                         @"message": text,
                                         @"playTime": playTime,
                                         };
        request.HTTPBody = [NSStringFromQueryParameters(bodyParameters) dataUsingEncoding:NSUTF8StringEncoding];
        
        // Headers
        
        [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
        [request addValue:userAgent forHTTPHeaderField:@"User-Agent"];
        [request setValue:@"http://static.hdslb.com" forHTTPHeaderField:@"Origin"];
        [request setValue:@"http://static.hdslb.com/play.swf" forHTTPHeaderField:@"Referer"];
        [request setValue:@"ShockwaveFlash/17.0.0.134" forHTTPHeaderField:@"X-Requested-With"];
        // Cookies will add automatically
        
        // Send Request
        
        NSURLResponse * response = nil;
        NSError * error = nil;
        NSData * data = [NSURLConnection sendSynchronousRequest:request
                                              returningResponse:&response
                                                          error:&error];
        NSString *returnData = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        
        if([returnData length] > 0){
            int x = [returnData intValue];
            if (x > 0){
                [sender setStringValue:@"😁发送成功！"];
                NSLog(@"Comment sent. ID: %d",x);
            }else{
                [sender setStringValue:[NSString stringWithFormat:@"😢发送失败 错误码 %d",x]];
                NSLog(@"Comment send failed. Error code: %d",x);
            }
        }else{
            [sender setStringValue:@"😡简直日了狗了！没发出去！"];
            NSLog(@"Comment send failed. Empty response");
        }
        double delayInSeconds = 3.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [sender setStringValue:@""];
            [self.view.window close];
        });
    }else{
        [self.view.window close];
    }
}

/*
 * Utils: Add this section before your class implementation
 */

/**
 This creates a new query parameters string from the given NSDictionary. For
 example, if the input is @{@"day":@"Tuesday", @"month":@"January"}, the output
 string will be @"day=Tuesday&month=January".
 @param queryParameters The input dictionary.
 @return The created parameters string.
 */
static NSString* NSStringFromQueryParameters(NSDictionary* queryParameters)
{
    NSMutableArray* parts = [NSMutableArray array];
    [queryParameters enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
        NSString *part = [NSString stringWithFormat: @"%@=%@",
                          [key stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding],
                          [value stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]
                          ];
        [parts addObject:part];
    }];
    return [parts componentsJoinedByString: @"&"];
}

/**
 Creates a new URL by adding the given query parameters.
 @param URL The input URL.
 @param queryParameters The query parameter dictionary to add.
 @return A new NSURL.
 */
static NSURL* NSURLByAppendingQueryParameters(NSURL* URL, NSDictionary* queryParameters)
{
    NSString* URLString = [NSString stringWithFormat:@"%@?%@",
                           [URL absoluteString],
                           NSStringFromQueryParameters(queryParameters)
                           ];
    return [NSURL URLWithString:URLString];
}

@end

@interface PostCommentWindow : NSWindow <NSWindowDelegate>

@end

@implementation PostCommentWindow{
    
}

- (BOOL)canBecomeMainWindow { return YES; }
- (BOOL)canBecomeKeyWindow { return YES; }
- (BOOL) becomeFirstResponder { return YES; }
- (BOOL) resignFirstResponder { return YES; }

@end