//
//  NGRTMPConstant.h
//  RTMPClientSample
//
//  Created by Nitin Gupta on 7/2/14.
//  Copyright (c) 2014 Nitin Gupta. All rights reserved.
//

#import <Foundation/Foundation.h>

#define SEND_QUEUE_CAPACITY	  5
#define RECEIVE_QUEUE_CAPACITY 5

#define DEFAULT_MAX_RECEIVE_BUFFER_SIZE 9216

#define API_KEY  @"apikey"
#define SIGNATURE_KEY @"signature"

#define PORT 12346

typedef NS_ENUM(NSUInteger, RequestMode) {
    REQUEST,
    RESPONSE,
    STREAM,
};

typedef NS_ENUM(NSUInteger, ServiceType) {
    AUTH,
    STREAMING,
};

typedef NS_ENUM(NSUInteger, DataType) {
    FLAT_STRING,
    BINARY,
    JSON,
};

typedef NS_ENUM(NSUInteger, MessageType) {
    MSG_UNDEFINED,
    MSG_VIDEO,
    MSG_AUDIO,
};
