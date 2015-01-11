//
//  NGUtilities.h
//  RTMPClientSample
//
//  Created by Nitin Gupta on 7/4/14.
//  Copyright (c) 2014 Nitin Gupta. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NGUtilities : NSObject

+(NSString*)getCurrentUTCTimeFormattedStamp;

+(NSString*)getUTCTimeFormattedStamp:(NSDate*)date;

+(NSString*)sign:(NSMutableDictionary *)dict secretKey:(NSString*)secretKey;
    
@end
