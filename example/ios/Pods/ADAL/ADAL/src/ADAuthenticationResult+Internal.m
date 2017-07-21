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

#import "ADAL_Internal.h"
#import "ADAuthenticationResult.h"
#import "ADAuthenticationResult+Internal.h"
#import "ADTokenCacheItem+Internal.h"
#import "ADOAuth2Constants.h"
#import "ADUserInformation.h"

@implementation ADAuthenticationResult (Internal)

- (id)initWithCancellation:(NSUUID*)correlationId
{
    ADAuthenticationError* error = [ADAuthenticationError errorFromCancellation:correlationId];
    
    return [self initWithError:error status:AD_USER_CANCELLED correlationId:correlationId];
}

-(id) initWithItem: (ADTokenCacheItem*) item
multiResourceRefreshToken: (BOOL) multiResourceRefreshToken
     correlationId: (NSUUID*) correlationId
{
    self = [super init];
    if (self)
    {
        // Non ObjC Objects
        _status = AD_SUCCEEDED;
        _multiResourceRefreshToken = multiResourceRefreshToken;
        
        // ObjC Objects
        _tokenCacheItem = item;
        _correlationId = correlationId;
    }
    return self;
}

- (id)initWithError:(ADAuthenticationError *)error
             status:(ADAuthenticationResultStatus)status
      correlationId:(NSUUID *)correlationId
{
    THROW_ON_NIL_ARGUMENT(error);
    
    self = [super init];
    if (self)
    {
        _status = status;
        _error = error;
        _correlationId = correlationId;
    }
    return self;
}

+ (ADAuthenticationResult*)resultFromTokenCacheItem:(ADTokenCacheItem *)item
                               multiResourceRefreshToken:(BOOL)multiResourceRefreshToken
                                           correlationId:(NSUUID *)correlationId
{
    if (!item)
    {
        ADAuthenticationError* error = [ADAuthenticationError unexpectedInternalError:@"ADAuthenticationResult was created with nil token item."
                                                                        correlationId:correlationId];
        return [ADAuthenticationResult resultFromError:error];
    }
    
    ADAuthenticationResult* result = [[ADAuthenticationResult alloc] initWithItem:item
                                                        multiResourceRefreshToken:multiResourceRefreshToken
                                                                    correlationId:correlationId];
    
    return result;
}

+(ADAuthenticationResult*) resultFromError: (ADAuthenticationError*) error
{
    return [self resultFromError:error correlationId:nil];
}

+(ADAuthenticationResult*) resultFromError: (ADAuthenticationError*) error
                             correlationId: (NSUUID*) correlationId
{
    ADAuthenticationResult* result = [[ADAuthenticationResult alloc] initWithError:error
                                                                            status:AD_FAILED
                                                                     correlationId:correlationId];
    
    return result;
}

+ (ADAuthenticationResult*)resultFromParameterError:(NSString *)details
{
    return [self resultFromParameterError:details correlationId:nil];
}

+ (ADAuthenticationResult*)resultFromParameterError:(NSString *)details
                                      correlationId:(NSUUID*)correlationId
{
    ADAuthenticationError* adError = [ADAuthenticationError invalidArgumentError:details correlationId:correlationId];
    ADAuthenticationResult* result = [[ADAuthenticationResult alloc] initWithError:adError
                                                                            status:AD_FAILED
                                                                     correlationId:correlationId];
    
    return result;
}

+ (ADAuthenticationResult*)resultFromCancellation
{
    return [self resultFromCancellation:nil];
}

+ (ADAuthenticationResult*)resultFromCancellation:(NSUUID *)correlationId
{
    ADAuthenticationResult* result = [[ADAuthenticationResult alloc] initWithCancellation:correlationId];
    return result;
}

+ (ADAuthenticationResult*)resultForNoBrokerResponse
{
    NSError* nsError = [NSError errorWithDomain:ADBrokerResponseErrorDomain
                                           code:AD_ERROR_TOKENBROKER_UNKNOWN
                                       userInfo:nil];
    ADAuthenticationError* error = [ADAuthenticationError errorFromNSError:nsError
                                                              errorDetails: @"No broker response received."
                                                             correlationId:nil];
    return [ADAuthenticationResult resultFromError:error correlationId:nil];
}

+ (ADAuthenticationResult*)resultForBrokerErrorResponse:(NSDictionary*)response
{
    NSUUID* correlationId = nil;
    NSString* uuidString = [response valueForKey:OAUTH2_CORRELATION_ID_RESPONSE];
    if (uuidString)
    {
        correlationId = [[NSUUID alloc] initWithUUIDString:[response valueForKey:OAUTH2_CORRELATION_ID_RESPONSE]];
    }
    
    // Otherwise parse out the error condition
    ADAuthenticationError* error = nil;
    
    NSString* errorDetails = [response valueForKey:OAUTH2_ERROR_DESCRIPTION];
    if (!errorDetails)
    {
        errorDetails = @"Broker did not provide any details";
    }
        
    NSString* strErrorCode = [response valueForKey:@"error_code"];
    NSInteger errorCode = AD_ERROR_TOKENBROKER_UNKNOWN;
    if (strErrorCode && ![strErrorCode isEqualToString:@"0"])
    {
        errorCode = [strErrorCode integerValue];
    }
    
    NSString* protocolCode = [response valueForKey:@"protocol_code"];
    if (!protocolCode)
    {
        // Older brokers used to send the protocol code as "code" and the error code not at all
        protocolCode = [response valueForKey:@"code"];
    }
    
    if (![NSString adIsStringNilOrBlank:protocolCode])
    {
       
        error = [ADAuthenticationError errorFromAuthenticationError:errorCode
                                                       protocolCode:protocolCode
                                                       errorDetails:errorDetails
                                                      correlationId:correlationId];
    }
    else
    {
        NSError* nsError = [NSError errorWithDomain:ADBrokerResponseErrorDomain
                                               code:errorCode
                                           userInfo:nil];
        error = [ADAuthenticationError errorFromNSError:nsError errorDetails:errorDetails correlationId:correlationId];
    }
    
    return [ADAuthenticationResult resultFromError:error correlationId:correlationId];

}

+ (ADAuthenticationResult *)resultFromBrokerResponse:(NSDictionary *)response
{
    if (!response)
    {
        return [self resultForNoBrokerResponse];
    }
    
    if ([response valueForKey:OAUTH2_ERROR_DESCRIPTION])
    {
        return [self resultForBrokerErrorResponse:response];
    }
    
    NSUUID* correlationId =  nil;
    NSString* correlationIdStr = [response valueForKey:OAUTH2_CORRELATION_ID_RESPONSE];
    if (correlationIdStr)
    {
        correlationId = [[NSUUID alloc] initWithUUIDString:correlationIdStr];
    }

    ADTokenCacheItem* item = [ADTokenCacheItem new];
    [item setAccessTokenType:@"Bearer"];
    BOOL isMRRT = [item fillItemWithResponse:response];
    ADAuthenticationResult* result = [[ADAuthenticationResult alloc] initWithItem:item
                                                        multiResourceRefreshToken:isMRRT
                                                                    correlationId:correlationId];
    return result;
    
}

- (void)setExtendedLifeTimeToken:(BOOL)extendedLifeTimeToken;
{
    _extendedLifeTimeToken = extendedLifeTimeToken;
}

@end
