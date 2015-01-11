//
//  NGRTMPClient.h
//  RTMPClientSample
//
//  Created by Nitin Gupta on 7/4/14.
//  Copyright (c) 2014 Nitin Gupta. All rights reserved.
//

#import <Foundation/Foundation.h>
@interface NGRTMPClient : NSObject {

}
@property (nonatomic, copy, getter = getSecretKey) NSString *secretKey;
@property (nonatomic, copy, getter = getAPIKey) NSString *apiKey;

+(instancetype)sharedRTMPClient;

-(BOOL)initRTMPCilentForHostAddress:(NSString *)host anAPIKey:(NSString *)aKey andSecretKey:(NSString *)sKey;


@end
