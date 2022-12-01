# CRM-iOS-CustomerPortal-SampleApp

Zoho Portal CRM empowers your customers, vendors, and partners with online portals where you can define what data is shown to whom and define their individual access permissions. Enable personal buying by providing a platform where clients can view your products and services, place orders, and update their own contact information. This is a sample code implementing Zoho CRM Portal's mobile SDK. This project contains code for initializing portal sdk and hitting a api through sdk. You may clone the whole project to run the sample application.

## Initialising the SDK

The SDK has to be initialized before its methods are consumed by the app. Set the required configurations through a ZCRMSDKConfigs object and pass it to the initSDK method in the ZCRMSDKClient object as below, to initialize the SDK.

`try ZCRMSDKClient.shared.initSDK(window: UIwindow, appConfiguration : ZCRMSDKConfigs ) throws`

If the user has not logged in, a login screen will be prompted during the SDK initialization. Based on the result of the login, the appropriate callback method will be triggered. 
Only after the successful initialization of the SDK, further methods can be invoked as intended.

## SDK Configuration object

There are methods for configuring the app client details.

Set the app client details, the portal ID and portal name as string values, and pass it to the build() method (builder pattern) using the ZCRMSDKConfigs object as shown below.

`try ZCRMSDKConfigs.Builder(clientId: "---CLIENT_ID---", clientSecret: "---CLIENT_SECRET---", redirectURL: "---REDIRECT_URL---", oauthScopes: ["ZohoCRM.settings.ALL", "ZohoCRM.modules.ALL", "ZohoCRM.users.READ", "ZohoCRM.org.READ", "Aaaserver.profile.Read", "profile.userphoto.READ" ], portalId: "---PORTAL_ID---").setAPPType( .zcrmcp ).setAPIBaseURL( "crm.zoho.com" ).setAccountsURL( "https://accounts.zohoportal.com" ).build()`
 
 - **clientID and clientSecret** : Configure the OAuth client ID and secret of the app registered in Zoho.
 - **oauthScopes** : The OAuth scopes of the Zoho CRM API that the app would use.
 - **portalName** : Specify the client's portal name.
 - **portalId** : Specify the client's portal ID.
 
 Full documentation for the SDK can be found [here](https://www.zoho.com/crm/developer/docs/mobile-sdk/ios.html). 
