//
//  OAuthCore.h
//  hatena_oauth_app_single
//
//  Created by 入江 昌信 on 2013/04/25.
//  Copyright (c) 2013年 入江 昌信. All rights reserved.
//

#ifndef hatena_oauth_app_single_OAuthCore_h
#define hatena_oauth_app_single_OAuthCore_h

//
//  OAuthCore.h
//
//  Created by Loren Brichter on 6/9/10.
//  Copyright 2010 Loren Brichter. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *OAuthorizationHeader(NSURL *url,
									  NSString *method,
									  NSData *body,
									  NSString *_oAuthConsumerKey,
									  NSString *_oAuthConsumerSecret,
                                      // 2013.3.3 元に戻す
									  NSString *_oAuthToken,
									  NSString *_oAuthTokenSecret,
                                      
                                      // 2013.3.3 追加
                                      NSString *_oAuthVerifier);


extern NSString *OAuthorizationHeader4Access(NSURL *url,
                                            NSString *method,

                                            // consumer credential
                                            NSString *_oAuthConsumerKey,
                                            NSString *_oAuthConsumerSecret,

                                            // access credential
                                            NSString *_oAuthAccessCredential,
                                            NSString *_oAuthAccessSecret
                                            );
 



#endif
