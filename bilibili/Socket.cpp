//
//  Socket.cpp
//  bilibili
//
//  Created by TYPCN on 2015/5/17.
//  Copyright (c) 2015 TYPCN. All rights reserved.
//

#include "Socket.hpp"

#include <iostream>
#include <stdio.h>
#include <string.h>
#include <string>
#include <sys/socket.h>
#include <netdb.h>

using namespace std;

void handShake();

tcp_client::tcp_client()
{
    sock = -1;
    port = 0;
    address = "";
}

string rec_address;
int rec_port;

/**
 Connect to a host on a certain port number
 */
bool tcp_client::conn(string address , int port)
{
    rec_address = address;
    rec_port = port;
    //create socket if it is not already created
    if(sock == -1)
    {
        //Create socket
        sock = socket(AF_INET , SOCK_STREAM , 0);
        if (sock == -1)
        {
            perror("Could not create socket");
        }
        
        cout<<"Socket created\n";
    }
    else    {   /* OK , nothing */  }
    
    //setup address structure
    if(inet_addr(address.c_str()) == -1)
    {
        struct hostent *he;
        struct in_addr **addr_list;
        
        //resolve the hostname, its not an ip address
        if ( (he = gethostbyname( address.c_str() ) ) == NULL)
        {
            //gethostbyname failed
            herror("gethostbyname");
            cout<<"Failed to resolve hostname\n";
            
            return false;
        }
        
        //Cast the h_addr_list to in_addr , since h_addr_list also has the ip address in long format only
        addr_list = (struct in_addr **) he->h_addr_list;
        
        for(int i = 0; addr_list[i] != NULL; i++)
        {
            //strcpy(ip , inet_ntoa(*addr_list[i]) );
            server.sin_addr = *addr_list[i];
            
            cout<<address<<" resolved to "<<inet_ntoa(*addr_list[i])<<endl;
            
            break;
        }
    }
    
    //plain ip address
    else
    {
        server.sin_addr.s_addr = inet_addr( address.c_str() );
    }
    
    server.sin_family = AF_INET;
    server.sin_port = htons( port );
    
    //Connect to remote server
    if (connect(sock , (struct sockaddr *)&server , sizeof(server)) < 0)
    {
        perror("connect failed. Error");
        return 1;
    }
    handShake();
    cout<<"Connected\n";
    return true;
}

/**
 Send data to the connected host
 */
bool tcp_client::send_data(const void *data,int size)
{
    long code = send(sock , data, size , 0);
    if(code == 0)
    {
        shutdown(sock, SHUT_RDWR);
        sock = -1;
        conn(rec_address, rec_port);
        return false;
    }else if(code < 0){
        sock = -1;
        conn(rec_address, rec_port);
        return false;
    }
    return true;
}

/**
 Receive data from the connected host
 */
string tcp_client::receive(int size=512)
{
    char buffer[size];
    bzero(buffer, size);
    long code = recv(sock , buffer , size , 0);
    if(code == 0)
    {
        shutdown(sock, SHUT_RDWR);
        sock = -1;
        conn(rec_address, rec_port);
        return "Server closed connection , reconnecting";
    }else if(code < 0){
        sock = -1;
        conn(rec_address, rec_port);
        return "Server closed connection , reconnecting";
    }
    buffer[0] = ' ';
    buffer[1] = ' ';
    buffer[2] = ' ';
    buffer[3] = ' ';
    string reply(buffer);
    return reply;
}
