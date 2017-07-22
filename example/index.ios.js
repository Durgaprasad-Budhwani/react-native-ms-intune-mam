/**
 * Sample React Native App
 * https://github.com/facebook/react-native
 * @flow
 */

import React, { Component } from 'react';

import {
  AppRegistry,
  StyleSheet,
  Text,
  View,
  Button,
} from 'react-native';
import RNReactNativeMsIntuneMam from 'react-native-ms-intune-mam';
import AzureAdal from 'react-native-azure-adal';

const authority = "https://login.windows.net/common/oauth2/authorize"; //"https://login.windows.net/ariaserver.onmicrosoft.com";
const resourceUri =  "https://graph.windows.net/"; //"https://ariamobileappproxy-ariaserver.msappproxy.net/VMS.ARIAMobile.DummryService/";

const clientId = "6c7e8096-f593-4d72-807f-a5f86dcc9c77"; //'f00ae3c0-172f-4978-a409-7d7bb29b1026';

const redirectUri = "urn:ietf:wg:oauth:2.0:oob"; //"http://TodoListClient"; //"x-msauth-awesomeproject://com.varian.awesomeproject"; //

export default class example extends Component {
  async _onLoginPress () {
    try {
      let isConfigure =  await AzureAdal.configure(authority, false, clientId, redirectUri, false);
      console.log(isConfigure);
      // let userId = await RNReactNativeMsIntuneMam.getCurrentEnrolledAccount();
      let result = await AzureAdal.loginWithPrompt(resourceUri);
      console.log(result);
      let enrolled1 = await RNReactNativeMsIntuneMam.registerAndEnrollAccount(result.userInfo.displayableId, false);
      console.log(enrolled1);
    }
    catch (error) {
      console.log(error);
    }
  }
  
  
  
  async _logout () {
    await AzureAdal.logout(resourceUri);
    let user = await RNReactNativeMsIntuneMam.getCurrentEnrolledAccount();
    console.log('user', user);
    if(user){
      let enrolled = await RNReactNativeMsIntuneMam.deRegisterAndUnenrollAccount(user, false);
      console.log(enrolled);
    }
  }
  
  async _loginWithApplicationUrl() {
    let isConfigure =  await AzureAdal.configure(authority, false, clientId, redirectUri, false);
    let user = await AzureAdal.login(resourceUri);
    let redirectUri = "http://ariamobileapp-redirect-uri";
    let configurations = await RNReactNativeMsIntuneMam.getAppConfiguration(null);
    if(configurations){
      // console.log(result);
      console.log(user);
      
      try{
	let config = configurations[0];
	let clientId = config.applicationId;
	let applicationUrl = config.applicationUrl;
	let authority = `https://login.windows.net/${user.tenantId}`;
	console.log(clientId);
	console.log(applicationUrl);
	console.log(authority);
	await AzureAdal.configure(authority, false, clientId, redirectUri, false);
	let result = await AzureAdal.login(applicationUrl, user.userInfo.displayableId);
	console.log(result);
      }
      catch(error){
        console.log(error);
      }
     
	
    }
   
    // console.log(isConfigure);
    // // let userId = await RNReactNativeMsIntuneMam.getCurrentEnrolledAccount();
    // let result = await AzureAdal.loginWithPrompt(resourceUri);
    
  }
  
  async _getConfiguration () {
    let result = await RNReactNativeMsIntuneMam.getAppConfiguration(null);
    console.log(result);
  }
  
  async _enrollCurrentUser () {
    let result = await RNReactNativeMsIntuneMam.getCurrentEnrolledAccount();
    console.log(result);
  }
  
  
  render() {
    return (
      <View style={styles.container}>
	<View style={{marginBottom:10}}>
	  <Button
	    onPress={this._onLoginPress.bind(this)}
	    title="Login"
	  />
	</View>
	<View style={{marginBottom:10}}>
	  <Button
	    onPress={this._loginWithApplicationUrl.bind(this)}
	    title="Login With Application Data"
	  />
	</View>
	<View style={{marginBottom:10}}>
	  <Button
	    onPress={this._enrollCurrentUser.bind(this)}
	    title="EnrollCurrentUser"
	  />
	</View>
	<View style={{marginBottom:10}}>
	  <Button
	    onPress={this._getConfiguration.bind(this)}
	    title="Get Configuration"
	  />
	</View>
	<View style={{marginBottom:10}}>
	  <Button
	    onPress={this._logout.bind(this)}
	    title="Logout"
	  />
	</View>
      </View>
    );
  }
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#F5FCFF',
  },
  welcome: {
    fontSize: 20,
    textAlign: 'center',
    margin: 10,
  },
  instructions: {
    textAlign: 'center',
    color: '#333333',
    marginBottom: 5,
  },
});

AppRegistry.registerComponent('example', () => example);
