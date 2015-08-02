//
//  DownloadManager.m
//  bilibili
//
//  Created by TYPCN on 2015/4/11.
//  Copyright (c) 2015 TYPCN. All rights reserved.
//

#import "DownloadManager.h"
#import "downloadWrapper.h"

extern NSMutableArray *downloaderObjects;
extern NSLock *dList;
extern Downloader* DL;
extern BOOL isStopped;

@interface DownloadManager (){
    
}

@end

@implementation DownloadManager

- (void)viewDidLoad {
    [super viewDidLoad];
    [NSTimer scheduledTimerWithTimeInterval:3
                                     target:self
                                   selector:@selector(updateString)
                                   userInfo:nil
                                    repeats:YES];
}

-(void)updateString
{
    [self.tableView reloadData];
    [[NSUserDefaults standardUserDefaults] setObject:[downloaderObjects copy] forKey:@"DownloadTaskList"];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView{
    return downloaderObjects.count;
}

- (id)tableView:(NSTableView *)aTableView
objectValueForTableColumn:(NSTableColumn *)aTableColumn
            row:(NSInteger)rowIndex{
    if([downloaderObjects count] <= rowIndex){
        return @"请稍后";
    }
    [dList lock];
    NSDictionary *object = [downloaderObjects objectAtIndex:rowIndex];
    if(!object){
        return @"ERROR";
    }
    [dList unlock];
    if([[aTableColumn identifier] isEqualToString:@"status"]){
        return [object valueForKey:@"status"];
    }else{
        return [object valueForKey:@"name"];
    }
}
- (IBAction)openFolder:(id)sender {
    NSString* folder = [NSString stringWithFormat:@"%@/Movies/Bilibili",NSHomeDirectory()];
    [[NSWorkspace sharedWorkspace] openFile:folder];
}
- (IBAction)clearDLList:(id)sender {
    isStopped = true;
    [dList lock];
    for (id object in downloaderObjects) {
        if([[object valueForKey:@"status"] isEqualToString:@"下载已完成"]){
            [downloaderObjects removeObject:object];
        }
    }
    [dList unlock];
}
- (IBAction)clearAllDL:(id)sender {
    [dList lock];
    int length = (int)[downloaderObjects count];
    for (int i = 0;i < length;i++) {
        id object = [downloaderObjects objectAtIndex:i];
        if([[object valueForKey:@"lastUpdate"] length] > 0){
            float lastUpdate = [[object valueForKey:@"lastUpdate"] floatValue];
            long currentTime = time(0);
            if((currentTime - lastUpdate) < 20){
                continue;
            }
        }
        [downloaderObjects removeObject:object];
    }
    [dList unlock];
}
- (IBAction)continueDownload:(id)sender {
    [dList lock];
    if(!DL){
        DL = new Downloader();
    }
    for (id object in downloaderObjects) {
        NSString *cid = [object valueForKey:@"cid"];
        NSString *name = [object valueForKey:@"name"];
        NSString *lastUp = [object valueForKey:@"lastUpdate"];
        
        int index = (int)[downloaderObjects count] - 1;
        
        if(cid && [cid length] > 0){
            if([lastUp length] > 0){
                float lastUpdate = [lastUp floatValue];
                long currentTime = time(0);
                if((currentTime - lastUpdate) < 10){
                    continue;
                }else{
                    [downloaderObjects removeObject:object];
                }
            }
            NSDictionary *taskData = @{
                                       @"name":name,
                                       @"status":@"正在等待恢复",
                                       @"cid":cid,
                                       };
            [downloaderObjects insertObject:taskData atIndex:index];
            dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                DL->init();
                DL->newTask([cid intValue], name);
                DL->runDownload(index, name);
            });
        }else{
            [downloaderObjects removeObject:object];
            NSDictionary *taskData = @{
                                       @"name":name,
                                       @"status":@"恢复下载失败",
                                       };
            [downloaderObjects insertObject:taskData atIndex:index];
        }
    }
    [dList unlock];
}

@end
