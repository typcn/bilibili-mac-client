//
//  reverseHTTP.cpp
//  bilibili
//
//  Created by TYPCN on 2015/9/16.
//  2015 TYPCN. MIT License
//
//  WARNING: This is very experimental code , for testing only
//

#include "reverseHTTP.hpp"
#include "ServiceDiscovery.hpp"

#include <iostream>
#include <stdio.h>
#include <string.h>
#include <string>
#include <sys/socket.h>
#include <netdb.h>

using namespace std;

PTTH::PTTH()
{
    sock = -1;
}

bool PTTH::conn(const char *address)
{
    char *addr_chr = (char *)malloc(strlen(address)+1);
    strcpy(addr_chr,address);

    char *addr_hostname = strtok(addr_chr, ":");
    if(!addr_hostname){
        printf("[PTTH] Missing hostname !\n");
        return false;
    }
    char *addr_port = strtok(NULL, ":");
    if(!addr_port){
        printf("[PTTH] Missing port !\n");
        return false;
    }
    SD_Addr(addr_hostname);
    printf("[PTTH] Trying to resolve  %s\n",addr_hostname);
    SD_Wait(2);

    const unsigned char *b = (const unsigned char *) &SD_inAddr;
    if(!b){
        printf("[PTTH] Failed to resolve hostname\n");
        return false;
    }
    printf("[PTTH] Resolved to: %d.%d.%d.%d \n", b[0], b[1], b[2], b[3]);
    
    if(sock == -1)
    {
        sock = socket(AF_INET , SOCK_STREAM , 0);
    }

    server.sin_addr =  SD_inAddr;
    server.sin_family = AF_INET;
    server.sin_port = htons(atoi(addr_port));
    
    if (connect(sock , (struct sockaddr *)&server , sizeof(server)) < 0)
    {
        printf("[PTTH] Failed to connect server\n");
        return false;
    }
    
    printf("[PTTH] %s Connected\n",addr_port);
    return true;
}

bool PTTH::send_data(const void *data,int size)
{
    long code = send(sock , data, size , 0);
    if(code == 0)
    {
        shutdown(sock, SHUT_RDWR);
        sock = -1;
        return false;
    }else if(code < 0){
        sock = -1;
        return false;
    }
    return true;
}

string PTTH::receive(int size=512)
{
    char buffer[size];
    bzero(buffer, size);
    long code = recv(sock , buffer , size , 0);
    if(code == 0)
    {
        shutdown(sock, SHUT_RDWR);
        sock = -1;
        return "";
    }else if(code < 0){
        sock = -1;
        return "";
    }
    string reply(buffer);
    return reply;
}

void PTTH::disconnect()
{
    shutdown(sock, SHUT_RDWR);
    sock = NULL;
}
