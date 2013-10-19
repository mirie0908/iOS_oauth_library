//
//  OAuthCoreWrapper.h
//  hatena_oauth_app_single
//
//  Created by 入江 昌信 on 2013/04/26.
//  Copyright (c) 2013年 入江 昌信. All rights reserved.
//

// #define MYDEBUG

#import <Foundation/Foundation.h>

#import "OAuthCore.h"
#import "OAuth+Additions.h"
#import "NSString+Additions2.h"
#import "MyChores.h"

#define NOT_AUTHORIZED                   0 // OAuth認証まったくされていない。
#define TEMPORARY_CREDENTIAL_AUTHORIZED  1 // Temporary credentialの取得まで完了している。
#define OAUTH_TOKEN_AUTHORIZED           2 // 認証サイトにリダイレクトされ、認証し、virifier codeの取得まで完了している。
#define ACCESS_TOKEN_AUTHORIZED          3 // Access credentialの取得まで完了している。


@interface OAuthCoreWrapper : NSObject {
    
    int oauth_status;
    
    NSString *myConsumerKey;
    NSString *myConsumerSecret;
    NSString *myMethod;
    NSURL *myURL4TemporaryCredential;
    NSURL *myURL4VerifierCode;
    NSURL *myURL4AccessCredential;
//    NSString *myCallbackURL;
    NSData *myBody;
    
    NSString *temporary_credential;
    NSString *temporary_credential_secret;
    NSString *access_credential;
    NSString *access_credential_secret;
    
    // 2013.9.29(sun)
    NSString *userid;
}

@property int oauth_status;
@property (retain) NSString *myConsumerKey;
@property (retain) NSString *myConsumerSecret;
@property (retain) NSString *myMethod;
@property (retain) NSURL *myURL4TemporaryCredential;
@property (retain) NSURL *myURL4VerifierCode;
@property (retain) NSURL *myURL4AccessCredential;
//@property (retain) NSString *myCallbackURL;
@property (retain) NSData *myBody;

@property (retain) NSString *temporary_credential;
@property (retain) NSString *temporary_credential_secret;
@property (retain) NSString *access_credential;
@property (retain) NSString *access_credential_secret;

// 2013.9.29(sun)
@property (retain) NSString *userid;


- (id) initWithConsumerKey:(NSString *)aConsumerKey
         andConsumerSecret:(NSString *)aConsumerSecret
                 andMethod:(NSString *)aMethod
andURL4TemporaryCredential:(NSString *)aURL4Temp_str
andURL4VerifierCodeToRedirect:(NSString *)aURL4VerifierCode_str
   andURL4AccessCredential:(NSString *)aURL4Access_str
//            andCallbackURL:(NSString *)aCallbackURL_str
                   andBody:(NSData *)aBody;



- (BOOL) getOAuthHeader4TemporaryCredentialAndStoreToProperty;

- (BOOL) getOAuthHeader4AccessCredentialAndStoreToPropertyWithVerifierCode:(NSString *)aVerifierCode;

- (NSString *) getOAuthHeader4GeneralWithUrl:(NSURL *)url andMethod:(NSString *)method;



@end
