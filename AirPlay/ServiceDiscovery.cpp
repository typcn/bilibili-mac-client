//
//  ServiceDiscovery.cpp
//  bilibili
//
//  Created by TYPCN on 2015/9/13.
//  2015 TYPCN. MIT License
//
//  WARNING: This is very experimental code , for testing only
//

#include "ServiceDiscovery.hpp"
#include <dns_sd.h>
#include <sys/types.h>
#include <unistd.h>			// For getopt() and optind
#include <netdb.h>			// For getaddrinfo()
#include <sys/time.h>		// For struct timeval
#include <sys/socket.h>		// For AF_INET
#include <netinet/in.h>		// For struct sockaddr_in()
#include <arpa/inet.h>		// For inet_addr()
#include <net/if.h>

using namespace std;

map<string,string>  SD_Map;             // (Browse)Name,Domain --> (Resolve)Name,URL
DNSServiceRef       SD_Serv = NULL;     // Service Ref
struct in_addr      SD_inAddr;          // Last resolved addr
const char *        SD_RegType;         // Last service type
string              SD_ServiceName;     // Last service name
time_t              SD_StartTime = 0;

#if SD_LL == 1
#define SD_Log(...) \
            printf(__VA_ARGS__)
#else
#define SD_Log(...) do{}while(0)
#endif

void SD_BrowseReply(DNSServiceRef       sdRef      , DNSServiceFlags flags      , uint32_t     interfaceIndex,
                    DNSServiceErrorType errorCode  , const char *    serviceName, const char * regtype       ,
                    const char *        replyDomain, void *          context){
    if(errorCode == 0){
        string serviceName_str = string(serviceName);
        SD_Map[serviceName_str] = string(replyDomain);
        SD_Log("[ServiceDiscovery] Found %s on domain %s\n",serviceName,replyDomain);
    }else{
        fprintf(stderr, "[ServiceDiscovery] Cannot find dns service , errorCode: %d\n", errorCode);
    }
};

void SD_ResolveReply(DNSServiceRef sdRef     , DNSServiceFlags flags   , uint32_t              interfaceIndex ,
           DNSServiceErrorType     errorCode , const char *    fullName, const char *          hostTarget     ,
                       uint16_t    opaqueport, uint16_t        txtLen  , const unsigned char * txtRecord      ,
                          void *   context   ){
    if(errorCode == 0){
        union { uint16_t s; u_char b[2]; } port = { opaqueport };
        uint16_t portNumber = ((uint16_t)port.b[0]) << 8 | port.b[1];
        string connect_str = string(hostTarget) + ":" + to_string(portNumber);
        SD_Map[SD_ServiceName] = connect_str;
        SD_Log("[ServiceDiscovery] %s be reached at %s\n",SD_ServiceName.c_str() , connect_str.c_str());
    }else{
        fprintf(stderr, "[ServiceDiscovery] Cannot find device host , errorCode: %d\n", errorCode);
    }
};

void SD_AddrReply(DNSServiceRef sdref, DNSServiceFlags flags, uint32_t interfaceIndex, DNSServiceErrorType errorCode, const char *hostname, const struct sockaddr *address, uint32_t ttl, void *context)
{
    if (errorCode)
    {
        if (errorCode == kDNSServiceErr_NoSuchRecord){
            printf("[ServiceDiscovery] GetAddrInfo failed , No Such Record");
        }else{
            printf("[ServiceDiscovery] GetAddrInfo failed ,  Error code %d", errorCode);
        }
    }else{
        SD_inAddr = ((struct sockaddr_in *)address)->sin_addr;
    }
}

bool SD_Start(const char *regType){
    SD_RegType = regType;
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

bool SD_Resolve(const char* name,const char *domain){
    SD_Serv = NULL;
    SD_ServiceName = string(name);
    SD_Log("[ServiceDiscovery] Starting resolve %s\n",name);
    DNSServiceErrorType err = DNSServiceResolve(&SD_Serv,0,0, name, SD_RegType, domain, SD_ResolveReply, NULL);
    if(err == kDNSServiceErr_NoError){
        SD_StartTime = time(0);
        SD_Log("[ServiceDiscovery] Recolve started \n");
        return true;
    }else{
        return false;
    }
}

bool SD_Addr(const char* hostname){
    SD_Serv = NULL;
    SD_Log("[ServiceDiscovery] Starting Getaddrinfo %s\n",hostname);
    DNSServiceErrorType err = DNSServiceGetAddrInfo(&SD_Serv, kDNSServiceFlagsReturnIntermediates, 0, kDNSServiceProtocol_IPv4, hostname, SD_AddrReply, NULL);
    // TODO: IPv6 Support
    if(err == kDNSServiceErr_NoError){
        SD_StartTime = time(0);
        SD_Log("[ServiceDiscovery] GetAddrInfo Started \n");
        return true;
    }else{
        return false;
    }
}

void SD_Wait(int waitTime){
    int dns_sd_fd  = SD_Serv ? DNSServiceRefSockFD(SD_Serv) : -1;
    int nfds = dns_sd_fd + 1;
    fd_set readfds;
    struct timeval tv;
    int result;
    
    //if (dns_sd_fd2 > dns_sd_fd) nfds = dns_sd_fd2 + 1;
    
    while (time(0) - SD_StartTime < waitTime)
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
            sleep(0.5);
            continue;
        }else{
            fprintf(stderr, "[ServiceDiscovery] select() returned %d\n", result);
            SD_StartTime = 0;
        }
    }
}

void SD_Clear(){
    SD_Map.clear();
    SD_Serv = NULL;
    SD_StartTime = 0;
    SD_ServiceName.clear();
}