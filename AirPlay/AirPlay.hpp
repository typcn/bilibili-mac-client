//
//  AirPlay.hpp
//  bilibili
//
//  Created by TYPCN on 2015/9/13.
//  2015 TYPCN. MIT License
//

#ifndef AirPlay_hpp
#define AirPlay_hpp

#include <stdio.h>
#include <string>
#include <map>

#import <Foundation/Foundation.h>

// To use on other platforms , Just change the NSURLSession to libcURL , NSArray to std::map


class AirPlay{
private:
    std::string uuid;
    std::string connStr;
    NSString *userAgent = @"TYPCNAirPlay/1.00 (like iTunes/12.2.2)";
public:
    NSDictionary *getDeviceList();
    bool selectDevice(const char* deviceName,const char* domain);
    void reverse();
    void playVideo(const char* url,float startpos);
};

#endif /* AirPlay_hpp */
