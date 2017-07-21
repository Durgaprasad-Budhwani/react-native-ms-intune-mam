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
import RNReactNativeMsIntuneMam from 'react-native-ms-intune-mam'

export default class example extends Component {
  _onLoginPress () {
  
  }
  
  _logout () {
  
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
