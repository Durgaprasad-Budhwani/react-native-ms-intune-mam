package com.microsoft.intune.mam;

import android.util.Log;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.modules.core.DeviceEventManagerModule;
import com.microsoft.intune.mam.client.notification.MAMNotificationReceiver;
import com.microsoft.intune.mam.policy.notification.MAMNotification;

/**
 * Created by durgaprasad on 11/3/17.
 */

public class RNReactNativeNotificationReceiver implements MAMNotificationReceiver {
    private ReactApplicationContext reactContext;

    public RNReactNativeNotificationReceiver(ReactApplicationContext context){
        reactContext = context;
    }

    @Override
    public boolean onReceive(MAMNotification mamNotification) {
        Log.w("Intune", "mamNotification: " + mamNotification.getType().toString());
        WritableMap params = Arguments.createMap();
        params.putString("enrollmentStatus", mamNotification.getType().toString());
        reactContext
                .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
                .emit("mamNotification", params);
        return true;
    }
}
