//
//  AirPlay.mm
//  bilibili
//
//  Created by TYPCN on 2015/9/13.
//  2015 TYPCN. MIT License
//
//  WARNING: This is very experimental testing code
//

#include "AirPlay.hpp"
#include "ServiceDiscovery.hpp"

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
        if(pair.first == std::string(deviceName)){
            connStr = pair.second;
        }
    }
    if(connStr.empty()){
        return false;
    }else{
        return true;
    }
}

void AirPlay::reverse(){
    if(connStr.empty()){
        return;
    }
    
    srand((int)time(0));
    
    char tmp_uuid[128];
    sprintf(tmp_uuid, "%x%x-%x-%x-%x-%x%x%x",
            rand(), rand(),                 // Generates a 64-bit Hex number
            rand(),                         // Generates a 32-bit Hex number
            ((rand() & 0x0fff) | 0x4000),   // Generates a 32-bit Hex number of the form 4xxx
            rand() % 0x3fff + 0x8000,       // Generates a 32-bit Hex number in the range [0x8000, 0xbfff]
            rand(), rand(), rand());        // Generates a 96-bit Hex number
    
    uuid = std::string(tmp_uuid);
    
    NSString* ConnStr = [NSString stringWithCString:connStr.c_str() encoding:NSUTF8StringEncoding];
    NSString* URLStr = [NSString stringWithFormat:@"http://%@/reverse",ConnStr];
    NSURL* URL = [NSURL URLWithString:URLStr];
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:URL];
    request.HTTPMethod = @"POST";
    
    // Headers
    
    NSString *nsuuid = [NSString stringWithCString:uuid.c_str() encoding:NSUTF8StringEncoding];
    
    [request addValue:@"PTTH/1.0"   forHTTPHeaderField:@"Upgrade"];
    [request addValue:@"Upgrade"    forHTTPHeaderField:@"Connection"];
    [request addValue:@"event"      forHTTPHeaderField:@"X-Apple-Purpose"];
    [request addValue:@"0"          forHTTPHeaderField:@"Content-Length"];
    [request addValue:userAgent     forHTTPHeaderField:@"User-Agent"];
    [request addValue:nsuuid        forHTTPHeaderField:@"X-Apple-Session-ID"];
    
    // Connection
    
    NSURLSessionConfiguration* sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession* session = [NSURLSession sessionWithConfiguration:sessionConfig delegate:nil delegateQueue:nil];
    
    NSURLSessionDataTask* task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error == nil) {
            // Success
            NSLog(@"Airplay UUID reverse succeeded: HTTP %ld", ((NSHTTPURLResponse*)response).statusCode);
        }
        else {
            // Failure
            NSLog(@"Airplay UUID reverse failed %@", [error localizedDescription]);
        }
    }];
    [task resume];
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
