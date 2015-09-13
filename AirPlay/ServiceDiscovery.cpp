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

std::map<const char*,const char*> sd_map;
DNSServiceRef SD_Serv = NULL;
time_t SD_StartTime = 0;

#if SD_LL == 1
#define SD_Log(...) \
            printf(__VA_ARGS__)
#else
#define SD_Log(...) do{}while(0)
#endif

void SD_BrowseReply(DNSServiceRef sdRef, DNSServiceFlags flags, uint32_t interfaceIndex, DNSServiceErrorType errorCode, const char *serviceName, const char *regtype, const char *replyDomain, void *context){
    if(errorCode == 0){
        SD_Log("[ServiceDiscovery] Found serviceName %s domain %s\n",serviceName,replyDomain);
    }else{
        fprintf(stderr, "[ServiceDiscovery] Cannot find dns service , errorCode: %d\n", errorCode);
    }
};

bool SD_Start(const char *regType){
    SD_Log("[ServiceDiscovery] Starting find %s\n",regType);
    DNSServiceErrorType err = DNSServiceBrowse(&SD_Serv, 0, 0, regType, NULL, SD_BrowseReply, NULL);
    if(err == kDNSServiceErr_NoError){
        SD_StartTime = time(0);
        SD_Log("[ServiceDiscovery] Find started \n");
        return true;
    }else{
        return false;
    }
}

void SD_Wait(){
    int dns_sd_fd  = SD_Serv ? DNSServiceRefSockFD(SD_Serv) : -1;
    int nfds = dns_sd_fd + 1;
    fd_set readfds;
    struct timeval tv;
    int result;
    
    //if (dns_sd_fd2 > dns_sd_fd) nfds = dns_sd_fd2 + 1;
    
    while (time(0) - SD_StartTime < 10)
    {
        FD_ZERO(&readfds);
        if (SD_Serv) FD_SET(dns_sd_fd , &readfds);
        tv.tv_sec  = 3;
        tv.tv_usec = 0;
        result = select(nfds, &readfds, (fd_set*)NULL, (fd_set*)NULL, &tv);
        
        if (result > 0){
            DNSServiceErrorType err = kDNSServiceErr_NoError;
            if(SD_Serv && FD_ISSET(dns_sd_fd , &readfds)){
                err = DNSServiceProcessResult(SD_Serv);
            }
            if (err) {
                fprintf(stderr, "[ServiceDiscovery] DNSServiceProcessResult returned %d\n", err);
                SD_StartTime = 0;
            }
        }else if(result == 0){
            sleep(1);
            continue;
        }else{
            fprintf(stderr, "[ServiceDiscovery] select() returned %d\n", result);
            SD_StartTime = 0;
        }
    }
}

void SD_Clear(){
    
}