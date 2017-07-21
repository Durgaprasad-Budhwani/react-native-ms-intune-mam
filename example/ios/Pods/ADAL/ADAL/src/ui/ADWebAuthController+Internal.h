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

@class ADAuthenticationError;

#import "ADAuthenticationContext.h"
#import "ADWebAuthController.h"

typedef void (^ADBrokerCallback)(ADAuthenticationError* error, NSURL*);
@interface ADWebAuthController (Internal)

+ (ADWebAuthController *)sharedInstance;

// Start the authentication process. Note that there are two different behaviours here dependent on whether the caller has provided
// a WebView to host the browser interface. If no WebView is provided, then a full window is launched that hosts a WebView to run
// the authentication process.
- (void)start:(NSURL *)startURL
          end:(NSURL *)endURL
  refreshCred:(NSString *)refreshCred
#if TARGET_OS_IPHONE
       parent:(UIViewController *)parent
   fullScreen:(BOOL)fullScreen
#endif
      webView:(WebViewType*)webView
      context:(ADRequestParameters*)requestParams
   completion:(ADBrokerCallback)completionBlock;

//Cancel the web authentication session which might be happening right now
//Note that it only works if there's an active web authentication session going on
- (BOOL)cancelCurrentWebAuthSessionWithError:(ADAuthenticationError *)error;

#if TARGET_OS_IPHONE
+ (void)setInterruptedBrokerResult:(ADAuthenticationResult*)result;
#endif // TARGET_OS_IPHONE

- (ADAuthenticationViewController*)viewController;

@end
