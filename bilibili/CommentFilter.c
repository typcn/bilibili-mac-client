//
//  CommentFilter.c
//  bilibili
//
//  Created by TYPCN on 2015/4/6.
//  Copyright (c) 2015 TYPCN. All rights reserved.
//

#include "CommentFilter.h"
#include <time.h>
#include <regex.h>

regex_t regex;
int reti;

//
//   WARNING: The c filter is not completed !
//
//
//

void ApplyFilter(char *comments,int type,char *param){
    clock_t start = clock(), diff;
    
    if(type == 1){
        ReplaceCommentByKeyword(comments,param);
    }else if(type == 2){
        ReplaceCommentByRegExp(comments,param);
    }else{
        printf("WARNING: Unknown type\n");
    }
    
    diff = clock() - start;
    int msec = (int)(diff * 1000 / CLOCKS_PER_SEC);
    printf("Time taken %d seconds %d milliseconds", msec/1000, msec%1000);
}

void ReplaceCommentByKeyword(char *comments,char *keywords){

}

void ReplaceCommentByRegExp(char *comments,char *regexp){

}


