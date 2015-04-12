//
//  DownloadManager.m
//  bilibili
//
//  Created by TYPCN on 2015/4/11.
//  Copyright (c) 2015 TYPCN. All rights reserved.
//

#import "DownloadManager.h"

extern NSMutableArray *downloaderObjects;

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
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView{
    return downloaderObjects.count;
}

- (id)tableView:(NSTableView *)aTableView
objectValueForTableColumn:(NSTableColumn *)aTableColumn
            row:(NSInteger)rowIndex{
    NSDictionary *object = [downloaderObjects objectAtIndex:rowIndex];
    if(!object){
        return @"ERROR";
    }
    
    if([[aTableColumn identifier] isEqualToString:@"status"]){
        return [object valueForKey:@"status"];
    }else{
        return [object valueForKey:@"name"];
    }
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
//    if([[aTableColumn identifier] isEqualToString:@"status"]){
//        [downloaderObjects[rowIndex] replaceValueAtIndex:rowIndex inPropertyWithKey:@"status" withValue:anObject];
//    }else{
//        [downloaderObjects[rowIndex] replaceValueAtIndex:rowIndex inPropertyWithKey:@"name" withValue:anObject];
//    }
    
//    [[NSUserDefaults standardUserDefaults] setObject:downloaderObjects forKey:@"DownloadTaskList"];
//    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
