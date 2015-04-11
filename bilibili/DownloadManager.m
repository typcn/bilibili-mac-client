//
//  DownloadManager.m
//  bilibili
//
//  Created by TYPCN on 2015/4/11.
//  Copyright (c) 2015 TYPCN. All rights reserved.
//

#import "DownloadManager.h"

NSMutableArray *objects;

@interface DownloadManager (){
    
}

@end

@implementation DownloadManager

- (void)viewDidLoad {
    [super viewDidLoad];
    NSArray *TaskList = [[NSUserDefaults standardUserDefaults] arrayForKey:@"DownloadTaskList"];
    objects = [TaskList copy];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView{
    return objects.count;
}

- (id)tableView:(NSTableView *)aTableView
objectValueForTableColumn:(NSTableColumn *)aTableColumn
            row:(NSInteger)rowIndex{
    NSMutableDictionary *object = objects[rowIndex];
    
    if([[aTableColumn identifier] isEqualToString:@"status"]){
        return [object valueForKey:@"status"];
    }else{
        return [object valueForKey:@"name"];
    }
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    if([[aTableColumn identifier] isEqualToString:@"status"]){
        [objects[rowIndex] replaceValueAtIndex:rowIndex inPropertyWithKey:@"status" withValue:anObject];
    }else{
        [objects[rowIndex] replaceValueAtIndex:rowIndex inPropertyWithKey:@"name" withValue:anObject];
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:objects forKey:@"DownloadTaskList"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
