package com.microsoft.intune.mam;

import android.app.Activity;
import android.app.AlarmManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.util.Log;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.WritableMap;
import com.facebook.soloader.SysUtil;
import com.facebook.soloader.UnpackingSoSource;
import com.microsoft.intune.mam.client.MAMIdentitySwitchResult;
import com.microsoft.intune.mam.client.MAMInfo;
import com.microsoft.intune.mam.client.app.MAMComponents;
import com.microsoft.intune.mam.client.app.offline.OfflineActivityBehavior;
import com.microsoft.intune.mam.client.identity.MAMPolicyManager;
import com.microsoft.intune.mam.client.identity.MAMPolicyManagerBehavior;
import com.microsoft.intune.mam.client.identity.MAMSetUIIdentityCallback;
import com.microsoft.intune.mam.client.notification.MAMNotificationReceiverRegistry;
import com.microsoft.intune.mam.log.MAMLogHandlerWrapper;
import com.microsoft.intune.mam.policy.MAMEnrollmentManager;
import com.microsoft.intune.mam.policy.MAMServiceAuthenticationCallback;
import com.microsoft.intune.mam.policy.MAMUserInfo;
import com.microsoft.intune.mam.policy.appconfig.MAMAppConfig;
import com.microsoft.intune.mam.policy.appconfig.MAMAppConfigManager;
import com.microsoft.intune.mam.policy.notification.MAMNotificationType;
import com.microsoft.intune.mam.client.app.offline.OfflineInstallCompanyPortalDialogActivity;

import java.io.File;
import java.io.IOException;
import java.util.List;
import java.util.Map;
import java.util.logging.Handler;

public class RNReactNativeMsIntuneMamModule extends ReactContextBaseJavaModule {

    private final ReactApplicationContext reactContext;
    private MAMServiceAuthenticationCallback serviceAuthenticationCallback;


    public RNReactNativeMsIntuneMamModule(ReactApplicationContext reactContext) {
        super(reactContext);
        this.reactContext = reactContext;
//        MAMEnrollmentManager enrollmentManager = MAMComponents.get(MAMEnrollmentManager.class);
//        if (enrollmentManager != null) {
//            serviceAuthenticationCallback = new RNMAMServiceAuthenticationCallback();
//            enrollmentManager.registerAuthenticationCallback(serviceAuthenticationCallback);
//        }

        MAMComponents.get(MAMLogHandlerWrapper.class).addHandler(new AndroidHandler(), true);
//        MAMComponents.get(MAMNotificationReceiverRegistry.class).registerReceiver(new RNReactNativeNotificationReceiver(reactContext), MAMNotificationType.MANAGEMENT_REMOVED);
        MAMComponents.get(MAMNotificationReceiverRegistry.class).registerReceiver(new RNReactNativeNotificationReceiver(reactContext), MAMNotificationType.MAM_ENROLLMENT_RESULT);
        MAMComponents.get(MAMNotificationReceiverRegistry.class).registerReceiver(new RNReactNativeNotificationReceiver(reactContext), MAMNotificationType.WIPE_USER_DATA);
//        MAMComponents.get(MAMNotificationReceiverRegistry.class).registerReceiver(new RNReactNativeNotificationReceiver(reactContext), MAMNotificationType.REFRESH_POLICY);
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
            _removeFiles();

            MAMPolicyManagerBehavior policyManager = MAMComponents.get(MAMPolicyManagerBehavior.class);
            MAMEnrollmentManager enrollmentManager = MAMComponents.get(MAMEnrollmentManager.class);
            if (enrollmentManager != null) {
                Log.i("Intune", "deRegisterAndUnenrollAccount: " + identity);

                enrollmentManager.unregisterAccountForMAM(identity);
//                if (policyManager != null) {
//                    MAMIdentitySwitchResult result = policyManager.setProcessIdentity("");
//                    if (result != null) {
//                        Log.d("Intune", result.name());
//                        promise.resolve(result.name());
//                        return;
//                    }
//                }
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
    public void removeFiles(final Promise promise){
        try{
            _removeFiles();
            promise.resolve(true);
        }
        catch (Exception exception){
            Log.e("Intune", "Exception: " + exception.getMessage());
            promise.resolve(false);
        }
    }


    private void _removeFiles() throws IOException {
        // removed shared storage files -- this is bug in react native android version
        String fileName = "lib-main";
        File file = UnpackingSoSource.getSoStorePath(reactContext, fileName);
        SysUtil.dumbDeleteRecursive(file);
    }

    @ReactMethod
    public void isCompanyPortalInstalled(
            final Promise promise
    ) {
        try {
            reactContext.getPackageManager().getApplicationInfo(MAMInfo.getPackageName(), 0);
            promise.resolve(true);
        } catch (PackageManager.NameNotFoundException e) {
            promise.resolve(false);
        }

    }

    @ReactMethod
    public void launchActivtyToInstallCompnayAppPortal() {
        reactContext.getCurrentActivity().startActivityForResult(createIntentForInstallCompanyPortal(), -1);
    }

    private Intent createIntentForInstallCompanyPortal() {
        Intent localIntent = new Intent(reactContext.getCurrentActivity(), OfflineInstallCompanyPortalDialogActivity.class);
        localIntent.setFlags(268435456);
        localIntent.putExtra("activityLaunchBlocked", true);
        return localIntent;
    }

    @ReactMethod
    public void getRegisteredAccountStatus(
            final Promise promise) {

        try {
            MAMUserInfo info = MAMComponents.get(MAMUserInfo.class);
            MAMEnrollmentManager enrollmentManager = MAMComponents.get(MAMEnrollmentManager.class);
            if (enrollmentManager != null) {
                MAMEnrollmentManager.Result result = enrollmentManager.getRegisteredAccountStatus(info.getPrimaryUser());
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
        final Activity activity = reactContext.getCurrentActivity();
        activity.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                try {
                    MAMEnrollmentManager enrollmentManager = MAMComponents.get(MAMEnrollmentManager.class);
                    if (serviceAuthenticationCallback == null) {
                        serviceAuthenticationCallback = new RNMAMServiceAuthenticationCallback();
                        enrollmentManager.registerAuthenticationCallback(serviceAuthenticationCallback);
                        ((RNMAMServiceAuthenticationCallback) serviceAuthenticationCallback).updateToken(token);
                    }

                    if (enrollmentManager != null) {
                        //enrollmentManager.unregisterAccountForMAM(identity);
                        enrollmentManager.registerAccountForMAM(identity, aadId, tenantId);

//                        MAMIdentitySwitchResult result = MAMPolicyManager.setCurrentThreadIdentity(identity);
//                        if (result != null) {
//                            Log.d("Intune", result.name());
//                        }
//                        MAMPolicyManager.setUIPolicyIdentity(activity, identity, new MAMSetUIIdentityCallback() {
//                            @Override
//                            public void notifyIdentityResult(MAMIdentitySwitchResult mamIdentitySwitchResult) {
//                                if (mamIdentitySwitchResult != null) {
//                                    Log.d("Intune", mamIdentitySwitchResult.name());
//                                }
//                            }
//                        });
//                        result = MAMPolicyManager.setProcessIdentity(identity);
//                        if (result != null) {
//                            Log.d("Intune", result.name());
//                            promise.resolve(result.name());
//                            return;
//                        }
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
    public void updateProcessIdentity(final String identity,
                                      final Promise promise) {
        try {
            final Activity activity = reactContext.getCurrentActivity();
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
        } catch (Exception exception) {
            Log.e("Intune", "exception: " + exception.getMessage());
            Log.e("Intune", "exception: " + exception.toString());
            Log.e("MsIntuneMamModule", "Exception: " + exception.getStackTrace());
            promise.reject(Constants.ERROR, exception.getMessage());
        }
    }

    @ReactMethod
    public void getCurrentEnrolledAccount(final Promise promise) {
        try {
            MAMUserInfo info = MAMComponents.get(MAMUserInfo.class);
            if (info != null) {
                promise.resolve(info.getPrimaryUser());
            } else {
                promise.reject(Constants.USER_NOT_FOUND, Constants.USER_NOT_FOUND);
            }
        } catch (Exception exception) {
            Log.e("Intune", "exception: " + exception.getMessage());
            Log.e("Intune", "exception: " + exception.toString());
            Log.e("MsIntuneMamModule", "Exception: " + exception.getStackTrace());
            promise.reject(Constants.ERROR, exception.getMessage());
        }

    }

    @ReactMethod
    public void exitApplication(final Promise promise){
        System.exit(0);
    }

    @ReactMethod
    public void restartApp() {
//        Intent intent = new Intent(reactContext.getApplicationContext(), reactContext.getCurrentActivity().getClass());
//        intent.putExtra("crash", true);
//        intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP
//                | Intent.FLAG_ACTIVITY_CLEAR_TASK
//                | Intent.FLAG_ACTIVITY_NEW_TASK);
//
//        PendingIntent pendingIntent = PendingIntent.getActivity(reactContext.getBaseContext(), 0, intent, PendingIntent.FLAG_ONE_SHOT);
//        AlarmManager mgr = (AlarmManager) reactContext.getBaseContext().getSystemService(Context.ALARM_SERVICE);
//        mgr.set(AlarmManager.RTC, System.currentTimeMillis() + 100, pendingIntent);
//        reactContext.getCurrentActivity().finish();
//        System.exit(2);
//
//        Intent intent = reactContext.getCurrentActivity().getIntent();
//        reactContext.getCurrentActivity().finish();
//        reactContext.getCurrentActivity().startActivity(intent);
//        Intent localIntent = new Intent(reactContext.getCurrentActivity(), com.microsoft.intune.mam.client.app.offline.OfflineRestartRequiredActivity.class);
//        localIntent
//                .setFlags(805437440);
//        reactContext.getCurrentActivity().startActivity(localIntent);
//        reactContext.getCurrentActivity().recreate();

        final Activity activity = reactContext.getCurrentActivity();
        if(activity != null){
            activity.runOnUiThread((new Runnable() {
                @Override
                public void run() {
                    try {
                        activity.recreate();
                    } catch (Exception exception) {
                        Log.e("Intune", "exception: " + exception.getMessage());
                        Log.e("Intune", "exception: " + exception.toString());
                        Log.e("MsIntuneMamModule", "Exception: " + exception.getStackTrace());
                    }
                }
            }));
        }

//
//        OfflineActivityBehavior.softRestart(reactContext.getCurrentActivity());

    }

    @ReactMethod
    public void getAppConfiguration(
            final String identity,
            final Promise promise) {

        try {
            MAMAppConfigManager configManager = MAMComponents.get(MAMAppConfigManager.class);
            if (configManager != null) {
                MAMAppConfig appConfig = configManager.getAppConfig(identity);
                if (appConfig != null) {
                    List<Map<String, String>> data = appConfig.getFullData();
                    WritableMap result = Arguments.createMap();

                    for (Map<String, String> mapData : data) {
                        for (Map.Entry<String, String> entry : mapData.entrySet()) {
                            result.putString(entry.getKey(), entry.getValue());
                        }
                    }

                    promise.resolve(result);
                    return;
                }
            }
            promise.reject(Constants.MAM_NOT_ENROLLED, Constants.MAM_NOT_ENROLLED);
        } catch (Exception exception) {
            Log.e("Intune", "exception: " + exception.getMessage());
            Log.e("Intune", "exception: " + exception.toString());
            Log.e("MsIntuneMamModule", "Exception: " + exception.getStackTrace());
            promise.reject(Constants.ERROR, exception.getMessage());
        }
    }
}