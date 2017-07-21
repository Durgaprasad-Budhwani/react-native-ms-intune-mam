// Copyright (c) Microsoft Corporation.
// All rights reserved.
//
// This code is licensed under the MIT License.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files(the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and / or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions :
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "ADPkeyAuthHelper.h"
#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonDigest.h>
#import "ADRegistrationInformation.h"
#import "NSString+ADHelperMethods.h"
#import "ADWorkPlaceJoinUtil.h"
#import "ADLogger+Internal.h"
#import "ADErrorCodes.h"
#import "ADJwtHelper.h"

@implementation ADPkeyAuthHelper

+ (nonnull NSString*) computeThumbprint:(nonnull NSData*) data{
    return [ADPkeyAuthHelper computeThumbprint:data isSha2:NO];
}


+ (nonnull NSString*) computeThumbprint:(nonnull NSData*) data isSha2:(BOOL) isSha2{
    
    //compute SHA-1 thumbprint
    int length = CC_SHA1_DIGEST_LENGTH;
    if(isSha2){
        length = CC_SHA256_DIGEST_LENGTH;
    }
    
    unsigned char dataBuffer[length];
    if(!isSha2){
        CC_SHA1(data.bytes, (CC_LONG)data.length, dataBuffer);
    }
    else{
        CC_SHA256(data.bytes, (CC_LONG)data.length, dataBuffer);
    }
    
    NSMutableString *fingerprint = [NSMutableString stringWithCapacity:length * 3];
    for (int i = 0; i < length; ++i)
    {
        [fingerprint appendFormat:@"%02x ",dataBuffer[i]];
    }
    
    NSString* thumbprint = [fingerprint stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    thumbprint = [thumbprint uppercaseString];
    return [thumbprint stringByReplacingOccurrencesOfString:@" " withString:@""];
}


+ (nullable NSString*)createDeviceAuthResponse:(nonnull NSString*)authorizationServer
                                challengeData:(nullable NSDictionary*)challengeData
                                correlationId:(nullable NSUUID *)correlationId
                                        error:(ADAuthenticationError * __nullable __autoreleasing * __nullable)error
{
    ADAuthenticationError* adError = nil;
    ADRegistrationInformation *info =
    [ADWorkPlaceJoinUtil getRegistrationInformation:correlationId
                                              error:&adError];
    
    if (!info && adError)
    {
        // If some error ocurred other then "I found nothing in the keychain" we want to short circuit out of
        // the rest of the code, but if there was no error, we still create a response header, even if we
        // don't have registration info
        AD_LOG_ERROR(@"Failed to create PKeyAuth request.", adError.code, correlationId, nil);
        
        if (error)
        {
            *error = adError;
        }
        return nil;
    }
    
    
    if (!challengeData)
    {
        // Error should have been logged before this where there is more information on why the challenge data was bad
    }
    else if (![info isWorkPlaceJoined])
    {
        AD_LOG_INFO(@"PKeyAuth: Received PKeyAuth request but no WPJ info.", nil, nil);
    }
    else
    {
        NSString* certAuths = [challengeData valueForKey:@"CertAuthorities"];
        NSString* expectedThumbprint = [challengeData valueForKey:@"CertThumbprint"];
        
        if (certAuths)
        {
            NSString* issuerOU = [ADPkeyAuthHelper getOrgUnitFromIssuer:[info certificateIssuer]];
            if (![self isValidIssuer:certAuths keychainCertIssuer:issuerOU])
            {
                AD_LOG_ERROR(@"PKeyAuth Error: Certificate Authority specified by device auth request does not match certificate in keychain.", AD_ERROR_SERVER_WPJ_REQUIRED, nil, nil);
                info = nil;
            }
        }
        else if (expectedThumbprint)
        {
            if (![expectedThumbprint isEqualToString:[ADPkeyAuthHelper computeThumbprint:[info certificateData]]])
            {
                AD_LOG_ERROR(@"PKeyAuth Error: Certificate Thumbprint does not match certificate in keychain.", AD_ERROR_SERVER_WPJ_REQUIRED, nil, nil);
                info = nil;
            }
        }
    }
    
    NSString* pKeyAuthHeader = @"";
    if (info)
    {
        pKeyAuthHeader = [NSString stringWithFormat:@"AuthToken=\"%@\",", [ADPkeyAuthHelper createDeviceAuthResponse:authorizationServer nonce:[challengeData valueForKey:@"nonce"] identity:info]];
        AD_LOG_INFO(@"Found WPJ Info and responded to PKeyAuth Request", correlationId, nil);
        info = nil;
    }
    
    
    
    return [NSString stringWithFormat:@"PKeyAuth %@ Context=\"%@\", Version=\"%@\"", pKeyAuthHeader,[challengeData valueForKey:@"Context"],  [challengeData valueForKey:@"Version"]];
}


+ (NSString*)getOrgUnitFromIssuer:(NSString*)issuer
{
    NSString *regexString = @"[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}";
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexString options:0 error:NULL];
    
    for (NSTextCheckingResult* myMatch in [regex matchesInString:issuer options:0 range:NSMakeRange(0, [issuer length])]){
        if (myMatch.numberOfRanges > 0) {
            NSRange matchedRange = [myMatch rangeAtIndex: 0];
            return [NSString stringWithFormat:@"OU=%@", [issuer substringWithRange: matchedRange]];
        }
    }
    
    return nil;
}

+ (BOOL)isValidIssuer:(NSString *)certAuths
   keychainCertIssuer:(NSString *)keychainCertIssuer
{
    NSString *regexString = @"OU=[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}";
    keychainCertIssuer = [keychainCertIssuer uppercaseString];
    certAuths = [certAuths uppercaseString];
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexString options:0 error:NULL];
    
    for (NSTextCheckingResult* myMatch in [regex matchesInString:certAuths options:0 range:NSMakeRange(0, [certAuths length])]){
        for (NSUInteger i = 0; i < myMatch.numberOfRanges; ++i)
        {
            NSRange matchedRange = [myMatch rangeAtIndex: i];
            NSString *text = [certAuths substringWithRange:matchedRange];
            if ([text isEqualToString:keychainCertIssuer]){
                return true;
            }
        }
    }
    
    return false;
}

+ (NSString *)createDeviceAuthResponse:(NSString *)audience
                                 nonce:(NSString *)nonce
                              identity:(ADRegistrationInformation *)identity
{
    if (!audience || !nonce)
    {
        AD_LOG_ERROR(@"audience or nonce is nil in device auth request!", AD_ERROR_UNEXPECTED, nil, nil);
        return nil;
    }
    NSArray *arrayOfStrings = @[[NSString stringWithFormat:@"%@", [[identity certificateData] base64EncodedStringWithOptions:0]]];
    NSDictionary *header = @{
                             @"alg" : @"RS256",
                             @"typ" : @"JWT",
                             @"x5c" : arrayOfStrings
                             };
    
    NSDictionary *payload = @{
                              @"aud" : audience,
                              @"nonce" : nonce,
                              @"iat" : [NSString stringWithFormat:@"%d", (CC_LONG)[[NSDate date] timeIntervalSince1970]]
                              };
    
    return [ADJwtHelper createSignedJWTforHeader:header payload:payload signingKey:[identity privateKey]];
}

@end
