//
//  CommentFilter.h
//  bilibili
//
//  Created by TYPCN on 2015/4/6.
//  Copyright (c) 2015 TYPCN. All rights reserved.
//

#ifndef __bilibili__CommentFilter__
#define __bilibili__CommentFilter__

#include <stdio.h>

void ApplyFilter(char *comments,int type,char* param);
void ReplaceCommentByKeyword(char *comments,char* keywords);
void ReplaceCommentByRegExp(char *comments,char* regexp);

#endif /* defined(__bilibili__CommentFilter__) */
