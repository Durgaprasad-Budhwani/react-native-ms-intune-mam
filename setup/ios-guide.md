## Prerequisites

A working CocoaPods installation [CocoaPods - Getting Started](https://guides.cocoapods.org/using/getting-started.html)

## Step 1

- If CocoaPods is not installed, please run below commands:

```bash
pod init
```

- Add the ADAL ios library to your ios/Podfile file pod `'ADAL', '~> 2.3'`.

```
target 'example' do
  # Uncomment the next line if you're using Swift or would like to use dynamic frameworks
  # use_frameworks!

  # Add ADAL Pod
  pod 'ADAL', '~> 2.3'
  # Pods for example

  target 'exampleTests' do
    inherit! :search_paths
    # Pods for testing
  end

end

```

- Run below command to pull the ios ADAL library down.

```bash
pod install
```

## Step 2

Install **react-native-azure-adal**

```bash
npm install react-native-azure-adal --save
```

OR 

```bash
yarn add react-native-azure-adal
```

And link react-native-azure-adal

```bash
react-native link react-native-azure-adal
```

## Step 3 
1. Link **IntuneMAM.framework** to your project. Drag **IntuneMAM.framework** to the Embedded Binaries list of the project target.
2. Add these iOS frameworks to the project:
	- MessageUI.framework
	- Security.framework
	- MobileCoreServices.framework
	- SystemConfiguration.framework
	- libsqlite3.tbd
	- libc++.tbd
	- ImageIO.framework
	- LocalAuthentication.framework
	- AudioToolbox.framework
3. Add the **IntuneMAMResources.bundle** resource bundle to the project by dragging the resource bundle under Copy Bundle Resources within Build Phases.
4. Enable keychain sharing (if it isn't already enabled) by choosing **Capabilities** in each project target and enabling the **Keychain** Sharing switch. Keychain sharing is required for you to proceed to the next step.
5. After you enable keychain sharing, follow these steps to create a separate access group in which the Intune App SDK will store its data. You can create a keychain access group by using the UI or by using the entitlements file. If you are using the UI to create the keychain access group, make sure to follow the steps below:
	- If your mobile app does not have any keychain access groups defined, add the app’s bundle ID as the first group.
	- Add the shared keychain group **com.microsoft.intune.mam** to your existing access groups. The Intune App SDK uses this access group to store data.
	- Add **com.microsoft.adalcache** to your existing access groups.
	- Add **com.microsoft.workplacejoin** to your existing access groups.

	![](https://docs.microsoft.com/en-us/intune/media/intune-app-sdk-ios-keychain-sharing.png)

	- If you are using the entitlement file to create the keychain access group, prepend the keychain access group with `$(AppIdentifierPrefix)` in the entitlement file. For example:
	
	```
	* `$(AppIdentifierPrefix)com.microsoft.intune.mam`
 	* `$(AppIdentifierPrefix)com.microsoft.adalcache`
	```
	
6. If the app defines URL schemes in its Info.plist file, add another scheme, with a `-intunemam` suffix, for each URL scheme.




## Info.plist chagnes

```xml
	<key>IntuneMAMSettings</key>
	<dict>
		<key>MAMPolicyRequired</key>
		<true/>
		<key>AutoEnrollOnLaunch</key>
		<true/>
		<key>MultiIdentity</key>
		<true/>
		<key>MAMTelemetryDisabled</key>
		<true/>
	</dict>
	<key>LSApplicationQueriesSchemes</key>
	<array>
		<string>msauth</string>
		<string>ms-outlook-intunemam</string>
		<string>http-intunemam</string>
		<string>https-intunemam</string>
		<string>msauth-intunemam</string>
	</array>
	<key>CFBundleSupportedPlatforms</key>
	<array>
		<string>iPhoneOS</string>
	</array>
	<key>NSAppTransportSecurity - 2</key>
	<dict>
		<key>NSAllowsArbitraryLoads</key>
		<true/>
	</dict>
	<key>CFBundleURLTypes</key>
	<array>
		<dict>
			<key>CFBundleTypeRole</key>
			<string>Editor</string>
			<key>CFBundleURLName</key>
			<string>com.varian.awesomeproject</string>
			<key>CFBundleURLSchemes</key>
			<array>
				<string>x-msauth-awesomeproject</string>
				<string>x-msauth-awesomeproject-intunemam</string>
			</array>
		</dict>
	</array>
```


## Register app with Microsft Intune

1. Go to Azure portal (TODO link)
2. Intune App Protection (TODO - Images)