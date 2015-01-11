//
//  NGAsyncRTMPSocket.h
//  RTMPClientSample
//
//  Created by Nitin Gupta on 6/24/14.
//  Copyright (c) 2014 Nitin Gupta. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NGRTMPConstant.h"

@class NGAsyncPacket;

@protocol NGAsyncRTMPSocketDelegate <NSObject>
@required
- (void)onResponse:(NGAsyncPacket*)response;
- (void)onStreamResponse:(NGAsyncPacket*)response;
- (void)onConnect:(BOOL)_status;
- (void)onDisconnect:(BOOL)_status;
@end

@interface NGAsyncRTMPSocket : NSObject <NSStreamDelegate> {
    NSInputStream   *_inputStream;
    NSOutputStream  *_outputStream;
    
    NSMutableArray  *_sendingDataList;
    NSMutableData   *_incompleteData;
    NSString        *_serverHost;
    
    BOOL            _waitingForData;
}

@property (nonatomic, strong) id<NGAsyncRTMPSocketDelegate> delegate;

- (void)setupNetworkCommunicationWithDelegate:(id <NGAsyncRTMPSocketDelegate>)d andHost:(NSString *)h;
- (void)sendData:(NSData*)data;
- (void)disconnect;
@end
