//
//  AirPlayTests.m
//  AirPlayTests
//
//  Created by TYPCN on 2015/9/13.
//  Copyright © 2015 TYPCN. All rights reserved.
//

#import <XCTest/XCTest.h>
#include "ServiceDiscovery.hpp"
#include "AirPlay.hpp"

@interface AirPlayTests : XCTestCase

@end

@implementation AirPlayTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testServiceDiscovery {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Testing ServiceDiscovery"];
    

    dispatch_async(dispatch_get_global_queue(0, NULL),^(void){
        SD_Start("_airplay._tcp");
        SD_Wait(5);
        const char* serviceName = nullptr;
        const char* domain = nullptr;
        for ( const auto &pair : SD_Map) {
            serviceName = pair.first.c_str();
            domain      = pair.second.c_str();
        }
        printf("[AirPlayTest] using %s\n",serviceName);
        
        SD_Resolve(serviceName,domain);
        SD_Wait(5);
        
        const char* address = nullptr;
        for ( const auto &pair : SD_Map) {
            serviceName = pair.first.c_str();
            address      = pair.second.c_str();
        }
        printf("[AirPlayTest] Result: %s , %s\n",serviceName, address);
        
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:30.0 handler:^(NSError *error) {
        
        if(error)
        {
            XCTFail(@"Expectation Failed with error: %@", error);
        }
        
    }];
}

- (void)testAirPlay{
    AirPlay *ap = new AirPlay();
    NSDictionary *dlist = ap->getDeviceList();
    NSLog(@"Got device list: %@",dlist);
    const char *device = nullptr;
    const char *domain = nullptr;
    for(id devName in dlist){
        device = [devName cStringUsingEncoding:NSUTF8StringEncoding];
        domain = [dlist[devName] cStringUsingEncoding:NSUTF8StringEncoding];
    }
    bool suc = ap->selectDevice(device,domain);
    if(!suc){
        NSLog(@"Failed to resolve device %s",device);
    }
    suc = ap->reverse();
    if(!suc){
        NSLog(@"Failed to establish reverse connection");
    }
    sleep(2);
    ap->playVideo("http://mac.lan:20003/2.mp4", 0);
    sleep(60);
    ap->stop();
    sleep(1);
    ap->disconnect();
}

@end
