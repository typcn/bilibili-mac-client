//
//  AirPlayTests.m
//  AirPlayTests
//
//  Created by TYPCN on 2015/9/13.
//  Copyright © 2015 TYPCN. All rights reserved.
//

#import <XCTest/XCTest.h>
#include "ServiceDiscovery.hpp"

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
        SD_Wait();
        const char* serviceName = nullptr;
        const char* domain = nullptr;
        for ( const auto &pair : SD_Map) {
            serviceName = pair.first.c_str();
            domain      = pair.second.c_str();
        }
        printf("[AirPlayTest] using %s\n",serviceName);
        
        SD_Resolve(serviceName,domain);
        SD_Wait();
        
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

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
