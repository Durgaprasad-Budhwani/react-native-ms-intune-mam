
#import "RNReactNativeMsIntuneMam.h"
#import <IntuneMAM/IntuneMAM.h>

@implementation RNReactNativeMsIntuneMam

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}
RCT_EXPORT_MODULE()

RCT_REMAP_METHOD(deRegisterAndUnenrollAccount,
                 identity:(NSString *)identity
                 withWipe:(BOOL)doWipe
                 resolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject ){
    @try{
        IntuneMAMEnrollmentManager* intuneMAMEnrollmentManager = [IntuneMAMEnrollmentManager instance];
        [intuneMAMEnrollmentManager deRegisterAndUnenrollAccount:identity withWipe:NO];

        resolve( @"success" );
    }
    @catch(NSError *error){
        reject( [[NSString alloc] initWithFormat:@"%d", error.code], error.localizedDescription, error );
    }

}

RCT_REMAP_METHOD(registerAndEnrollAccount,
                 identity:(NSString *)identity
                 forceLogin:(BOOL) forceLogin
                 resolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject ){
    @try{
        IntuneMAMEnrollmentManager* intuneMAMEnrollmentManager = [IntuneMAMEnrollmentManager instance];
        if(forceLogin){
            [intuneMAMEnrollmentManager loginAndEnrollAccount:identity];
        }
        else{
            [intuneMAMEnrollmentManager registerAndEnrollAccount:identity];
        }

        resolve( @"success" );
    }
    @catch(NSError *error){
        reject( [[NSString alloc] initWithFormat:@"%d", error.code], error.localizedDescription, error );
    }
}


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

