iOS_oauth_library
=================

objective-c iOS OAuth library

1. Abstract

Class OAuthCoreWrapper has methods to create OAuth header for temporary credential and token credential.

2. Instance method

2.1  - (BOOL) getOAuthHeader4TemporaryCredentialAndStoreToProperty; 

 Method to create temporary credential.
 

2.2  - (BOOL) getOAuthHeader4AccessCredentialAndStoreToPropertyWithVerifierCode:(NSString *)aVerifierCode;

 Method to create token credential (= access key and secret). Parameter "verified code" is necessary, which 
 you will get in advance from the site when the iOS app will redicrect you to the callback URL for authentication.
