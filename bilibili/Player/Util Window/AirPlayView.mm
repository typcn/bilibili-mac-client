//
//  AirPlayView.mm
//  bilibili
//
//  Created by TYPCN on 2015/9/16.
//  Copyright © 2016 TYPCN. All rights reserved.
//

#import "vp_bilibili.h"
#import "AirPlayView.h"
#import "AirPlay.hpp"
#import "Common.hpp"

@interface AirPlayView (){
    bool isPlaying;
    NSMutableArray *deviceList;
    AirPlay *ap;
    dispatch_queue_t queue;
    __weak AirPlayWindowController *apwc;
    __weak IBOutlet NSTableView *tableView;
    __unsafe_unretained IBOutlet NSTextView *textView;
    __weak IBOutlet NSButton *refreshBtn;
    __weak IBOutlet NSButton *connectBtn;
    __weak IBOutlet NSButton *disconnBtn;
    const char* sel_devName; // Selected device name
    const char* sel_domain; // Selected device address or domain
}

@end

@implementation AirPlayView


- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"airplay view loaded");
    ap = new AirPlay();
    deviceList = [[NSMutableArray alloc] init];
    queue = dispatch_queue_create("com.typcn.airplay", DISPATCH_QUEUE_SERIAL);
    [tableView setFocusRingType:NSFocusRingTypeNone];
    [self writeLog:@"注意：该功能仅供测试，可能有很多 BUG ，如果出现问题，请点击帮助 -- 反馈，或者加群 467687309"];
    [self refreshDeviceList];
    apwc = self.view.window.windowController;
}

- (void)refreshDeviceList {
    [self writeLog:@"正在刷新设备列表"];
    [connectBtn setEnabled:NO];
    [refreshBtn setEnabled:NO];
    [refreshBtn setTitle:NSLocalizedString(@"读取中", NULL)];
    dispatch_async(queue, ^(void){
        NSDictionary *ddlist = ap->getDeviceList();
        for(id key in ddlist){
            NSArray *arr = [NSArray arrayWithObjects:key, ddlist[key] , nil];
            [deviceList addObject:arr];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^(void){
            NSLog(@"Ready to reload");
            [tableView reloadData];
            [refreshBtn setTitle:NSLocalizedString(@"刷新",NULL)];
            [refreshBtn setEnabled:YES];
            [self writeLog:@"设备列表刷新成功，请在左边选择一个服务器进行连接"];
        });
    });
}

- (IBAction)refreshAction:(id)sender {
    [self refreshDeviceList];
}

- (IBAction)connAction:(id)sender {
    if(!sel_devName || !sel_domain){
        [self writeLog:@"请选择一个服务器再进行连接"];
        return;
    }
    [connectBtn setEnabled:NO];
    [refreshBtn setEnabled:NO];
    dispatch_async(queue, ^(void){
        [self writeLog:@"正在初始化引擎（注意：暂时不支持分段视频与弹幕）"];
        bool suc = ap->selectDevice(sel_devName,sel_domain);
        if(!suc){
            [self writeLog:@"无法查找到设备地址"];
            [self connStop];
            return;
        }
        [self writeLog:@"正在尝试连接设备"];
        suc = ap->reverse();
        if(!suc){
            [self writeLog:@"无法连接到指定设备"];
            [self connStop];
            return;
        }
        [self writeLog:@"连接成功，正在尝试解析视频"];
        

        VP_Bilibili *bili = [VP_Bilibili sharedInstance];
        NSMutableDictionary *params = [[bili generateParamsFromURL:apwc.url] mutableCopy];

        params[@"cid"] = apwc.cid;
        params[@"title"] = apwc.vtitle;
        params[@"forceType"] = @"mp4";
        
        NSString *playurl;
        @try {
            VideoAddress *video = [bili getVideoAddress:params];
            if(!video){
                [NSException raise:@VP_RESOLVE_ERROR format:@"Empty Content"];
            }
            playurl = [video firstFragmentURL];
        }
        @catch (NSException *exception) {
            NSLog(@"[AirPlay] Error: %@",exception);
            [self writeLog:@"Bilibili API 暂时不可用，请稍后再试"];
            [self connStop];
            return;
        }
        
        if(!playurl){
            [self writeLog:@"视频解析失败，可能是视频源已失效，或者无 MP4 格式的视频（Apple 不支持 FLV）"];
            [self connStop];
            return;
        }
        [self writeLog:@"视频解析成功，正在尝试开始播放"];
        ap->playVideo([playurl cStringUsingEncoding:NSUTF8StringEncoding], 0);
        [self writeLog:@"已发起播放，请查看电视"];
        dispatch_async(dispatch_get_main_queue(), ^(void){
            isPlaying = true;
            [disconnBtn setEnabled:YES];
        });
    });
}
- (IBAction)playWithQT:(id)sender {
    [self writeLog:@"正在尝试解析视频"];
    VP_Bilibili *bili = [VP_Bilibili sharedInstance];
    NSMutableDictionary *params = [[bili generateParamsFromURL:apwc.url] mutableCopy];
    
    params[@"cid"] = apwc.cid;
    params[@"title"] = apwc.vtitle;
    params[@"forceType"] = @"mp4";
    
    NSString *playurl;
    @try {
        VideoAddress *video = [bili getVideoAddress:params];
        if(!video){
            [NSException raise:@VP_RESOLVE_ERROR format:@"Empty Content"];
        }
        playurl = [video firstFragmentURL];
    }
    @catch (NSException *exception) {
        NSLog(@"[AirPlay] Error: %@",exception);
        [self writeLog:@"Bilibili API 暂时不可用，请稍后再试"];
        [self connStop];
        return;
    }

    if(!playurl){
        [self writeLog:@"视频解析失败，可能是视频源已失效，或者无 MP4 格式的视频（Apple 不支持 FLV）"];
        return;
    }
    
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = @"/usr/bin/open";
    task.arguments = @[@"-a",@"QuickTime Player",playurl];
    [task launch];
}

- (IBAction)stopAction:(id)sender {
    dispatch_async(queue, ^(void){
        ap->stop();
        ap->disconnect();
        sleep(0.1);
        ap->clear();
        dispatch_async(dispatch_get_main_queue(), ^(void){
           [self.view.window close];
        });
    });
}

- (void)connStop {
    dispatch_async(dispatch_get_main_queue(), ^(void){
        [connectBtn setEnabled:YES];
        [refreshBtn setEnabled:YES];
    });
}

- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)rowIndex {
    if(isPlaying){
        return NO;
    }
    if([deviceList count] <= rowIndex){
        [self writeLog:@"选择的设备已经不存在，请刷新"];
        return NO;
    }
    NSArray *object = [deviceList objectAtIndex:rowIndex];
    if(!object){
        [self writeLog:@"选择的设备已经不存在，请刷新"];
        return NO;
    }
    sel_devName = [[object objectAtIndex:0] cStringUsingEncoding:NSUTF8StringEncoding];
    sel_domain = [[object objectAtIndex:1] cStringUsingEncoding:NSUTF8StringEncoding];
    [connectBtn setEnabled:YES];
    return YES;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView{
    return deviceList.count;
}

- (id)tableView:(NSTableView *)aTableView
objectValueForTableColumn:(NSTableColumn *)aTableColumn
            row:(NSInteger)rowIndex{
    if([deviceList count] <= rowIndex){
        return @"读取中";
    }
    NSArray *object = [deviceList objectAtIndex:rowIndex];
    if(!object){
        return @"ERROR";
    }
    if([[aTableColumn identifier] isEqualToString:@"c_addr"]){
        return [object objectAtIndex:1];
    }else{
        return [object objectAtIndex:0];
    }
}

- (void)writeLog:(NSString*)text
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        // Time string
        NSString *dateString = [NSDateFormatter localizedStringFromDate:[NSDate date]
                                                              dateStyle:NSDateFormatterShortStyle
                                                              timeStyle:NSDateFormatterMediumStyle];
        NSString *prefix = [NSString stringWithFormat:@"[%@] ",dateString];
        NSAttributedString* timeattr = [[NSAttributedString alloc] initWithString:prefix attributes:@{ NSForegroundColorAttributeName : [NSColor grayColor] }];
        
        // User string
        
        NSString *userContent = [NSString stringWithFormat:@"%@\n",NSLocalizedString(text, NULL)];
        NSAttributedString* attr = [[NSAttributedString alloc] initWithString:userContent];
        
        [[textView textStorage] appendAttributedString:timeattr];
        [[textView textStorage] appendAttributedString:attr];
        
        [textView scrollRangeToVisible:NSMakeRange([[textView string] length], 0)];
    });
}

@end

@implementation AirPlayWindowController



@end