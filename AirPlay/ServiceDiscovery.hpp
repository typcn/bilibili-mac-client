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

bool SD_Start(const char *regType);
void SD_Wait();
void SD_Clear();

#endif /* ServiceDiscovery_hpp */
