//
//  NGAsyncRTMPSocket.m
//  RTMPClientSample
//
//  Created by Nitin Gupta on 6/24/14.
//  Copyright (c) 2014 Nitin Gupta. All rights reserved.
//

#import "NGAsyncRTMPSocket.h"
#import "NGUtilities.h"
#import "NGRTMPClient.h"
#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>
#import <sys/ioctl.h>
#import <net/if.h>
#import <netdb.h>

#pragma mark -
#pragma mark - --NGAsyncPacket--
#pragma mark -
@interface NGAsyncPacket : NSObject {

}
@property(nonatomic,assign)Byte type;
@property(nonatomic,assign)Byte reserved;
@property (nonatomic,assign)Byte streamID;
@property(nonatomic,assign)Byte payloadType;
@property(nonatomic,assign)int payloadSize;
@property(retain) NSData* payload;

@end

@implementation NGAsyncPacket

-(id)init {
    if (self=[super init]) {
        _payload=nil;
    }
    return self;
}

-(void)dealloc {
        self.payload = nil;
}

@end

#pragma mark -
#pragma mark - --NGAsyncSendPacket--
#pragma mark -
@interface NGAsyncSendPacket : NGAsyncPacket

@property(nonatomic,assign)Byte requestType;
@property(nonatomic,assign)int sessionId;
@property(nonatomic,assign)int requestId;

@end

@implementation NGAsyncSendPacket
@end

#pragma mark -
#pragma mark - --NGAsyncReceivePacket--
#pragma mark -
@interface NGAsyncReceivePacket : NGAsyncPacket

@property Byte result;
@property Byte requestType;

@end

@implementation NGAsyncReceivePacket
+(instancetype)createResponse {
    return [[self alloc] init];
}

@end

#pragma mark -
#pragma mark - --NGAsyncPacketEncoder--
#pragma mark -
@interface NGAsyncPacketEncoder : NSObject
+(NSMutableData*)buildAuthMessage:(NSDictionary*)d;

@end

@implementation NGAsyncPacketEncoder

+(NSMutableData*)buildAuthMessage:(NSDictionary *)d {
    int msgStreamId = 0;
    int srvType = AUTH;
    int reqModeType = REQUEST;
    int dataFormate = BINARY;
    int msgType = MSG_UNDEFINED;
    unsigned char reserved = 0;
    NSData *tsData = [[NGUtilities getCurrentUTCTimeFormattedStamp] dataUsingEncoding:NSUTF8StringEncoding];
    const void*tsBytes = (const void *)[tsData bytes];

    
    NSMutableDictionary *_mDict = [NSMutableDictionary dictionaryWithDictionary:d];
    //Creating Signature for AUTHENTICATION
    NSString *_secretKey = [[NGRTMPClient sharedRTMPClient] getSecretKey];
    NSString *_apiKey = [[NGRTMPClient sharedRTMPClient] getAPIKey];
    [_mDict setValue:_apiKey forKey:API_KEY];
    NSString *signature = [NGUtilities sign:_mDict secretKey:_secretKey];
    [_mDict setObject:signature forKey:SIGNATURE_KEY];
    
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:d options:0 error:&error];
    
    
    uint32_t jsonSize = (int)[jsonData length];
    uint32_t jsonSizeNetwork = CFSwapInt32HostToBig(jsonSize);
    
    NSMutableData *_mData = [NSMutableData dataWithCapacity:(18+jsonSize)];
    
    // construct protocol header
    [_mData appendBytes:&msgStreamId length:4];
    [_mData appendBytes:&srvType length:1];
    [_mData appendBytes:&reqModeType length:1];
    [_mData appendBytes:&dataFormate length:1];
    [_mData appendBytes:&msgType length:1];
    [_mData appendBytes:&reserved length:2];
    [_mData appendBytes:&tsBytes length:4];
    [_mData appendBytes:&jsonSizeNetwork length:4];
    
    // construct bytes
    [_mData appendData: jsonData];
    
    return _mData;
}

@end
#pragma mark -
#pragma mark - --NGAsyncPacketDecoder--
#pragma mark -
@interface NGAsyncPacketDecoder : NSObject  {
    
}
+(NGAsyncPacket*) decode:(NSData*)data;
+(bool) canDecode:(NSData*)data;
@end

@implementation NGAsyncPacketDecoder

+(NGAsyncPacket*) decode:(NSData*)data {
    unsigned char *bytePtr = (unsigned char *)data.bytes;
    // construct protocol headers
    Byte _type = bytePtr[0];
    if(_type == RESPONSE || _type == STREAM){
        NGAsyncReceivePacket* response = [NGAsyncReceivePacket createResponse];
        
        response.type = bytePtr[0];
        response.requestType = bytePtr[1];
        response.result = bytePtr[2];
        response.reserved = bytePtr[3];
        response.payloadType = bytePtr[4];
        
        // construct payload size
        int payloadSize = 0;
        memcpy(&payloadSize, bytePtr+5, 4);
        payloadSize = CFSwapInt32BigToHost(payloadSize);
        response.payloadSize = payloadSize;
        
        // construct actual payload
        response.payload = [NSData dataWithBytes:(bytePtr+9) length:payloadSize];
        
        return response;
    } else {
        return nil;
    }
}

+(bool) canDecode:(NSData*)data {
    unsigned char *bytePtr = (unsigned char *)data.bytes;
    // construct protocol headers
    if(bytePtr[0] == RESPONSE) {
        // construct payload size
        int payloadSize = 0;
        memcpy(&payloadSize, bytePtr+5, 4);
        payloadSize = CFSwapInt32BigToHost(payloadSize);
        if((payloadSize+9) > data.length) {
            return false;
        }
    }
    return true;
}

@end

#pragma mark -
#pragma mark - --NGAsyncRTMPSocket--
#pragma mark -

@implementation NGAsyncRTMPSocket
@synthesize delegate = _delegate;

- (void)setupNetworkCommunicationWithDelegate:(id <NGAsyncRTMPSocketDelegate>)d andHost:(NSString *)h {
    _delegate = d;
    _serverHost = [h copy];
    _sendingDataList = [[NSMutableArray alloc]init];
    _waitingForData = false;
	CFReadStreamRef readStream;
	CFWriteStreamRef writeStream;
    CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef)_serverHost, PORT, &readStream, &writeStream);
	_inputStream = (__bridge NSInputStream *)readStream;
	_outputStream = (__bridge NSOutputStream *)writeStream;
	[_inputStream setDelegate:self];
	[_outputStream setDelegate:self];
	[_inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[_outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[_inputStream open];
	[_outputStream open];
}

-(void)disconnect {
    [_inputStream close];
    _inputStream = nil;
    [_outputStream close];
    _outputStream = nil;
    _incompleteData = nil;
    _sendingDataList = nil;
}

- (void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)streamEvent {
	switch (streamEvent) {
		case NSStreamEventOpenCompleted:
            if(theStream == _outputStream)
            {
                [_delegate onConnect:true];
            }
			break;
            
        case NSStreamEventHasSpaceAvailable: {
            if(theStream == _outputStream) {
                if ([_sendingDataList count] > 0) {
                    NSData *data = [_sendingDataList firstObject];
                    [_outputStream write:[data bytes] maxLength:[data length]];
                    [_sendingDataList removeObject:data];
                }
            }
        } break;
            
		case NSStreamEventHasBytesAvailable: {
			if (theStream == _inputStream) {
				uint8_t streamBuf[2048];
				int len;
				if ([_inputStream hasBytesAvailable]) {
					len = (int)[_inputStream read:streamBuf maxLength:sizeof(streamBuf)];
                    if(len < 0) {
                        break;
                    }
                    uint32_t numDecoded = 0;
                    NSMutableData *dataToDecode;
                    if (_waitingForData) {
                        uint32_t readLen = len;
                        len = readLen + (int)_incompleteData.length;
                        dataToDecode = [NSMutableData dataWithBytes:_incompleteData.bytes length:_incompleteData.length];
                        [dataToDecode appendBytes:(streamBuf) length:readLen];
                        _waitingForData = false;
                    } else {
                        dataToDecode = [NSMutableData dataWithCapacity:len];
                        [dataToDecode appendBytes:(streamBuf) length:len];
                    }
                    
                    uint8_t bufferToDecode[dataToDecode.length];
                    memcpy(bufferToDecode, dataToDecode.bytes, dataToDecode.length);
					while (len > numDecoded) {
                        NSMutableData *workingData = [NSMutableData dataWithCapacity:len-numDecoded];
                        [workingData appendBytes:(bufferToDecode+numDecoded) length:len-numDecoded];
                        
                        bool canDecodeData = [NGAsyncPacketDecoder canDecode:workingData];
                        if (canDecodeData) {
                            NGAsyncPacket *message = [NGAsyncPacketDecoder decode:workingData];
                            if(message.type == RESPONSE) {
                                [_delegate onResponse:(NGAsyncPacket*)message];
                            } else if (message.type == STREAM){
                                [_delegate onStreamResponse:(NGAsyncPacket*)message];
                            }
                            numDecoded += 9 + message.payloadSize;
                        } else {
                            _incompleteData = [workingData mutableCopy];
                            _waitingForData = true;
                            break;
                        }
					}
				}
			}
        } break;
            
		case NSStreamEventErrorOccurred: {
            [theStream close];
            theStream = nil;
            [_delegate onConnect:false];
        } break;
			
		case NSStreamEventEndEncountered: {
            [_delegate onDisconnect:YES];
            [theStream close];
            [theStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
            theStream = nil;
			
        } break;
		default: {
			NSLog(@"Unknown event");
        } break;
	}
}

-(void)dealloc {
    [self disconnect];
}

- (void)sendData:(NSData *)data {
    [_sendingDataList addObject:data];
    if([_outputStream hasSpaceAvailable]){
        if ([_sendingDataList count]!=0) {
            NSData *data = [_sendingDataList firstObject];
            [_outputStream write:[data bytes] maxLength:[data length]];
            [_sendingDataList removeObject:data];
        }
    }
}

@end
