//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//

typedef NS_ENUM(NSUInteger, IntuneMAMEnrollmentStatusCode)
{
    // 1xx - Success Codes
    IntuneMAMEnrollmentStatusNewPoliciesReceived = 100,             // Policy request sucess and new policies were retrieved
    IntuneMAMEnrollmentStatusPoliciesHaveNotChanged = 101,          // Policy request sucess, but policies have not changed since last request
    IntuneMAMEnrollmentStatusWipeReceived = 102,                    // Policy request success and a selective wipe command was received
    IntuneMAMEnrollmentStatusNoPolicyReceived = 103,                // Policy request sucess, but no policy was targeted to the user
    IntuneMAMEnrollmentStatusUnenrollmentSuccess = 104,             // Successfully un-enrolled the user and de-registered the account with the SDK
    
    // 2xx - Failure Codes
    IntuneMAMEnrollmentStatusAccountNotLicensed = 200,              // The user's tenant is enabled for MAM, but the user is not licensed
    IntuneMAMEnrollmentStatusInternalError = 201,                   // Internal error, see error object for details
    IntuneMAMEnrollmentStatusMamServiceDisabled = 202,              // The MAM Service is disabled in the application's info.plist
    IntuneMAMEnrollmentStatusAuthRequired = 203,                    // Operation failed because the SDK could not access the user's AAD token because the users credentials are needed
    IntuneMAMEnrollmentStatusLocationServiceFailure = 204,          // Failed to connect to the location service to determine the user's endpoint, see error object for details
    IntuneMAMEnrollmentStatusEnrollmentEndPointNetworkFailure = 205,// Failed to connect to the enrollment endpoint, see error object for details
    IntuneMAMEnrollmentStatusParsingFailure = 206,                  // Failed to parse the service's response
    IntuneMAMEnrollmentStatusNilAccount = 207,                      // Nil identity was passed to SDK
    IntuneMAMEnrollmentStatusAlreadyEnrolled = 208,                 // Operation failed because the application is already enrolled
    IntuneMAMEnrollmentStatusNotEmmAccount = 209,                   // Operation failed because the SDK is expecting a specific account provided by the 3rd party EMM
    IntuneMAMEnrollmentStatusMdmEnrolledDifferentUser = 210,        // Operation failed because the device is MDM enrolled under a different account
    IntuneMAMEnrollmentStatusNotDeviceAccount = 211,                // Operation failed because the provided identity does not match the device account
    IntuneMAMEnrollmentStatusPolicyEndPointNetworkFailure = 212,    // Failed to connect to the policy endpoint, see error object for details
    IntuneMAMEnrollmentStatusAppNotEnrolled = 213,                  // Operation failed because the appliction is not enrolled
    IntuneMAMEnrollmentStatusNotEnrolledAccount = 214,              // Operation failed because the provided account does not match the currently enrolled account
    IntuneMAMEnrollmentStatusFailedToClearMamData = 215,            // Failed to clear the account's data from the SDK
    IntuneMAMEnrollmentStatusTimeout = 216,                         // The operation has timed out
    IntuneMAMEnrollmentStatusADALInternalError = 217,               // Generic error returned by ADAL when trying to acquire the user's MAM Token
    IntuneMAMEnrollmentStatusSwitchExistingAccount = 218,           // The operation has failed because the existing enrolled account will be removed first
    IntuneMAMEnrollmentStatusLoginCanceled = 219,                   // The user canceled the login prompt for loginAndEnrollAccount
    IntuneMAMEnrollmentStatusPolicyRecordGone = 220,                // Operation failed because we recieved a Gone response from the service
    IntuneMAMEnrollmentStatusReEnrollForUnenrolledUser = 221        // Operation failed because reenrolls can only be processed if the same user is still enrolled in the app.
};

/**
 *  An IntuneMAMEnrollmentStatus object will be returned as a
 *  parameter in the methods defined in IntuneMAMEnrollmentDelegate.h
 */
@interface IntuneMAMEnrollmentStatus : NSObject

/**
 *  The UPN of the account for which the operation was requested
 */
@property (nonatomic, strong) NSString *identity;

/**
 *  YES if the operation completed successfully, otherwise NO
 */
@property (nonatomic) BOOL didSucceed;

/**
 *  The resulting status code for the completed operation.  This status
 *  code can provide further details about a successful operation or
 *  reason for an operation's failure.
 */
@property (nonatomic) IntuneMAMEnrollmentStatusCode statusCode;

/**
 *  A string with debug information for the completed operation
 */
@property (nonatomic, strong) NSString *errorString;

/**
 *  Associated error object for the completed operation.  Could be nil.
 */
@property (nonatomic, strong) NSError *error;

@end
