//
//  NGUtilities.m
//  RTMPClientSample
//
//  Created by Nitin Gupta on 7/4/14.
//  Copyright (c) 2014 Nitin Gupta. All rights reserved.
//

#import "NGUtilities.h"
#import <CommonCrypto/CommonHMAC.h>

@implementation NGUtilities

+(NSString*)getCurrentUTCTimeFormattedStamp {
    NSDate *date = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSTimeZone *timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
    [dateFormatter setTimeZone:timeZone];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"];
    NSString *dateString = [dateFormatter stringFromDate:date];
    dateFormatter = nil;
    return dateString;
}

+(NSString*)getUTCTimeFormattedStamp:(NSDate*)date {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSTimeZone *timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
    [dateFormatter setTimeZone:timeZone];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"];
    NSString *dateString = [dateFormatter stringFromDate:date];
    dateFormatter = nil;
    return dateString;
}

+(NSString*)sign:(NSMutableDictionary *)dict secretKey:(NSString*)secretKey {
    NSArray *allKeys = [dict allKeys];
    NSArray *sortedKeys = [allKeys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    NSMutableString *dataString  = [NSMutableString string];
    for(NSString *key in sortedKeys) {
        [dataString appendFormat:@"%@%@",key,[dict objectForKey:key]];
    }
    
    NSData *secretData = [secretKey dataUsingEncoding:NSUTF8StringEncoding];
    NSData *clearTextData = [dataString dataUsingEncoding:NSUTF8StringEncoding];
    
    unsigned char result[20];
	CCHmac(kCCHmacAlgSHA1, [secretData bytes], [secretData length], [clearTextData bytes], [clearTextData length], result);
    
    NSData *theData = [NSData dataWithBytes:result length:20];
    
    NSString *encodedResult = [[NSString alloc] initWithData:theData encoding:NSASCIIStringEncoding];
    
    NSString * encodedString = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
                                                                                   NULL,
                                                                                   (CFStringRef)encodedResult,
                                                                                   NULL,
                                                                                   (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                                   kCFStringEncodingUTF8 ));
    
    encodedResult = nil;
    
    return encodedString;
}

@end
