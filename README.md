
# react-native-react-native-ms-intune-mam

## Getting started

`$ npm install react-native-react-native-ms-intune-mam --save`

### Mostly automatic installation

`$ react-native link react-native-react-native-ms-intune-mam`

### Manual installation


#### iOS

1. In XCode, in the project navigator, right click `Libraries` ➜ `Add Files to [your project's name]`
2. Go to `node_modules` ➜ `react-native-react-native-ms-intune-mam` and add `RNReactNativeMsIntuneMam.xcodeproj`
3. In XCode, in the project navigator, select your project. Add `libRNReactNativeMsIntuneMam.a` to your project's `Build Phases` ➜ `Link Binary With Libraries`
4. Run your project (`Cmd+R`)<

#### Android

1. Open up `android/app/src/main/java/[...]/MainActivity.java`
  - Add `import com.reactlibrary.RNReactNativeMsIntuneMamPackage;` to the imports at the top of the file
  - Add `new RNReactNativeMsIntuneMamPackage()` to the list returned by the `getPackages()` method
2. Append the following lines to `android/settings.gradle`:
  	```
  	include ':react-native-react-native-ms-intune-mam'
  	project(':react-native-react-native-ms-intune-mam').projectDir = new File(rootProject.projectDir, 	'../node_modules/react-native-react-native-ms-intune-mam/android')
  	```
3. Insert the following lines inside the dependencies block in `android/app/build.gradle`:
  	```
      compile project(':react-native-react-native-ms-intune-mam')
  	```

#### Windows
[Read it! :D](https://github.com/ReactWindows/react-native)

1. In Visual Studio add the `RNReactNativeMsIntuneMam.sln` in `node_modules/react-native-react-native-ms-intune-mam/windows/RNReactNativeMsIntuneMam.sln` folder to their solution, reference from their app.
2. Open up your `MainPage.cs` app
  - Add `using Com.Reactlibrary.RNReactNativeMsIntuneMam;` to the usings at the top of the file
  - Add `new RNReactNativeMsIntuneMamPackage()` to the `List<IReactPackage>` returned by the `Packages` method


## Usage
```javascript
import RNReactNativeMsIntuneMam from 'react-native-react-native-ms-intune-mam';

// TODO: What to do with the module?
RNReactNativeMsIntuneMam;
```
  