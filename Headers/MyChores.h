//
//  MyChores.h
//  OAuthCore_test
//
//  Created by 入江 昌信 on 2013/02/13.
//  Copyright (c) 2013年 入江 昌信. All rights reserved.
//
// いろいろ雑用こなすクラス

#import <Foundation/Foundation.h>

@interface MyChores : NSObject

-(NSMutableDictionary *) responseString2Dict: (NSString *) str;

+(NSString *) getTimestamp;

@end