//
//  NGRTMPClient.m
//  RTMPClientSample
//
//  Created by Nitin Gupta on 7/4/14.
//  Copyright (c) 2014 Nitin Gupta. All rights reserved.
//

#import "NGRTMPClient.h"
#import "NGAsyncRTMPSocket.h"
#import "NGUtilities.h"

static NGRTMPClient *_sharedInstance = nil;
@interface NGRTMPClient ()<NGAsyncRTMPSocketDelegate> {
    NGAsyncRTMPSocket *_socket;
}
@end

@implementation NGRTMPClient
@synthesize secretKey = _secretKey;
@synthesize apiKey  =_apiKey;

+(instancetype)sharedRTMPClient {
    return _sharedInstance;
}

-(BOOL)initRTMPCilentForHostAddress:(NSString *)host anAPIKey:(NSString *)aKey andSecretKey:(NSString *)sKey{
    BOOL _result = false;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[NGRTMPClient alloc] init];
        [_sharedInstance setSecretKey:sKey];
        [_sharedInstance setApiKey:aKey];
        _socket = [[NGAsyncRTMPSocket alloc] init];
        [_socket setupNetworkCommunicationWithDelegate:self andHost:host];
    });
    return _result;
}

#pragma mark - NGAsyncRTMPSocketDelegate Related
- (void)onResponse:(NGAsyncPacket*)response {
    NSLog(@"%s, Response = %@",__FUNCTION__, response);

}

- (void)onStreamResponse:(NGAsyncPacket*)response {
    NSLog(@"%s, Response = %@",__FUNCTION__, response);
}

- (void)onConnect:(BOOL)_status {
    NSLog(@"%s",__FUNCTION__);
}

- (void)onDisconnect:(BOOL)_status {
    NSLog(@"%s",__FUNCTION__);
}

@end
