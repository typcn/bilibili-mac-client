//
//  SP_Local.m
//  bilibili
//
//  Created by TYPCN on 2016/3/6.
//  Copyright © 2016 TYPCN. All rights reserved.
//

#import "SP_Local.h"
#import "NSString+LcsDiff.h"

@implementation SP_Local

- (BOOL) canHandle: (NSDictionary *)dict{
    if(dict && dict[@"files"]){
        return YES;
    }
    return NO;
}

- (NSDictionary *) getSubtitle: (NSDictionary *)dict{
    NSMutableDictionary *rdict = [dict mutableCopy];
    NSArray *selectedFiles = dict[@"files"];
    NSString *firstVideoPath;
    
    for(int i = 0; i < [selectedFiles count]; i++ )
    {
        NSString *path = [selectedFiles objectAtIndex:i];

        if([[path pathExtension] isEqualToString:@"xml"]){
            rdict[@"commentFile"] = path;
        }else if([[path pathExtension] isEqualToString:@"ass"]){
            rdict[@"subtitleFile"] = path;
        }else if(!firstVideoPath){
            firstVideoPath = path;
        }
    }
    
    NSString *fileDir = [firstVideoPath stringByDeletingLastPathComponent];
    NSArray *dirFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:fileDir error:nil];
    NSArray *assFiles = [dirFiles filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self ENDSWITH '.ass'"]];
    NSArray *xmlFiles = [dirFiles filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self ENDSWITH '.xml'"]];
    
    if(!rdict[@"subtitleFile"]){
        NSString *file = [self findBestMatch:firstVideoPath
                                             inFiles:assFiles
                                       withExtension:@".ass"];
        if(file) {
            rdict[@"subtitleFile"] = [NSString stringWithFormat:@"%@/%@",fileDir,file];
        }
    }
    
    if(!rdict[@"commentFile"]){
        NSString *file  = [self findBestMatch:firstVideoPath
                                             inFiles:xmlFiles
                                       withExtension:@".xml"];
        if(file) {
            rdict[@"commentFile"] = [NSString stringWithFormat:@"%@/%@",fileDir,file];
        }
    }
    
    return rdict;
}

- (NSString *)findBestMatch:(NSString *)firstVideoPath
                  inFiles:(NSArray *)files
            withExtension:(NSString *)ext
{
    
    // Find sub file with same name
    NSString *sameNameSub = [[firstVideoPath stringByDeletingPathExtension] stringByAppendingString:ext];
    if([[NSFileManager defaultManager] fileExistsAtPath:sameNameSub]){
        return sameNameSub;
    }
    
    if([files count] == 0){
        return NULL;
    }else if([files count] == 1){
        return [files objectAtIndex:0];
    }
    
    
    NSString *firstVideoName = [[firstVideoPath lastPathComponent] stringByDeletingPathExtension];

    // 寻找跟视频文件名区别最少的文件（大多数情况下，因为文件名中的分集数，可以直接定位到）
    NSUInteger minDiffCount = 9999;
    NSMutableArray *minDiffFiles;
    
    for (NSString *path in files) {
        NSString *name = [[path lastPathComponent] stringByDeletingPathExtension];
        NSArray *diffs = [firstVideoName lcsDiff:name];
        if (diffs.count < minDiffCount){
            minDiffCount = diffs.count;
            minDiffFiles = [[NSMutableArray alloc] init];
        }
        [minDiffFiles addObject:@{
                                  @"file":path,
                                  @"diffs":diffs
                                  }];
    }
    
    if([minDiffFiles count] == 0){
        return NULL;
    }else if([minDiffFiles count] == 1){
        return [minDiffFiles objectAtIndex:0][@"file"];
    }
    
    // 忽略增加的部分，再找一次 （部分字幕会带 Chs&XXX 之类的标识）
    NSMutableArray *minDiffFiles_ignoreAdd = [[NSMutableArray alloc] init];

    for (NSDictionary *mdf in minDiffFiles) {
        NSArray *diffs = mdf[@"diffs"];
        for (NSArray *diff in diffs) {
            if(![[diff objectAtIndex:0] length]){
                [minDiffFiles_ignoreAdd addObject:mdf[@"file"]];
                break;
            }
        }
    }
    
    if([minDiffFiles_ignoreAdd count] == 0){
        return NULL;
    }
    
    // 这还有重复就返回第一个吧。。
    return [minDiffFiles_ignoreAdd objectAtIndex:0];
}

@end