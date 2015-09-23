//
//  reverseHTTP.hpp
//  bilibili
//
//  Created by TYPCN on 2015/9/16.
//  2015 TYPCN. MIT License
//

#ifndef reverseHTTP_hpp
#define reverseHTTP_hpp

#include <stdio.h>
#include <string>
#include <arpa/inet.h>

class PTTH{
private:
    int sock;
    std::string address;
    int port;
    struct sockaddr_in server;
    
public:
    PTTH();
    bool conn(const char *address);
    bool send_data(const void *data,int size);
    std::string receive(int);
    void disconnect();
};

#endif /* reverseHTTP_hpp */
