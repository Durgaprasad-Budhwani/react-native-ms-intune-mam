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

#import "ADAuthenticationRequest.h"
#import "ADAuthenticationContext+Internal.h"
#import "ADTokenCacheItem+Internal.h"
#import "ADAuthorityValidation.h"
#import "ADHelpers.h"
#import "ADUserIdentifier.h"
#import "ADTokenCacheKey.h"
#import "ADAcquireTokenSilentHandler.h"
#import "ADTelemetry.h"
#import "ADTelemetry+Internal.h"
#import "ADTelemetryAPIEvent.h"
#import "ADTelemetryBrokerEvent.h"
#import "ADTelemetryEventStrings.h"
#import "ADBrokerHelper.h"

@implementation ADAuthenticationRequest (AcquireToken)

#pragma mark -
#pragma mark AcquireToken

- (void)acquireToken:(NSString *)apiId
     completionBlock:(ADAuthenticationCallback)completionBlock
{
    THROW_ON_NIL_ARGUMENT(completionBlock);
    [[ADTelemetry sharedInstance] startEvent:self.telemetryRequestId
                                   eventName:AD_TELEMETRY_EVENT_API_EVENT];
    
    AD_REQUEST_CHECK_ARGUMENT([_requestParams resource]);
    [self ensureRequest];
    NSString* telemetryRequestId = [_requestParams telemetryRequestId];
    
    __block NSString* log = [NSString stringWithFormat:@"##### BEGIN acquireToken%@ (authority = %@, resource = %@, clientId = %@, idtype = %@) #####",
                             _silent ? @"Silent" : @"", _requestParams.authority, _requestParams.resource, _requestParams.clientId, [_requestParams.identifier typeAsString]];
    AD_LOG_INFO_F(log, _requestParams.correlationId, @"userId = %@", _requestParams.identifier.userId);
    
    ADAuthenticationCallback wrappedCallback = ^void(ADAuthenticationResult* result)
    {
        NSString* finalLog = nil;
        if (result.status == AD_SUCCEEDED)
        {
            finalLog = [NSString stringWithFormat:@"##### END %@ succeeded. #####", log];
        }
        else
        {
            ADAuthenticationError* error = result.error;
            finalLog = [NSString stringWithFormat:@"##### END %@ failed { domain: %@ code: %ld protocolCode: %@ errorDetails: %@} #####",
                        log, error.domain, (long)error.code, error.protocolCode, error.errorDetails];
        }
        
        
        AD_LOG_INFO(finalLog, result.correlationId, nil);
        
        ADTelemetryAPIEvent* event = [[ADTelemetryAPIEvent alloc] initWithName:AD_TELEMETRY_EVENT_API_EVENT
                                                                       context:self];
        [event setApiId:apiId];
        
        [event setCorrelationId:self.correlationId];
        [event setClientId:_requestParams.clientId];
        [event setAuthority:_context.authority];
        [event setExtendedExpiresOnSetting:[_requestParams extendedLifetime]? AD_TELEMETRY_VALUE_YES:AD_TELEMETRY_VALUE_NO];
        [event setPromptBehavior:_promptBehavior];
        if ([result tokenCacheItem])
        {
            [event setUserInformation:result.tokenCacheItem.userInformation];
        }
        else
        {
            [event setUserId:_requestParams.identifier.userId];
        }
        [event setResultStatus:result.status];
        [event setIsExtendedLifeTimeToken:[result extendedLifeTimeToken]? AD_TELEMETRY_VALUE_YES:AD_TELEMETRY_VALUE_NO];
        [event setErrorCode:[NSString stringWithFormat:@"%ld",(long)[result.error code]]];
        [event setErrorDomain:[result.error domain]];
        [event setProtocolCode:[[result error] protocolCode]];
        
        [[ADTelemetry sharedInstance] stopEvent:self.telemetryRequestId event:event];
        //flush all events in the end of the acquireToken call
        [[ADTelemetry sharedInstance] flush:self.telemetryRequestId];
        
        completionBlock(result);
    };
    
    if (!_silent && ![NSThread isMainThread])
    {
        ADAuthenticationError* error =
        [ADAuthenticationError errorFromAuthenticationError:AD_ERROR_UI_NOT_ON_MAIN_THREAD
                                               protocolCode:nil
                                               errorDetails:@"Interactive authentication requests must originate from the main thread"
                                              correlationId:_requestParams.correlationId];
        
        wrappedCallback([ADAuthenticationResult resultFromError:error correlationId:_requestParams.correlationId]);
        return;
    }
    
    if (![self checkExtraQueryParameters])
    {
        ADAuthenticationError* error =
        [ADAuthenticationError errorFromAuthenticationError:AD_ERROR_DEVELOPER_INVALID_ARGUMENT
                                               protocolCode:nil
                                               errorDetails:@"extraQueryParameters is not properly encoded. Please make sure it is URL encoded."
                                              correlationId:_requestParams.correlationId];
        wrappedCallback([ADAuthenticationResult resultFromError:error correlationId:_requestParams.correlationId]);
        return;
    }
    
    if (!_silent && _context.credentialsType == AD_CREDENTIALS_AUTO && ![ADAuthenticationRequest validBrokerRedirectUri:_requestParams.redirectUri])
    {
        ADAuthenticationError* error =
        [ADAuthenticationError errorFromAuthenticationError:AD_ERROR_TOKENBROKER_INVALID_REDIRECT_URI
                                               protocolCode:nil
                                               errorDetails:ADRedirectUriInvalidError
                                              correlationId:_requestParams.correlationId];
        wrappedCallback([ADAuthenticationResult resultFromError:error correlationId:_requestParams.correlationId]);
        return;
    }
    
    if (!_context.validateAuthority)
    {
        [self validatedAcquireToken:wrappedCallback];
        return;
    }
    
    [[ADTelemetry sharedInstance] startEvent:telemetryRequestId eventName:AD_TELEMETRY_EVENT_AUTHORITY_VALIDATION];
    
    ADAuthorityValidation* authorityValidation = [ADAuthorityValidation sharedInstance];
    [authorityValidation validateAuthority:_requestParams
                           completionBlock:^(BOOL validated, ADAuthenticationError *error)
     {
         ADTelemetryAPIEvent* event = [[ADTelemetryAPIEvent alloc] initWithName:AD_TELEMETRY_EVENT_AUTHORITY_VALIDATION
                                                                        context:_requestParams];
         [event setAuthorityValidationStatus:validated ? AD_TELEMETRY_VALUE_YES:AD_TELEMETRY_VALUE_NO];
         [event setAuthority:_context.authority];
         [[ADTelemetry sharedInstance] stopEvent:telemetryRequestId event:event];
         if (error)
         {
             wrappedCallback([ADAuthenticationResult resultFromError:error correlationId:_requestParams.correlationId]);
         }
         else
         {
             [self validatedAcquireToken:wrappedCallback];
         }
     }];
    
}

- (BOOL)checkExtraQueryParameters
{
    if ([NSString adIsStringNilOrBlank:_queryParams])
    {
        return YES;
    }
    
    NSString* queryParams = _queryParams.adTrimmedString;
    if ([queryParams hasPrefix:@"&"])
    {
        queryParams = [queryParams substringFromIndex:1];
    }
    NSURL* url = [NSURL URLWithString:[NSMutableString stringWithFormat:@"%@?%@", _context.authority, queryParams]];
    
    return url!=nil;
}

- (void)validatedAcquireToken:(ADAuthenticationCallback)completionBlock
{
    [self ensureRequest];
    
    if (![ADAuthenticationContext isForcedAuthorization:_promptBehavior] && [_context hasCacheStore])
    {
        [[ADTelemetry sharedInstance] startEvent:[self telemetryRequestId] eventName:AD_TELEMETRY_EVENT_ACQUIRE_TOKEN_SILENT];
        ADAcquireTokenSilentHandler* request = [ADAcquireTokenSilentHandler requestWithParams:_requestParams];
        [request getToken:^(ADAuthenticationResult *result)
        {
            ADTelemetryAPIEvent* event = [[ADTelemetryAPIEvent alloc] initWithName:AD_TELEMETRY_EVENT_ACQUIRE_TOKEN_SILENT
                                                                           context:_requestParams];
            [[ADTelemetry sharedInstance] stopEvent:[self telemetryRequestId] event:event];
            if ([ADAuthenticationContext isFinalResult:result])
            {
                completionBlock(result);
                return;
            }
            
            _underlyingError = result.error;
            
            [self requestToken:completionBlock];
        }];
        return;
    }
    
    [self requestToken:completionBlock];
}

- (void)requestToken:(ADAuthenticationCallback)completionBlock
{
    [self ensureRequest];
    NSUUID* correlationId = [_requestParams correlationId];
    
    if (_samlAssertion)
    {
        [self requestTokenByAssertion:completionBlock];
        return;
    }

    if (_silent && !_allowSilent)
    {
        //The cache lookup and refresh token attempt have been unsuccessful,
        //so credentials are needed to get an access token, but the developer, requested
        //no UI to be shown:
        NSDictionary* underlyingError = _underlyingError ? @{NSUnderlyingErrorKey:_underlyingError} : nil;
        ADAuthenticationError* error =
        [ADAuthenticationError errorFromAuthenticationError:AD_ERROR_SERVER_USER_INPUT_NEEDED
                                               protocolCode:nil
                                               errorDetails:ADCredentialsNeeded
                                                   userInfo:underlyingError
                                              correlationId:correlationId];
        
        ADAuthenticationResult* result = [ADAuthenticationResult resultFromError:error correlationId:correlationId];
        completionBlock(result);
        return;
    }
    
    //can't pop UI or go to broker in an extension
    if ([[[NSBundle mainBundle] bundlePath] hasSuffix:@".appex"])
    {
        // This is an app extension. Return an error unless a webview is specified by the
        // extension and embedded auth is being used.
        BOOL isEmbeddedWebView = (nil != _context.webView) && (AD_CREDENTIALS_EMBEDDED == _context.credentialsType);
        if (!isEmbeddedWebView)
        {
            ADAuthenticationError* error =
            [ADAuthenticationError errorFromAuthenticationError:AD_ERROR_UI_NOT_SUPPORTED_IN_APP_EXTENSION
                                                   protocolCode:nil
                                                   errorDetails:ADInteractionNotSupportedInExtension
                                                  correlationId:correlationId];
            ADAuthenticationResult* result = [ADAuthenticationResult resultFromError:error correlationId:correlationId];
            completionBlock(result);
            return;
        }
    }
    
    if (![self takeExclusionLock:completionBlock])
    {
        return;
    }
    
    [self requestTokenImpl:^(ADAuthenticationResult *result)
    {
        [ADAuthenticationRequest releaseExclusionLock];
        completionBlock(result);
    }];
}

- (void)requestTokenImpl:(ADAuthenticationCallback)completionBlock
{
#if !AD_BROKER && TARGET_OS_IPHONE
    //call the broker.
    if ([self canUseBroker])
    {
        ADAuthenticationError* error = nil;
        NSURL* brokerURL = [self composeBrokerRequest:&error];
        if (!brokerURL)
        {
            completionBlock([ADAuthenticationResult resultFromError:error correlationId:_requestParams.correlationId]);
            return;
        }
        
        [[ADTelemetry sharedInstance] startEvent:[self telemetryRequestId] eventName:AD_TELEMETRY_EVENT_LAUNCH_BROKER];
        [ADBrokerHelper invokeBroker:brokerURL completionHandler:^(ADAuthenticationResult* result)
         {
             ADTelemetryBrokerEvent* event = [[ADTelemetryBrokerEvent alloc] initWithName:AD_TELEMETRY_EVENT_LAUNCH_BROKER
                                                                                requestId:_requestParams.telemetryRequestId
                                                                            correlationId:_requestParams.correlationId];
             [event setResultStatus:[result status]];
             [event setBrokerAppVersion:s_brokerAppVersion];
             [event setBrokerProtocolVersion:s_brokerProtocolVersion];
             [[ADTelemetry sharedInstance] stopEvent:[self telemetryRequestId] event:event];
             completionBlock(result);
         }];
        return;
    }
#endif
    
    __block BOOL silentRequest = _allowSilent;
    
    NSString* telemetryRequestId = [_requestParams telemetryRequestId];
    
// Get the code first:
    [[ADTelemetry sharedInstance] startEvent:telemetryRequestId eventName:AD_TELEMETRY_EVENT_AUTHORIZATION_CODE];
    [self requestCode:^(NSString * code, ADAuthenticationError *error)
     {
         ADTelemetryAPIEvent* event = [[ADTelemetryAPIEvent alloc] initWithName:AD_TELEMETRY_EVENT_AUTHORIZATION_CODE
                                                                        context:_requestParams];

         if (error)
         {
             if (silentRequest)
             {
                 _allowSilent = NO;
                 [self requestToken:completionBlock];
                 return;
             }
             
             ADAuthenticationResult* result = (AD_ERROR_UI_USER_CANCEL == error.code) ? [ADAuthenticationResult resultFromCancellation:_requestParams.correlationId]
             : [ADAuthenticationResult resultFromError:error correlationId:_requestParams.correlationId];
             [event setAPIStatus:(AD_ERROR_UI_USER_CANCEL == error.code) ? AD_TELEMETRY_VALUE_CANCELLED:AD_TELEMETRY_VALUE_FAILED];
             [[ADTelemetry sharedInstance] stopEvent:_requestParams.telemetryRequestId event:event];
             completionBlock(result);
         }
         else
         {
#if TARGET_OS_IPHONE
             if([code hasPrefix:@"msauth://"])
             {
                 [event setAPIStatus:@"try to prompt to install broker"];
                 [[ADTelemetry sharedInstance] stopEvent:_requestParams.telemetryRequestId event:event];
                 
                 ADAuthenticationError* error = nil;
                 NSURL* brokerRequestURL = [self composeBrokerRequest:&error];
                 if (!brokerRequestURL)
                 {
                     completionBlock([ADAuthenticationResult resultFromError:error correlationId:_requestParams.correlationId]);
                     return;
                 }
                 
                 [ADBrokerHelper promptBrokerInstall:[NSURL URLWithString:code]
                                       brokerRequest:brokerRequestURL
                                   completionHandler:completionBlock];
                 return;
             }
             else
#endif
             {
                 [event setAPIStatus:AD_TELEMETRY_VALUE_SUCCEEDED];
                 [[ADTelemetry sharedInstance] stopEvent:_requestParams.telemetryRequestId event:event];
                 
                 [[ADTelemetry sharedInstance] startEvent:_requestParams.telemetryRequestId eventName:AD_TELEMETRY_EVENT_TOKEN_GRANT];
                 [self requestTokenByCode:code
                          completionBlock:^(ADAuthenticationResult *result)
                  {
                      ADTelemetryAPIEvent* event = [[ADTelemetryAPIEvent alloc] initWithName:AD_TELEMETRY_EVENT_TOKEN_GRANT
                                                                                     context:_requestParams];
                      [event setGrantType:AD_TELEMETRY_VALUE_BY_CODE];
                      [event setResultStatus:[result status]];
                      [[ADTelemetry sharedInstance] stopEvent:_requestParams.telemetryRequestId event:event];
                      if (AD_SUCCEEDED == result.status)
                      {
                          [[_requestParams tokenCache] updateCacheToResult:result
                                                                 cacheItem:nil
                                                              refreshToken:nil
                                                                   context:_requestParams];
                          result = [ADAuthenticationContext updateResult:result toUser:[_requestParams identifier]];
                      }
                      completionBlock(result);
                  }];
             }
         }
     }];
}

// Generic OAuth2 Authorization Request, obtains a token from an authorization code.
- (void)requestTokenByCode:(NSString *)code
           completionBlock:(ADAuthenticationCallback)completionBlock
{
    HANDLE_ARGUMENT(code, [_requestParams correlationId]);
    [self ensureRequest];
    AD_LOG_VERBOSE_F(@"Requesting token from authorization code.", [_requestParams correlationId], @"Requesting token by authorization code for resource: %@", [_requestParams resource]);
    
    //Fill the data for the token refreshing:
    NSMutableDictionary *request_data = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                         OAUTH2_AUTHORIZATION_CODE, OAUTH2_GRANT_TYPE,
                                         code, OAUTH2_CODE,
                                         [_requestParams clientId], OAUTH2_CLIENT_ID,
                                         [_requestParams redirectUri], OAUTH2_REDIRECT_URI,
                                         nil];
    if (![NSString adIsStringNilOrBlank:_scope])
    {
        [request_data setValue:_scope forKey:OAUTH2_SCOPE];
    }
    
    [self executeRequest:request_data
              completion:completionBlock];
}

@end
