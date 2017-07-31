
package com.microsoft.intune.mam.plugin;

import android.app.Activity;
import android.util.Log;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.WritableMap;
import com.microsoft.intune.mam.client.MAMIdentitySwitchResult;
import com.microsoft.intune.mam.client.app.MAMComponents;
import com.microsoft.intune.mam.client.identity.MAMPolicyManager;
import com.microsoft.intune.mam.client.identity.MAMPolicyManagerBehavior;
import com.microsoft.intune.mam.client.identity.MAMSetUIIdentityCallback;
import com.microsoft.intune.mam.policy.MAMEnrollmentManager;
import com.microsoft.intune.mam.policy.MAMUserInfo;
import com.microsoft.intune.mam.policy.appconfig.MAMAppConfig;
import com.microsoft.intune.mam.policy.appconfig.MAMAppConfigManager;

import java.util.List;
import java.util.Map;

public class RNReactNativeMsIntuneMamModule extends ReactContextBaseJavaModule {

    private final ReactApplicationContext reactContext;
    private RNMAMServiceAuthenticationCallback serviceAuthenticationCallback;


    public RNReactNativeMsIntuneMamModule(ReactApplicationContext reactContext) {
        super(reactContext);
        this.reactContext = reactContext;
        MAMEnrollmentManager enrollmentManager = MAMComponents.get(MAMEnrollmentManager.class);
        if (enrollmentManager != null) {
            serviceAuthenticationCallback = new RNMAMServiceAuthenticationCallback();
            enrollmentManager.registerAuthenticationCallback(serviceAuthenticationCallback);
        }
    }

    @Override
    public String getName() {
        return "RNReactNativeMsIntuneMam";
    }

    @ReactMethod
    public void deRegisterAndUnenrollAccount(
            final String identity,
            final Promise promise) {

        try {
            MAMPolicyManagerBehavior policyManager = MAMComponents.get(MAMPolicyManagerBehavior.class);

            MAMEnrollmentManager enrollmentManager = MAMComponents.get(MAMEnrollmentManager.class);
            if (enrollmentManager != null) {
                enrollmentManager.unregisterAccountForMAM(identity);
                if (policyManager != null) {
                    MAMIdentitySwitchResult result = policyManager.setProcessIdentity("");
                    if (result != null) {
                        Log.d("Intune", result.name());
                        promise.resolve(result.name());
                        return;
                    }
                }
                promise.resolve(true);
            } else {
                promise.reject(Constants.MAM_NOT_ENROLLED, Constants.MAM_NOT_ENROLLED);
            }
        } catch (Exception exception) {
            Log.e("Intune", "exception: " + exception.getMessage());
            Log.e("Intune", "exception: " + exception.toString());
            Log.e("MsIntuneMamModule", "Exception: " + exception.getStackTrace());
            promise.reject(Constants.ERROR, exception.getMessage());
        }
    }

    @ReactMethod
    public void getRegisteredAccountStatus(
            final String identity,
            final Promise promise) {

        try {
            MAMEnrollmentManager enrollmentManager = MAMComponents.get(MAMEnrollmentManager.class);
            if (enrollmentManager != null) {
                MAMEnrollmentManager.Result result = enrollmentManager.getRegisteredAccountStatus(identity);
                if (result != null) {
                    promise.resolve(result.name());
                } else {
                    promise.resolve(null);
                }
            } else {
                promise.reject(Constants.MAM_NOT_ENROLLED, Constants.MAM_NOT_ENROLLED);
            }
        } catch (Exception exception) {
            Log.e("Intune", "Exception: " + exception.getMessage());
            promise.reject(Constants.ERROR, exception.getMessage());
        }
    }


    @ReactMethod
    public void updateToken(
            final String identity,
            String aadId,
            String resourceId,
            String token,
            final Promise promise) {

        try {
            MAMEnrollmentManager enrollmentManager = MAMComponents.get(MAMEnrollmentManager.class);
            if (enrollmentManager != null) {
                enrollmentManager.updateToken(identity, aadId, resourceId, token);
                promise.resolve(true);
            } else {
                promise.reject(Constants.MAM_NOT_ENROLLED, Constants.MAM_NOT_ENROLLED);
            }
        } catch (Exception exception) {
            Log.e("Intune", "exception: " + exception.getMessage());
            Log.e("Intune", "exception: " + exception.toString());
            Log.e("MsIntuneMamModule", "Exception: " + exception.getStackTrace());
            promise.reject(Constants.ERROR, exception.getMessage());
        }
    }

    @ReactMethod
    public void registerAndEnrollAccount(
            final String identity,
            final String aadId,
            final String tenantId,
            final String token,
            final Promise promise) {
        final Activity activity = getCurrentActivity();
        activity.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                try {
                    if (serviceAuthenticationCallback != null) {
                        serviceAuthenticationCallback.updateToken(token);
                    }

                    MAMEnrollmentManager enrollmentManager = MAMComponents.get(MAMEnrollmentManager.class);
                    if (enrollmentManager != null) {
                        enrollmentManager.registerAccountForMAM(identity, aadId, tenantId);

                        MAMIdentitySwitchResult result = MAMPolicyManager.setCurrentThreadIdentity(identity);
                        if (result != null) {
                            Log.d("Intune", result.name());
                        }
                        MAMPolicyManager.setUIPolicyIdentity(activity, identity, new MAMSetUIIdentityCallback() {
                            @Override
                            public void notifyIdentityResult(MAMIdentitySwitchResult mamIdentitySwitchResult) {
                                if (mamIdentitySwitchResult != null) {
                                    Log.d("Intune", mamIdentitySwitchResult.name());
                                }
                            }
                        });
                        result = MAMPolicyManager.setProcessIdentity(identity);
                        if (result != null) {
                            Log.d("Intune", result.name());
                            promise.resolve(result.name());
                            return;
                        }
                        promise.resolve(true);
                    } else {
                        promise.reject(Constants.MAM_NOT_ENROLLED, Constants.MAM_NOT_ENROLLED);
                    }
                } catch (Exception exception) {
                    Log.e("Intune", "exception: " + exception.getMessage());
                    Log.e("Intune", "exception: " + exception.toString());
                    Log.e("MsIntuneMamModule", "Exception: " + exception.getStackTrace());
                    promise.reject(Constants.ERROR, exception.getMessage());
                }
            }
        });

    }

    @ReactMethod
    public void getCurrentEnrolledAccount(final Promise promise) {
        MAMUserInfo info = MAMComponents.get(MAMUserInfo.class);
        if (info != null) {
            promise.resolve(info.getPrimaryUser());
        } else {
            promise.reject(Constants.USER_NOT_FOUND, Constants.USER_NOT_FOUND);
        }
    }

    @ReactMethod
    public void getAppConfiguration(
            final String identity,
            final Promise promise) {

        try {
            MAMAppConfigManager configManager = MAMComponents.get(MAMAppConfigManager.class);
            if (configManager != null) {
                MAMAppConfig appConfig = configManager.getAppConfig(identity);

                List<Map<String, String>> data = appConfig.getFullData();
                WritableMap result = Arguments.createMap();

                for (Map<String, String> mapData : data) {
                    for (Map.Entry<String, String> entry : mapData.entrySet()) {
                        result.putString(entry.getKey(), entry.getValue());
                    }
                }

                promise.resolve(result);
            } else {
                promise.reject(Constants.MAM_NOT_ENROLLED, Constants.MAM_NOT_ENROLLED);
            }
        } catch (Exception exception) {
            Log.e("Intune", "exception: " + exception.getMessage());
            Log.e("Intune", "exception: " + exception.toString());
            Log.e("MsIntuneMamModule", "Exception: " + exception.getStackTrace());
            promise.reject(Constants.ERROR, exception.getMessage());
        }
    }
}