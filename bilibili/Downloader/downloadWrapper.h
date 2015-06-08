//
//  downloadWrapper.h
//  bilibili
//
//  Created by TYPCN on 2015/6/6.
//  Copyright (c) 2015 TYPCN. All rights reserved.
//

#ifndef bilibili__downloadWrapper
#define bilibili__downloadWrapper

#include <stdio.h>
#include "aria2.hpp"
#include <mutex>

#import <Cocoa/Cocoa.h>

class Downloader {
private:
    aria2::Session* session;
    aria2::SessionConfig config;
    NSArray *getUrl(int cid);
    std::mutex mtx;
public:
    void init();
    aria2::Session* getSession() {return session;}
    void newTask(int cid,NSString *name);
    void runDownload(int fileid,NSString *filename);
};

#endif /* defined(__bilibili__downloadWrapper__) */
