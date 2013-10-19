//
//  OAuthCoreWrapper.m
//  hatena_oauth_app_single
//
//  Created by 入江 昌信 on 2013/04/26.
//  Copyright (c) 2013年 入江 昌信. All rights reserved.
//

#import "OAuthCoreWrapper.h"
#import "OAuthCore.h"

@implementation OAuthCoreWrapper

@synthesize oauth_status;

@synthesize myConsumerKey;
@synthesize myConsumerSecret;
@synthesize myMethod;
@synthesize myURL4TemporaryCredential;
@synthesize myURL4VerifierCode;
@synthesize myURL4AccessCredential;
//@synthesize myCallbackURL;
@synthesize myBody;

@synthesize temporary_credential, temporary_credential_secret;
@synthesize access_credential, access_credential_secret;

@synthesize userid;


- (id) initWithConsumerKey:(NSString *)aConsumerKey
         andConsumerSecret:(NSString *)aConsumerSecret
                 andMethod:(NSString *)aMethod
andURL4TemporaryCredential:(NSString *)aURL4Temp_str
andURL4VerifierCodeToRedirect:(NSString *)aURL4VerifierCode_str
   andURL4AccessCredential:(NSString *)aURL4Access_str
        // andCallbackURL:(NSString *)aCallbackURL_str
                   andBody:(NSData *)aBody {
    

    
    if ((self = [super init])) {
        self.myConsumerKey = aConsumerKey;
        self.myConsumerSecret = aConsumerSecret;
        self.myMethod = aMethod;
        self.myURL4TemporaryCredential = [NSURL URLWithString:aURL4Temp_str];
        self.myURL4VerifierCode = [NSURL URLWithString:aURL4VerifierCode_str];
        self.myURL4AccessCredential = [NSURL URLWithString:aURL4Access_str];
     //   self.myCallbackURL = aCallbackURL_str;
        self.myBody = aBody;
    }
    return self;
}


- (BOOL) getOAuthHeader4TemporaryCredentialAndStoreToProperty {
    
    //NSURL *url = [NSURL URLWithString:@"https://www.hatena.com/oauth/initiate"];
    //NSString *method = @"POST";
    //NSData *body = [NSData dataWithBytes:"scope=read_private%2Cwrite_private" length:34];
    // //NSData *body = [[NSData alloc]initWithBytes:"scope=read_private,write_private" length:32];
    
    NSURL *url = self.myURL4TemporaryCredential;
    NSString *method = self.myMethod;
    NSData *body = self.myBody;
    
#ifdef MYDEBUG
    NSLog(@"body : %@",[body description]);
    NSLog(@"body length: %d", [body length]);
#endif
    
    // NSSTring scopeを、一旦NSStringに変換して、NSStringの（カテゴリで付与した）メソッドでurlencoding
    // 2013.6.29 scope=...全体をエンコーディングしてはいけない。
    //NSString *body_str= [[NSString alloc] initWithData:body encoding:NSUTF8StringEncoding];
    //NSString *body_str_encoded = [body_str ab_RFC3986EncodedString];
    
    //[body release];
    //[body_str release];
    
    // urlencoding後のNSStringを再びNSDataに戻す
    //NSData *body_data_encoded = [body_str_encoded dataUsingEncoding:NSUTF8StringEncoding];
    //NSData *body_data = [body_str dataUsingEncoding:NSUTF8StringEncoding];
    
    //NSLog(@"body_data_encoded : %@",[body_data_encoded description]);
    
    NSString *oauth_verifier = @"";
    
    NSString *oauth_token = @"";
    NSString *oauth_token_secret = @"";
    
    // 1. OAuthヘッダーの作成
    //NSString *header = OAuthorizationHeader(url, method, body, self.myConsumerKey, self.myConsumerSecret, oauth_token,oauth_token_secret,oauth_verifier);
    
    NSString *header = OAuthorizationHeader(url, method, body, self.myConsumerKey, self.myConsumerSecret, oauth_token,oauth_token_secret,oauth_verifier);
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:method];
    [request setValue:header forHTTPHeaderField:@"Authorization"];
    
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    
    // bodyは、scope= は原型で、=の右辺はパーセントエンコーディングで。
    [request setHTTPBody:body];
    //[request setHTTPBody:body_data_encoded];
    
    //NSURLResponse *response = nil;
    NSHTTPURLResponse *response = nil;
    NSError       *error    = nil;
    
    // 2. temporary credential (=古い言い方だと、request token)の取得。取得できたものは、oauth_tokenに返る。
    NSString *responseString = [[[NSString alloc] initWithData:[NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error] encoding:NSUTF8StringEncoding] autorelease];
    
#ifdef MYDEBUG
    NSLog(@"Got statuses. HTTP result code: %d", [response statusCode]);
    NSLog(@"responseString = %@",responseString);
#endif
    
    if ( [response statusCode] != 200) {
        NSLog(@"temporary_credential 取得失敗");
        return NO;
    }
    
    // 3. responseStringから、temprary_credential と　temporary_credential_secretをパースする。
    MyChores *chores = [[[MyChores alloc] init] autorelease];
    NSMutableDictionary *dict = [chores responseString2Dict:responseString];
    
    // 2013.4.9(tue) 取得した temporary_credential, temporary_credential_secretは、URLencodedな文字列なので、
    // 先頃つくった RFC3986Decodingカテゴリをつかって、取得後すぐ、decodingしといて、以降、他のparameterと同様の扱いできるようにしとく。
    self.temporary_credential = [[dict valueForKey:@"oauth_token"] RFC3986DecordingString];
    self.temporary_credential_secret = [[dict valueForKey:@"oauth_token_secret"] RFC3986DecordingString];
    
#ifdef MYDEBUG
    NSLog(@" temporary_credential dict : %@",[dict description]);
#endif
    
    return YES;
}


- (BOOL) getOAuthHeader4AccessCredentialAndStoreToPropertyWithVerifierCode:(NSString *)aVerifierCode {
    
    // 5. verification codeで、token credential (古い言い方だとaccess_token)を取得する
    
    //NSURL *url = [NSURL URLWithString:@"https://www.hatena.com/oauth/token"];
    //NSString *method = @"POST";
    //NSData *body = nil;
    
    NSURL *url       = self.myURL4AccessCredential;
    NSString *method = self.myMethod;
    NSData *body     = nil;
    
    NSString *oauth_token = self.temporary_credential;
    NSString *oauth_token_secret = self.temporary_credential_secret;
    
    // 2013.3.19 oauth_verifierは、ここでRFC3986エンコーディングしちゃいけんだろ。OAuthorizationHeader()に渡した後、そのなかで、encodingされるんで。
    // エンコーディングせずに渡すように戻す。
    NSString *oauth_verifier = aVerifierCode;
    NSString *header = OAuthorizationHeader(url, method, body, self.myConsumerKey, self.myConsumerSecret, oauth_token, oauth_token_secret, oauth_verifier);
    
#ifdef MYDEBUG
    NSLog(@"oauth_verifier = %@",aVerifierCode);
    NSLog(@"header : %@",header);
#endif
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:method];
    [request setValue:header forHTTPHeaderField:@"Authorization"];
    [request setHTTPBody:body];
    NSHTTPURLResponse *response = nil;
    NSError       *error    = nil;
    
    NSString *responseString = [[[NSString alloc] initWithData:[NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error] encoding:NSUTF8StringEncoding] autorelease];
    
#ifdef MYDEBUG
    NSLog(@"Got statuses. HTTP result code: %d", [response statusCode]);
    NSLog(@"responseString = %@",responseString);
#endif
    
    if ([response statusCode] == 200) {
        // 3. responseStringから、access_credential と　access_credential_secretをパースする。
        MyChores *chores = [[[MyChores alloc] init] autorelease];
        NSMutableDictionary *dict = [chores responseString2Dict:responseString];
        self.access_credential = [[dict valueForKey:@"oauth_token"] RFC3986DecordingString];
        self.access_credential_secret = [[dict valueForKey:@"oauth_token_secret"] RFC3986DecordingString];
        
        // 2013.9.29(sun)
        self.userid = [[dict valueForKey:@"url_name"] RFC3986DecordingString];
    
        self.oauth_status = ACCESS_TOKEN_AUTHORIZED;
    
#ifdef MYDEBUG
        NSLog(@" access_credential dict : %@",[dict description]);
        NSLog(@" access_credential = %@",self.access_credential);
        NSLog(@" access_credential_secret = %@",self.access_credential_secret);
#endif
    
        return YES;
        
    } else {
        // access credential取得失敗
        NSLog(@"access credential取得失敗");
        return FALSE;
    }
    
}

- (NSString *) getOAuthHeader4GeneralWithUrl:(NSURL *)url andMethod:(NSString *)method  {
    
    NSString *header = OAuthorizationHeader4Access(url, method, self.myConsumerKey, self.myConsumerSecret, self.access_credential, self.access_credential_secret);
    
    return header;
    
    
}


@end
