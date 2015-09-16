//
//  AirPlay.mm
//  bilibili
//
//  Created by TYPCN on 2015/9/13.
//  2015 TYPCN. MIT License
//
//  WARNING: This is very experimental code , for testing only
//

#include "AirPlay.hpp"
#include "ServiceDiscovery.hpp"

#include <thread>
#include <sstream>
#include <sys/socket.h>
#include <netdb.h>

using namespace std;

NSDictionary *AirPlay::getDeviceList(){
    SD_Start("_airplay._tcp");
    SD_Wait(3);
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    for ( const auto &pair : SD_Map) {
        NSString *key = [NSString stringWithCString:pair.first.c_str() encoding:NSUTF8StringEncoding];
        NSString *value = [NSString stringWithCString:pair.second.c_str() encoding:NSUTF8StringEncoding];
        dict[key] = value;
    }
    return dict;
}

bool AirPlay::selectDevice(const char* deviceName,const char* domain){
    SD_Resolve(deviceName,domain);
    SD_Wait(2);
    for ( const auto &pair : SD_Map) {
        if(pair.first == string(deviceName)){
            connStr = pair.second;
        }
    }
    if(connStr.empty()){
        return false;
    }else{
        return true;
    }
}

void revReply(PTTH *rhttp){
    // TODO: Processing result
    const char* response = "HTTP/1.1 200 OK\r\nContent-Length: 0\r\n\r\n";
    int length = (int)strlen(response);
    while(rhttp){
        string res = rhttp->receive(2048);
        if(res.length() < 1){
            sleep(1);
        }else{
            rhttp->send_data(response, length);
        }
    }
}

bool AirPlay::reverse(){
    if(connStr.empty()){
        return false;
    }
    
    srand((int)time(0));
    
    char tmp_uuid[128];
    sprintf(tmp_uuid, "%x%x-%x-%x-%x-%x%x%x",
            rand(), rand(),                 // Generates a 64-bit Hex number
            rand(),                         // Generates a 32-bit Hex number
            ((rand() & 0x0fff) | 0x4000),   // Generates a 32-bit Hex number of the form 4xxx
            rand() % 0x3fff + 0x8000,       // Generates a 32-bit Hex number in the range [0x8000, 0xbfff]
            rand(), rand(), rand());        // Generates a 96-bit Hex number
    
    uuid = string(tmp_uuid);
    
    rhttp = new PTTH();
    bool suc = rhttp->conn(connStr.c_str());
    if(!suc){
        return false;
    }
    
    stringstream ss;
    ss << "POST /reverse HTTP/1.1" << "\r\n";
    ss << "Upgrade: PTTH/1.0" << "\r\n";
    ss << "Connection: Upgrade" << "\r\n";
    ss << "X-Apple-Purpose: event" << "\r\n";
    ss << "Content-Length: 0" << "\r\n";
    ss << "User-Agent: " << [userAgent cStringUsingEncoding:NSUTF8StringEncoding] << "\r\n";
    ss << "X-Apple-Session-ID: " << uuid << "\r\n";
    ss << "\r\n";
    
    string sendStr = ss.str();
    suc = rhttp->send_data(sendStr.c_str(), (int)sendStr.size());
    if(!suc){
        return false;
    }
    
    string result = rhttp->receive(2048);
    if(result.find("101") != string::npos){
        std::thread t1(revReply,rhttp);
        t1.detach();
        return true;
    }else{
        return false;
    }
}

void AirPlay::playVideo(const char* url,float startpos){
    NSString* ConnStr = [NSString stringWithCString:connStr.c_str() encoding:NSUTF8StringEncoding];
    NSString* URLStr = [NSString stringWithFormat:@"http://%@/play",ConnStr];

    
    NSURL* URL = [NSURL URLWithString:URLStr];
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:URL];
    request.HTTPMethod = @"POST";
    
    // Headers
    
    NSString *nsuuid = [NSString stringWithCString:uuid.c_str() encoding:NSUTF8StringEncoding];
    
    [request addValue:userAgent     forHTTPHeaderField:@"User-Agent"];
    [request addValue:@"text/parameters" forHTTPHeaderField:@"Content-Type"];
    [request addValue:nsuuid        forHTTPHeaderField:@"X-Apple-Session-ID"];

    // Body
    
    NSString *body = [NSString stringWithFormat:@"Content-Location: %s\r\nStart-Position: %f", url, startpos];
    request.HTTPBody = [body dataUsingEncoding:NSUTF8StringEncoding];
                        
    // Connection
    
    NSURLSessionConfiguration* sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession* session = [NSURLSession sessionWithConfiguration:sessionConfig delegate:nil delegateQueue:nil];
    
    NSURLSessionDataTask* task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error == nil) {
            NSLog(@"Airplay play by url: HTTP %ld", ((NSHTTPURLResponse*)response).statusCode);
        }
        else {
            NSLog(@"Airplay play failed %@", [error localizedDescription]);
        }
    }];
    [task resume];
}
