//
//  NSBundle+OBCodeSigningInfo.m
//
//  Created by Ole Begemann on 22.02.12.
//  Copyright (c) 2012 Ole Begemann. All rights reserved.
//

#import "NSBundle+OBCodeSigningInfo.h"
#import <Security/SecRequirement.h>
#import <objc/runtime.h>


@interface NSBundle (OBCodeSigningInfoPrivateMethods)
- (SecStaticCodeRef)ob_createStaticCode;
- (SecRequirementRef)ob_sandboxRequirement;
@end


@implementation NSBundle (OBCodeSigningInfo)

- (BOOL)ob_comesFromAppStore
{
    // Check existence of Mac App Store receipt
    NSURL *appStoreReceiptURL = [self appStoreReceiptURL];
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    BOOL appStoreReceiptExists = [fileManager fileExistsAtPath:[appStoreReceiptURL path]];
    return appStoreReceiptExists;
}


- (BOOL)ob_isSandboxed
{
    BOOL isSandboxed = NO;
    if ([self ob_codeSignState] == OBCodeSignStateSignatureValid)
    {
        SecStaticCodeRef staticCode = [self ob_createStaticCode];
        SecRequirementRef sandboxRequirement = [self ob_sandboxRequirement];
        if (staticCode && sandboxRequirement) {
            OSStatus codeCheckResult = SecStaticCodeCheckValidityWithErrors(staticCode, kSecCSBasicValidateOnly, sandboxRequirement, NULL);
            if (codeCheckResult == errSecSuccess) {
                isSandboxed = YES;
            }
            CFRelease(staticCode);
        }
    }
    return isSandboxed;
}


- (OBCodeSignState)ob_codeSignState
{
    // Return cached value if it exists
    static const void *kOBCodeSignStateKey;
    NSNumber *resultStateNumber = objc_getAssociatedObject(self, kOBCodeSignStateKey);
    if (resultStateNumber) {
        return (int)[resultStateNumber integerValue];
    }
    
    // Determine code sign status
    OBCodeSignState resultState = OBCodeSignStateError;
    SecStaticCodeRef staticCode = [self ob_createStaticCode];
    if (staticCode)
    {
        OSStatus signatureCheckResult = SecStaticCodeCheckValidityWithErrors(staticCode, kSecCSBasicValidateOnly, NULL, NULL);
        switch (signatureCheckResult) {
            case errSecSuccess: resultState = OBCodeSignStateSignatureValid; break;
            case errSecCSUnsigned: resultState = OBCodeSignStateUnsigned; break;
            case errSecCSSignatureFailed:
            case errSecCSSignatureInvalid:
                resultState = OBCodeSignStateSignatureInvalid;
                break;
            case errSecCSSignatureNotVerifiable: resultState = OBCodeSignStateSignatureNotVerifiable; break;
            case errSecCSSignatureUnsupported: resultState = OBCodeSignStateSignatureUnsupported; break;
            default: resultState = OBCodeSignStateError; break;
        }
        CFRelease(staticCode);
    }
    else
    {
        resultState = OBCodeSignStateError;
    }
    
    // Cache the result
    resultStateNumber = [NSNumber numberWithInteger:resultState];
    objc_setAssociatedObject(self, kOBCodeSignStateKey, resultStateNumber, OBJC_ASSOCIATION_RETAIN);
    
    return resultState;
}


#pragma mark - Private helper methods

- (SecStaticCodeRef)ob_createStaticCode
{
    NSURL *bundleURL = [self bundleURL];
    SecStaticCodeRef staticCode = NULL;
    SecStaticCodeCreateWithPath((__bridge CFURLRef)bundleURL, kSecCSDefaultFlags, &staticCode);
    return staticCode;
}

- (SecRequirementRef)ob_sandboxRequirement
{
    static SecRequirementRef sandboxRequirement = NULL;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SecRequirementCreateWithString(CFSTR("entitlement[\"com.apple.security.app-sandbox\"] exists"), kSecCSDefaultFlags, &sandboxRequirement);
    });
    return sandboxRequirement;
}

@end