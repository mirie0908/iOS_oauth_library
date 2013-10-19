//
//  MyChores.m
//  OAuthCore_test
//
//  Created by 入江 昌信 on 2013/02/13.
//  Copyright (c) 2013年 入江 昌信. All rights reserved.
//

#import "MyChores.h"

@implementation MyChores

-(NSMutableDictionary *) responseString2Dict: (NSString *) str {
    
    NSArray *array = [str componentsSeparatedByString:@"&"];
    
    NSEnumerator *enumerator = [array objectEnumerator];
    NSString *aStr;
    NSArray *aAry;
    
    NSMutableDictionary *dict = [[[NSMutableDictionary alloc] init] autorelease];
    
    while (aStr = [enumerator nextObject]) {
        /* code to act on each element as it is returned */
        
        aAry = [aStr componentsSeparatedByString:@"="];
        [dict setObject:[aAry objectAtIndex:1] forKey:[aAry objectAtIndex:0]];
        
    }
    
    return dict;
}

+(NSString *) getTimestamp {
    // 次のフォーマットで現時刻のタイムスタンプの文字列を返す。
    // yyyy-MM-ddhh:mm:ss+09:00
    // timezone取得
    
    NSTimeZone *tz = [NSTimeZone systemTimeZone];
    
    //NSLog(@"timezone = %@",[tz description]);
    
    
    
    // date formatter
    
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    
    [df setTimeZone:tz];
    
    [df setDateFormat:@"yyyy'-'MM'-'dd'T'hh:mm:ssZ"];
    
    
    
    NSDate *today = [NSDate date];
    NSString *retstr = [df stringFromDate:today];
    
    //NSLog(@"today = %@",[today description]);
    
    //NSLog(@"fomatted date = %@",[df stringFromDate:today]);
    
    [df release];
    
    return retstr;
    
    
}

@end