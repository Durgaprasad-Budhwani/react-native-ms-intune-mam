package com.microsoft.intune.mam;

import android.util.Log;

import com.microsoft.intune.mam.policy.MAMServiceAuthenticationCallback;

/**
 * Created by durgaprasad on 7/27/17.
 */

public class RNMAMServiceAuthenticationCallback implements MAMServiceAuthenticationCallback {

    private String token = null;
    public void updateToken(String aadToken) {
        Log.v("Intune", aadToken);
        token = aadToken;
    }

    @Override
    public String acquireToken(String s, String s1, String s2) {
        Log.v("Intune", "Asking token " + token);
        return token;
    }
}
