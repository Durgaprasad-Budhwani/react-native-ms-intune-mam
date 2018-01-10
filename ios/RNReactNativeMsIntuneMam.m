#import "RNReactNativeMsIntuneMam.h"
#import <IntuneMAM/IntuneMAM.h>

@interface RNReactNativeMsIntuneMam ()<IntuneMAMPolicyDelegate>

@property (nonatomic,weak) id<IntuneMAMPolicyDelegate> delegate;

@end

@implementation RNReactNativeMsIntuneMam

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}
RCT_EXPORT_MODULE()


/**
 *  This method will remove the provided account from the list of
 *  registered accounts.  Once removed, if the account has enrolled
 *  the application, the account will be un-enrolled.
 *
 *  @note In the case where an un-enroll is initiated, this method will block
 *  until the MAM token is acquired, then return.  This method must be called before
 *  the user is removed from the application (so that required AAD tokens are not purged
 *  before this method is called).xx
 *
 *  @param identity The UPN of the account to be removed.
 *  @param doWipe   If YES, a selective wipe if the account is un-enrolled
 *  @param resolve - if request is successful
 *  @param reject - if request is failed
 */
RCT_REMAP_METHOD(deRegisterAndUnenrollAccount,
                 identity:(NSString *)identity
                 withWipe:(BOOL)doWipe
                 resolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject ){
    @try{
        IntuneMAMEnrollmentManager* intuneMAMEnrollmentManager = [IntuneMAMEnrollmentManager instance];
        [intuneMAMEnrollmentManager deRegisterAndUnenrollAccount:identity withWipe:doWipe];
        
        resolve( @"success" );
    }
    @catch(NSError *error){
        reject( [[NSString alloc] initWithFormat:@"%d", error.code], error.localizedDescription, error );
    }
    
}

/**
 *  This method will add the account to the list of registered accounts.
 *  An enrollment request will immediately be started.  If the enrollment
 *  is not successful, the SDK will periodically re-try the enrollment every
 *  24 hours.
 *  If the application has already registered an account using this API, and calls
 *  it again, the SDK will ignore the request and output a warning.
 *
 *  @param identity The UPN of the account to be registered with the SDK
 *  @param forceLogin -  if true - Creates an enrollment request which is started immediately.
 *                       The user will be prompted to enter their credentials,
 *                       and we will attempt to enroll the user.
 *  @param resolve - if request is successful
 *  @param reject - if request is failed
 */

RCT_REMAP_METHOD(registerAndEnrollAccount,
                 identity:(NSString *)identity
                 forceLogin:(BOOL) forceLogin
                 resolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject ){
    @try{
        IntuneMAMEnrollmentManager* intuneMAMEnrollmentManager = [IntuneMAMEnrollmentManager instance];
        [self.delegate restartApplication];
        if(forceLogin){
            [intuneMAMEnrollmentManager loginAndEnrollAccount:identity];
        }
        else{
            [intuneMAMEnrollmentManager registerAndEnrollAccount:identity];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            @try{
                IntuneMAMPolicyManager* policyManager = [IntuneMAMPolicyManager instance];
                NSString* primaryUser = [policyManager primaryUser];
                [policyManager setProcessIdentity:identity];
                NSString* uiIdentity = [policyManager getUIPolicyIdentity];
                [policyManager setUIPolicyIdentity:identity
                                 completionHandler:^(IntuneMAMSwitchIdentityResult result) {
                                     
                                     resolve( @"success" );
                                 }];
                
                NSDate* date = [NSDate date];
                IntuneMAMAppConfigManager* configManager = [IntuneMAMAppConfigManager instance];
                NSArray<NSDictionary*>* configurations;
                while (TRUE)
                {
                    
                    NSArray<NSDictionary*>* configurations = [[configManager appConfigForIdentity:identity] fullData];
                    
                    if (configurations)
                    {
                        // the condition is reached
                        break;
                    }
                    
                    if ([date timeIntervalSinceNow] < -10)
                    {
                        // the condition is not reached before timeout
                        break;
                    }
                    
                    // adapt this value in microseconds.
                    usleep(10000);
                }
                if(configurations){
                    resolve( @"success" );
                }
                else{
                    NSError *err = [NSError errorWithDomain:@"INTUNE"
                                                       code:100
                                                   userInfo:@{
                                                              NSLocalizedDescriptionKey:@"Please restart application"
                                                              }];
                    @throw err;
                }
            }
            @catch(NSError *error){
                reject( [[NSString alloc] initWithFormat:@"%d", error.code], error.localizedDescription, error );
            }
        });
        

        
    }
    @catch(NSError *error){
        reject( [[NSString alloc] initWithFormat:@"%d", error.code], error.localizedDescription, error );
    }
}

/**
 *  Returns a list of UPNs of account currently registered with the SDK.
 *
 *  @return Array containing UPNs of registered accounts
 */
RCT_REMAP_METHOD(getRegisteredAccounts,
                 resolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject ){
    @try{
        IntuneMAMEnrollmentManager* intuneMAMEnrollmentManager = [IntuneMAMEnrollmentManager instance];
        NSArray* accounts = [intuneMAMEnrollmentManager registeredAccounts];
        resolve(accounts);
    }
    @catch(NSError *error){
        reject( [[NSString alloc] initWithFormat:@"%d", error.code], error.localizedDescription, error );
    }
}

/**
 *  Returns the UPN of the currently enrolled user.  Returns
 *  nil if the application is not currently enrolled.
 *
 *  @return UPN of the enrolled account
 */
RCT_REMAP_METHOD(getCurrentEnrolledAccount,
                 resolve:(RCTPromiseResolveBlock)resolve
                 reject:(RCTPromiseRejectBlock)reject ){
    @try{
        IntuneMAMEnrollmentManager* intuneMAMEnrollmentManager = [IntuneMAMEnrollmentManager instance];
        NSString* account = [intuneMAMEnrollmentManager enrolledAccount];
        resolve(account);
    }
    @catch(NSError *error){
        reject( [[NSString alloc] initWithFormat:@"%d", error.code], error.localizedDescription, error );
    }
}

/**
 *  An array of Dictionaries containing all the AppConfig data sent
 *  by the MAM service.  If a configuration Dictionary was sent as
 *  a tenant wide default configuration, the __IsDefault key will be
 *  present in that dictionary and the value for that key will be set
 *  to true.  The __IsDefault key will only be present in the Dictionary
 *  representing the tenant wide default configuration.  All other
 *  configuration dictionaries will contain targeted policies, and
 *  these targeted App Configuration settings should always take
 *  precedence over the tenant wide default configuration settings.
 */
RCT_REMAP_METHOD(getAppConfiguration,
                 identity:(NSString *)identity
                 resolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject ){
    @try{
        if(!identity){
            IntuneMAMPolicyManager* policyManager = [IntuneMAMPolicyManager instance];
            identity = [policyManager primaryUser];
        }
        IntuneMAMAppConfigManager* configManager = [IntuneMAMAppConfigManager instance];
        NSArray<NSDictionary*>* configurations = [[configManager appConfigForIdentity:identity] fullData];
        resolve(configurations);
    }
    @catch(NSError *error){
        reject( [[NSString alloc] initWithFormat:@"%d", error.code], error.localizedDescription, error );
    }
}

@end
