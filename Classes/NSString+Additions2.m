//
//  NSString+Additions2.m
//  test_libraries
//
//  Created by 入江 昌信 on 2013/03/30.
//  Copyright (c) 2013年 入江 昌信. All rights reserved.
//

#import "NSString+Additions2.h"

@implementation NSString (Additions2)

- (NSString *) RFC3986DecordingString {
    
    NSMutableString *result = [NSMutableString string];
    unsigned char c;
    NSInteger index;
    NSRange range;
    unsigned int result_int;
    
    for(index = 0; index < self.length; index++) {
        c = [self characterAtIndex:index];
        
        if (c != '%') {
            [result appendFormat:@"%c",c];
        }
        else {
            range = NSMakeRange(index + 1,2);
            NSMutableString *encoded_substr = [NSMutableString string];
            [encoded_substr appendFormat:@"%@",@"#"];
            
            [encoded_substr appendFormat:@"%@",[self substringWithRange:range]];
            //NSLog(@"*** encoded_substr : %@",encoded_substr);
            NSScanner *scanner = [NSScanner scannerWithString:encoded_substr];
            [scanner setScanLocation:1]; // skip '#'
            [scanner scanHexInt:&result_int];
            //result_int = 61;
            //NSLog(@"*** result_int : %d",result_int);
            
            [result appendFormat:@"%c",(char)result_int];
            index = index + 2;
        }
    }
    
    return result;
    
}

@end
