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
    [downloaderObjects removeAllObjects];
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
        [downloaderObjects removeObject:object];
        int index = (int)[downloaderObjects count];
        
        if(cid && [cid length] > 0){
            NSDictionary *taskData = @{
                                       @"name":name,
                                       @"status":@"正在等待恢复",
                                       @"cid":cid,
                                       };
            dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                DL->init();
                DL->newTask([cid intValue], name);
                [downloaderObjects insertObject:taskData atIndex:index];
                DL->runDownload(index, name);
            });
        }else{
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
