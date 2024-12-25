//
//  USBClient.m
//  WireDrop
//
//  Created by Anton Meier on 2020-09-04.
//

#import "USBClient.h"
#import <UIKit/UIKit.h>
#import "USBProtocol.h"
#import "PTChannel.h"
#import "WCLog.h"
#import "USBDispatchData.h"
#import <sys/sysctl.h>

@interface USBClient () <PTChannelDelegate>
{
    PTChannel *serverChannel;
    PTChannel *peerChannel;
    dispatch_queue_t _sendQueue;
}

@property(weak, nonatomic, nullable) id<USBClientDelegate> delegate;

@end

@implementation USBClient

- (instancetype)initWithConfiguration:(USBClientConfiguration *)configuration delegate:(id<USBClientDelegate>)delegate;
{
    self = [super init];
    
    if (self)
    {
        _configuration = configuration;
        _delegate = delegate;
        _sendQueue =  dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    }
    
    return self;
}

- (void)startSocket:(void (^)(NSError * _Nullable error))completion;
{
    PTChannel *channel = [PTChannel channelWithDelegate:self];
    
    [channel listenOnPort:WCPTProtocolIPv4PortNumber IPv4Address:INADDR_LOOPBACK callback:^(NSError *error)
     {
        if (error)
        {
            WCLog(@"Failed to listen on 127.0.0.1:%d: %@", WCPTProtocolIPv4PortNumber, error);
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(error);
            });
        }
        else
        {
            WCLog(@"Listening on 127.0.0.1:%d", WCPTProtocolIPv4PortNumber);
            self->serverChannel = channel;
            WCLog(@"isListening: %d", self->serverChannel.isListening);
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(nil);
            });
        }
    }];
}

- (void)stopSocket;
{
    if (peerChannel)
    {
        WCLog(@"[peerChannel cancel];");
        [peerChannel close];
    }
    
    if (serverChannel)
    {
        WCLog(@"[serverChannel cancel];");
        [serverChannel close];
    }
}

- (void)sendData:(NSData *)data completion:(void (^)(NSError * _Nullable error))completion;
{
    if (peerChannel)
    {
        dispatch_async(_sendQueue, ^{
            dispatch_data_t payload = WCPTTextDispatchDataWithData(data);
            [self->peerChannel sendFrameOfType:WCPTFrameTypeRawData tag:PTFrameNoTag withPayload:payload callback:^(NSError *error) {
                if (error)
                {
                    WCLog(@"Failed to send raw data: %@", error);
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.delegate usbClient:self didFailToSendData:data];
                    });
                }
                
                if (completion != nil) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        completion(error);
                    });
                }
            }];
        });
    }
    else
    {
        WCLog(@"Can not send raw data — not connected");
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate usbClient:self didFailToSendData:data];
        });
    }
}

- (void)sendDataArray:(NSArray<NSData *> *)dataArr completion:(void (^)(NSError * _Nullable error))completion;
{
    if (peerChannel)
    {
        dispatch_async(_sendQueue, ^{
            dispatch_data_t payload = WCPTTextDispatchDataWithDataArray(dataArr);
            [self->peerChannel sendFrameOfType:WCPTFrameTypeRawData tag:PTFrameNoTag withPayload:payload callback:^(NSError *error) {
                if (error)
                {
                    WCLog(@"Failed to send raw data: %@", error);
                    // If needed, dispatch data failure here
                }
                
                if (completion != nil) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        completion(error);
                    });
                }
            }];
        });
    }
    else
    {
        WCLog(@"Can not send raw data — not connected");
        // If needed, dispatch data failure here
    }
}

- (void)sendDeviceIdentification;
{
    if (!peerChannel)
    {
        return;
    }
    
    WCLog(@"Sending device identification %@", peerChannel);
    
    NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:
                          self.configuration.identifier, @"identifier",
                          self.configuration.name ? self.configuration.name : @"Unknown Device", @"name",
                          self.configuration.hardwareMachine ? self.configuration.hardwareMachine : @"", @"model",
                          @(self.configuration.protocolVersion), @"pv",
                          @(self.configuration.minSupportedProtocolVersion), @"mspv",
                          @(self.configuration.clientType), @"ct",
                          nil];
    
    dispatch_data_t payload = [info createReferencingDispatchData];
    
    [peerChannel sendFrameOfType:WCPTFrameTypeDeviceIdentification tag:PTFrameNoTag withPayload:payload callback:^(NSError *error) {
        if (error)
        {
            WCLog(@"Failed to send WCPTFrameTypeDeviceInfo: %@", error);
            // If needed, dispatch identification failure here
        }
    }];
}

- (BOOL)ioFrameChannel:(PTChannel*)channel shouldAcceptFrameOfType:(uint32_t)type tag:(uint32_t)tag payloadSize:(uint32_t)payloadSize;
{
    if (channel != peerChannel)
    {
        // A previous channel that has been canceled but not yet ended. Ignore.
        return NO;
    }
    else if (type != WCPTFrameTypeDeviceIdentification && type != WCPTFrameTypeRawData)
    {
        WCLog(@"Unexpected frame of type %u", type);
        [channel close];
        return NO;
    }
    else
    {
        return YES;
    }
}

- (void)ioFrameChannel:(PTChannel*)channel didReceiveFrameOfType:(uint32_t)type tag:(uint32_t)tag payload:(PTData*)payload;
{
    if (type == WCPTFrameTypeDeviceIdentification)
    {
        NSDictionary *deviceInfo = [NSDictionary dictionaryWithContentsOfDispatchData:payload.dispatchData];
        
        USBServerConfiguration *config = [[USBServerConfiguration alloc] init];
        
        config.identifier = deviceInfo[@"identifier"];
        config.name = deviceInfo[@"name"];
        config.hardwareModel = deviceInfo[@"model"];
        config.protocolVersion = deviceInfo[@"pv"] ? [deviceInfo[@"pv"] unsignedIntValue] : 0;
        config.minSupportedProtocolVersion = deviceInfo[@"mspv"] ? [deviceInfo[@"mspv"] unsignedIntValue] : 0;
        config.clientType = deviceInfo[@"ct"] ? [deviceInfo[@"ct"] unsignedIntValue] : 0;
        
        WCLog(@"Identified server: %@ : %@, model: %@, pv: %u, mspv: %u", config.identifier, config.name, config.hardwareModel, config.protocolVersion, config.minSupportedProtocolVersion);
        
        self.connectedServer = config;
        
        // We may consider acknowledging that this has been received, so that the server don't start to send data too soon.
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.delegate && [self.delegate respondsToSelector:@selector(usbClient:didStartConnectionToServerWithConfiguration:)])
            {
                [self.delegate usbClient:self didStartConnectionToServerWithConfiguration:config];
            }
        });
    }
    else if (type == WCPTFrameTypeRawData && peerChannel)
    {
        WCPTDataFrame *textFrame = (WCPTDataFrame*)payload.data;
        textFrame->length = ntohl(textFrame->length);
        NSData *d = [NSData dataWithBytes:textFrame->data length:textFrame->length];
        
        // TODO: Investigate ways to avoid data copy
        WCLog(@"Got Frame: %@", d);
        [self.delegate usbClient:self gotDataPacket:d];
    }
    else
    {
        WCLog(@"Unknown: didReceiveFrameOfType: %u, %u, %@", type, tag, payload);
    }
}

- (void)ioFrameChannel:(PTChannel*)channel didEndWithError:(NSError*)error;
{
    USBServerConfiguration *justDisconnectedServer = self.connectedServer;
    
    self.connectedServer = nil;
    
    if (error)
    {
        WCLog(@"%@ ended with error: %@", channel, error);
        
        if ([@"NSPOSIXErrorDomain" isEqualToString:error.domain] && error.code == 57) // Socket is not connected
        {
            WCLog(@"Connection with server ended due to socket shutdown");
            WCLog(@"isListening: %d", self->serverChannel.isListening);
        }
    }
    else
    {
        WCLog(@"Disconnected from %@", channel.userInfo);
    }
    
    serverChannel = nil;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.delegate && [self.delegate respondsToSelector:@selector(usbClient:didEndConnectionWithError:)])
        {
            [self.delegate usbClient:self didEndConnectionWithError:error];
        }
    });
    
    if (justDisconnectedServer)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.delegate && [self.delegate respondsToSelector:@selector(usbClient:didEndConnectionToServerWithConfiguration:error:)])
            {
                [self.delegate usbClient:self didEndConnectionToServerWithConfiguration:justDisconnectedServer error:error];
            }
        });
    }
}

- (void)ioFrameChannel:(PTChannel*)channel didAcceptConnection:(PTChannel*)otherChannel fromAddress:(PTAddress*)address;
{
    if (peerChannel)
    {
        [peerChannel cancel];
    }
    
    peerChannel = otherChannel;
    peerChannel.userInfo = address;
    WCLog(@"Connected to %@", address);
    
    [self sendDeviceIdentification];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.delegate && [self.delegate respondsToSelector:@selector(usbClientDidStartConnection:)])
        {
            [self.delegate usbClientDidStartConnection:self];
        }
    });
}

- (BOOL)isListeningOnSocket;
{
    if (self->serverChannel)
    {
        return self->serverChannel.isListening;
    }
    return NO;
}

+ (NSString *)getSysInfoByName:(char *)typeSpecifier;
{
    size_t size;
    sysctlbyname(typeSpecifier, NULL, &size, NULL, 0);
    
    char *answer = malloc(size);
    sysctlbyname(typeSpecifier, answer, &size, NULL, 0);
    
    NSString *results = [NSString stringWithCString:answer encoding: NSUTF8StringEncoding];
    
    free(answer);
    
    return results ? results : @"";
}

+ (NSString *)hardwareModel;
{
    return [self getSysInfoByName:"hw.machine"]; // ex: iPhone14,2
}

@end
