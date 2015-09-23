//
//  ServiceDiscovery.hpp
//  bilibili
//
//  Created by TYPCN on 2015/9/13.
//  2015 TYPCN. MIT License
//

#ifndef ServiceDiscovery_hpp
#define ServiceDiscovery_hpp

#include <stdio.h>
#include <map>
#include <string>

extern std::map<std::string,std::string> SD_Map;
extern struct in_addr SD_inAddr;

bool SD_Start(const char *regType);
bool SD_Resolve(const char* name,const char *domain);
bool SD_Addr(const char* hostname);
void SD_Wait(int waitTime);
void SD_Clear();

#endif /* ServiceDiscovery_hpp */
