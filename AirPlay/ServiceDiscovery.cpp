//
//  ServiceDiscovery.cpp
//  bilibili
//
//  Created by TYPCN on 2015/9/13.
//  2015 TYPCN. MIT License
//

#include "ServiceDiscovery.hpp"
#include <map>
#include <dns_sd.h>

std::map<const char*,const char*> scMap;

void SD_BrowseReply(DNSServiceRef sdRef, DNSServiceFlags flags, uint32_t interfaceIndex, DNSServiceErrorType errorCode, const char *serviceName, const char *regtype, const char *replyDomain, void *context){
    printf("on reply");
    if(errorCode == 0){
        printf("[ServiceDiscovery] Found serviceName %s domain %s\n",serviceName,replyDomain);
        
    }else{
        printf("[ServiceDiscovery] Cannot find dns service , errorCode: %d\n",errorCode);
    }
};

bool SD_Start(const char *regType){
    DNSServiceRef serv = NULL;
    printf("[ServiceDiscovery] Starting find %s\n",regType);
    DNSServiceErrorType err = DNSServiceBrowse(&serv, 0, 0, regType, NULL, SD_BrowseReply, NULL);
    if(err == kDNSServiceErr_NoError){
        printf("ok\n");
        return true;
    }else{
        return false;
    }
}

void SD_Clear(){
    
}