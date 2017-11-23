package com.example;

import com.facebook.react.ReactApplication;
//import com.reactlibrary.RNReactNativeMsIntuneMamPackage;
//import com.microsoft.azure.adal.RNAzureAdalPackage;
import com.facebook.react.ReactNativeHost;
import com.facebook.react.ReactPackage;
import com.facebook.react.shell.MainReactPackage;
import com.facebook.soloader.SoLoader;
import com.microsoft.aad.adal.AuthenticationSettings;
import com.microsoft.azure.adal.RNAzureAdalPackage;
import com.microsoft.intune.mam.client.app.MAMApplication;
import com.microsoft.intune.mam.RNReactNativeMsIntuneMamPackage;

import java.io.UnsupportedEncodingException;
import java.security.NoSuchAlgorithmException;
import java.security.spec.InvalidKeySpecException;
import java.util.Arrays;
import java.util.List;

public class MainApplication extends MAMApplication implements ReactApplication {

  private final ReactNativeHost mReactNativeHost = new ReactNativeHost(this) {

    @Override
    public boolean getUseDeveloperSupport() {
      return BuildConfig.DEBUG;
    }

    @Override
    protected List<ReactPackage> getPackages() {
      return Arrays.<ReactPackage>asList(
          new MainReactPackage()
              ,
            new RNReactNativeMsIntuneMamPackage(),
            new RNAzureAdalPackage()
      );
    }
  };

  @Override
  public ReactNativeHost getReactNativeHost() {
    return mReactNativeHost;
  }

  @Override
  public void onMAMCreate() {
    super.onMAMCreate();
    SoLoader.init(this, /* native exopackage */ false);
  }



//  @Override
  public byte[] getADALSecretKey() {
    if (AuthenticationSettings.INSTANCE.getSecretKeyData() == null) {
      // use same key for tests
      return com.microsoft.azure.adal.AdalUtils.getADALSecretKey();
    }
    return AuthenticationSettings.INSTANCE.getSecretKeyData();
  }
}
