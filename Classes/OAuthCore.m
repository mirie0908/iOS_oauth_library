//
//  OAuthCore.m
//
//  Created by Loren Brichter on 6/9/10.
//  Copyright 2010 Loren Brichter. All rights reserved.
//

#import "OAuthCore.h"
#import "OAuth+Additions.h"
#import "NSData+Base64.h"
#import <CommonCrypto/CommonHMAC.h>

static NSInteger SortParameter(NSString *key1, NSString *key2, void *context) {
	NSComparisonResult r = [key1 compare:key2];
	if(r == NSOrderedSame) { // compare by value in this case
		NSDictionary *dict = (NSDictionary *)context;
		NSString *value1 = [dict objectForKey:key1];
		NSString *value2 = [dict objectForKey:key2];
		return [value1 compare:value2];
	}
	return r;
}

static NSData *HMAC_SHA1(NSString *data, NSString *key) {
	unsigned char buf[CC_SHA1_DIGEST_LENGTH];
	CCHmac(kCCHmacAlgSHA1, [key UTF8String], [key length], [data UTF8String], [data length], buf);
	return [NSData dataWithBytes:buf length:CC_SHA1_DIGEST_LENGTH];
}

NSString *OAuthorizationHeader(NSURL *url, NSString *method, NSData *body, NSString *_oAuthConsumerKey, NSString *_oAuthConsumerSecret,
                               NSString *_oAuthToken, NSString *_oAuthTokenSecret,
                               // 2013.3.3 追加
                               NSString *_oAuthVerifier)
{
	NSString *_oAuthNonce = [NSString ab_GUID];
	NSString *_oAuthTimestamp = [NSString stringWithFormat:@"%d", (int)[[NSDate date] timeIntervalSince1970]];
	NSString *_oAuthSignatureMethod = @"HMAC-SHA1";
	NSString *_oAuthVersion = @"1.0";
    
    // 2013.02.06 mod mirie
    // 2013.3.3 再修正
    NSString *_oAuthCallback;
    if ([_oAuthToken isEqualToString:@""] ) {
        _oAuthCallback = @"oob";
    }
    else {
        _oAuthCallback = @"";
    }
	
	NSMutableDictionary *oAuthAuthorizationParameters = [NSMutableDictionary dictionary];
	[oAuthAuthorizationParameters setObject:_oAuthNonce forKey:@"oauth_nonce"];
	[oAuthAuthorizationParameters setObject:_oAuthTimestamp forKey:@"oauth_timestamp"];
	[oAuthAuthorizationParameters setObject:_oAuthSignatureMethod forKey:@"oauth_signature_method"];
	[oAuthAuthorizationParameters setObject:_oAuthVersion forKey:@"oauth_version"];
	[oAuthAuthorizationParameters setObject:_oAuthConsumerKey forKey:@"oauth_consumer_key"];
    
    // 2013.3.3 復活
	//if(_oAuthToken)
    // _oAuthTokenがブランクじゃない時は、oAuthTokenをOAuthのパラメータに渡したいとき。そのときはセットする。
    if(![_oAuthToken isEqualToString:@""])
		[oAuthAuthorizationParameters setObject:_oAuthToken forKey:@"oauth_token"];
    
    
    // 2013.02.06 mod mirie
    if (![_oAuthCallback isEqualToString:@""])
        [oAuthAuthorizationParameters setObject:_oAuthCallback forKey:@"oauth_callback"];
    
    
    // 2013.3.3 追加
    if (![_oAuthVerifier isEqualToString:@""])
        [oAuthAuthorizationParameters setObject:_oAuthVerifier forKey:@"oauth_verifier"];
    
	
	// get query and body parameters
	NSDictionary *additionalQueryParameters = [NSURL ab_parseURLQueryString:[url query]];
	NSDictionary *additionalBodyParameters = nil;
	if(body) {
		NSString *string = [[[NSString alloc] initWithData:body encoding:NSUTF8StringEncoding] autorelease];
        
#ifdef MYDEBUG
        NSLog(@"string of body : %@", string);
#endif
        
		if(string) {
            // 2013.6.29  ab_parseURLQueryString って、URL文中の形にエンコードされたパラメータを、元の形にデコードするルーチンみたい。
            // なんで元の形に戻すの？　いや、それでいいみたい。
			additionalBodyParameters = [NSURL ab_parseURLQueryString:string];
		}
	}
    
    //check body
#ifdef MYDEBUG
    NSLog(@"additionalBodyParameters : %@",[additionalBodyParameters description]);
#endif
	
	// combine all parameters
	NSMutableDictionary *parameters = [[oAuthAuthorizationParameters mutableCopy] autorelease];
	if(additionalQueryParameters) [parameters addEntriesFromDictionary:additionalQueryParameters];
	if(additionalBodyParameters) [parameters addEntriesFromDictionary:additionalBodyParameters];
    
#ifdef MYDEBUG
    NSLog(@"parameters : %@",[parameters description]);
#endif
	
	// -> UTF-8 -> RFC3986
	NSMutableDictionary *encodedParameters = [NSMutableDictionary dictionary];
    
    /*
     for(NSString *key in parameters) {
     NSString *value = [parameters objectForKey:key];
     [encodedParameters setObject:[value ab_RFC3986EncodedString] forKey:[key ab_RFC3986EncodedString]];
     }
     */
    
    // 2013.3.19(tue)  value of the key=oauth_token is not be encoded because it is already encoded.
    // この取り出し方って？
    
    for(NSString *key in parameters) {
		NSString *value = [parameters objectForKey:key];
        
#ifdef MYDEBUG
        NSLog(@"key : %@ ,   value : %@ ¥n", key, value);
#endif
        
        /* 2013.4.9(tue) oauth_token だけ特別扱いは、やめ。
         if ( ![key isEqualToString:@"oauth_token"]){
         //NSLog(@" not oauth_token  ¥n");
         [encodedParameters setObject:[value ab_RFC3986EncodedString] forKey:[key ab_RFC3986EncodedString]];
         //[encodedParameters setObject:value  forKey:[key ab_RFC3986EncodedString]];
         }
         else {
         //NSLog(@" match oauth_token  ¥n");
         [encodedParameters setObject:value forKey:[key ab_RFC3986EncodedString]];
         }
         */
        
        [encodedParameters setObject:[value ab_RFC3986EncodedString] forKey:[key ab_RFC3986EncodedString]];
	}
    
#ifdef MYDEBUG
    NSLog(@"encoded Parameters : %@",[encodedParameters description]);
#endif
    
	
	NSArray *sortedKeys = [[encodedParameters allKeys] sortedArrayUsingFunction:SortParameter context:encodedParameters];
	
	NSMutableArray *parameterArray = [NSMutableArray array];
    
    
	for(NSString *key in sortedKeys) {
		[parameterArray addObject:[NSString stringWithFormat:@"%@=%@", key, [encodedParameters objectForKey:key]]];
	}
    
    
	NSString *normalizedParameterString = [parameterArray componentsJoinedByString:@"&"];
	
	NSString *normalizedURLString = [NSString stringWithFormat:@"%@://%@%@", [url scheme], [url host], [url path]];
	
	NSString *signatureBaseString = [NSString stringWithFormat:@"%@&%@&%@",
									 [method ab_RFC3986EncodedString],
									 [normalizedURLString ab_RFC3986EncodedString],
                                     
                                     [normalizedParameterString ab_RFC3986EncodedString]];
    // 2013.3.28 なんでここでも3986エンコーディングしてる？２度目じゃないの？
    // normalizedParameterString];
    
#ifdef MYDEBUG
    NSLog(@"signature_base_str : %@",signatureBaseString);
#endif
    
    // 2013.3.3 修正
    
    NSString *key;
    
    //if (_oAuthTokenSecret) {
    if (![_oAuthTokenSecret isEqualToString:@""]) {
        key = [NSString stringWithFormat:@"%@&%@",
               [_oAuthConsumerSecret ab_RFC3986EncodedString],
               [_oAuthTokenSecret ab_RFC3986EncodedString]];
    }
    else {
        key = [NSString stringWithFormat:@"%@&%@",
               [_oAuthConsumerSecret ab_RFC3986EncodedString],
               @""];
    }
    
#ifdef MYDEBUG
    NSLog(@"key = %@",key);
#endif
	
	NSData *signature = HMAC_SHA1(signatureBaseString, key);
	NSString *base64Signature = [signature base64EncodedString];
	
	NSMutableDictionary *authorizationHeaderDictionary = [[oAuthAuthorizationParameters mutableCopy] autorelease];
	[authorizationHeaderDictionary setObject:base64Signature forKey:@"oauth_signature"];
	
	NSMutableArray *authorizationHeaderItems = [NSMutableArray array];
	for(NSString *key in authorizationHeaderDictionary) {
		NSString *value = [authorizationHeaderDictionary objectForKey:key];
		[authorizationHeaderItems addObject:[NSString stringWithFormat:@"%@=\"%@\"",
											 [key ab_RFC3986EncodedString],
											 [value ab_RFC3986EncodedString]]];
	}
	
	NSString *authorizationHeaderString = [authorizationHeaderItems componentsJoinedByString:@", "];
	authorizationHeaderString = [NSString stringWithFormat:@"OAuth %@", authorizationHeaderString];
	
	return authorizationHeaderString;
}






// 2013.5.28(tue)
//NSString *OAuthorizationHeader4Access(NSURL *url, NSString *method, NSData *body, NSString *_oAuthConsumerKey, NSString
NSString *OAuthorizationHeader4Access(NSURL *url, NSString *method, NSString *_oAuthConsumerKey, NSString *_oAuthConsumerSecret,
                                      NSString *_oAuthAccessCredential,    NSString *_oAuthAccessSecret)


{
	NSString *_oAuthNonce = [NSString ab_GUID];
	NSString *_oAuthTimestamp = [NSString stringWithFormat:@"%d", (int)[[NSDate date] timeIntervalSince1970]];
	NSString *_oAuthSignatureMethod = @"HMAC-SHA1";
	NSString *_oAuthVersion = @"1.0";
	
	NSMutableDictionary *oAuthAuthorizationParameters = [NSMutableDictionary dictionary];
	[oAuthAuthorizationParameters setObject:_oAuthNonce forKey:@"oauth_nonce"];
	[oAuthAuthorizationParameters setObject:_oAuthTimestamp forKey:@"oauth_timestamp"];
	[oAuthAuthorizationParameters setObject:_oAuthSignatureMethod forKey:@"oauth_signature_method"];
	[oAuthAuthorizationParameters setObject:_oAuthVersion forKey:@"oauth_version"];
	[oAuthAuthorizationParameters setObject:_oAuthConsumerKey forKey:@"oauth_consumer_key"];
    

    if(![_oAuthAccessCredential isEqualToString:@""])
		[oAuthAuthorizationParameters setObject:_oAuthAccessCredential forKey:@"oauth_token"];
    
	
	// get query and body parameters
	NSDictionary *additionalQueryParameters = [NSURL ab_parseURLQueryString:[url query]];
	NSDictionary *additionalBodyParameters = nil;
    /*
	if(body) {
		NSString *string = [[[NSString alloc] initWithData:body encoding:NSUTF8StringEncoding] autorelease];
		if(string) {
			additionalBodyParameters = [NSURL ab_parseURLQueryString:string];
		}
	}
     */
	
	// combine all parameters
	NSMutableDictionary *parameters = [[oAuthAuthorizationParameters mutableCopy] autorelease];
	if(additionalQueryParameters) [parameters addEntriesFromDictionary:additionalQueryParameters];
	if(additionalBodyParameters) [parameters addEntriesFromDictionary:additionalBodyParameters];
	
	// -> UTF-8 -> RFC3986
	NSMutableDictionary *encodedParameters = [NSMutableDictionary dictionary];
    
    
    // 2013.3.19(tue)  value of the key=oauth_token is not be encoded because it is already encoded.
    // この取り出し方って？
    
    for(NSString *key in parameters) {
		NSString *value = [parameters objectForKey:key];
        
#ifdef MYDEBUG
        NSLog(@"key : %@ ,   value : %@ ¥n", key, value);
#endif
        
        [encodedParameters setObject:[value ab_RFC3986EncodedString] forKey:[key ab_RFC3986EncodedString]];
	}
    
#ifdef MYDEBUG
    NSLog(@"encoded Parameters : %@",[encodedParameters description]);
#endif
    
	
	NSArray *sortedKeys = [[encodedParameters allKeys] sortedArrayUsingFunction:SortParameter context:encodedParameters];
	
	NSMutableArray *parameterArray = [NSMutableArray array];
    
    
	for(NSString *key in sortedKeys) {
		[parameterArray addObject:[NSString stringWithFormat:@"%@=%@", key, [encodedParameters objectForKey:key]]];
	}
    
    
	NSString *normalizedParameterString = [parameterArray componentsJoinedByString:@"&"];
	
	NSString *normalizedURLString = [NSString stringWithFormat:@"%@://%@%@", [url scheme], [url host], [url path]];
	
	NSString *signatureBaseString = [NSString stringWithFormat:@"%@&%@&%@",
									 [method ab_RFC3986EncodedString],
									 [normalizedURLString ab_RFC3986EncodedString],
                                     [normalizedParameterString ab_RFC3986EncodedString]];
    // 2013.3.28 なんでここでも3986エンコーディングしてる？２度目じゃないの？
    // normalizedParameterString];
    
#ifdef MYDEBUG
    NSLog(@"signature_base_str : %@",signatureBaseString);
#endif
    
    // 2013.3.3 修正
    
    NSString *key;
    
    //if (_oAuthTokenSecret) {
    if (![_oAuthAccessCredential isEqualToString:@""]) {
        key = [NSString stringWithFormat:@"%@&%@",
               [_oAuthConsumerSecret ab_RFC3986EncodedString],
               [_oAuthAccessSecret ab_RFC3986EncodedString]];
    }
    else {
        key = [NSString stringWithFormat:@"%@&%@",
               [_oAuthConsumerSecret ab_RFC3986EncodedString],
               @""];
    }
    
	
	NSData *signature = HMAC_SHA1(signatureBaseString, key);
	NSString *base64Signature = [signature base64EncodedString];
	
	NSMutableDictionary *authorizationHeaderDictionary = [[oAuthAuthorizationParameters mutableCopy] autorelease];
	[authorizationHeaderDictionary setObject:base64Signature forKey:@"oauth_signature"];
	
	NSMutableArray *authorizationHeaderItems = [NSMutableArray array];
	for(NSString *key in authorizationHeaderDictionary) {
		NSString *value = [authorizationHeaderDictionary objectForKey:key];
		[authorizationHeaderItems addObject:[NSString stringWithFormat:@"%@=\"%@\"",
											 [key ab_RFC3986EncodedString],
											 [value ab_RFC3986EncodedString]]];
	}
	
	NSString *authorizationHeaderString = [authorizationHeaderItems componentsJoinedByString:@", "];
	authorizationHeaderString = [NSString stringWithFormat:@"OAuth %@", authorizationHeaderString];
	
	return authorizationHeaderString;
}
 




