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

#import "ADTelemetry.h"
#import "ADTelemetryUIEvent.h"
#import "ADTelemetryEventStrings.h"

@implementation ADTelemetryUIEvent

- (id)initWithName:(NSString*)eventName
         requestId:(NSString*)requestId
     correlationId:(NSUUID*)correlationId
{
    if (!(self = [super initWithName:eventName requestId:requestId correlationId:correlationId]))
    {
        return nil;
    }
    
    [self setProperty:AD_TELEMETRY_KEY_USER_CANCEL value:@""];
    [self setProperty:AD_TELEMETRY_KEY_NTLM_HANDLED value:@""];
    
    return self;
}

- (void)setLoginHint:(NSString*)hint
{
    [self setProperty:AD_TELEMETRY_KEY_LOGIN_HINT value:[hint adComputeSHA256]];
}

- (void)setNtlm:(NSString*)ntlmHandled
{
    [self setProperty:AD_TELEMETRY_KEY_NTLM_HANDLED value:ntlmHandled];
}

@end
