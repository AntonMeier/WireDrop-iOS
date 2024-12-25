//
//  USBServer.m
//  WireDrop
//
//  Created by Anton Meier on 2020-09-04.
//

#import "USBServer.h"
#import "USBProtocol.h"
#import "PTChannel.h"
#import "WCLog.h"
#import "USBDispatchData.h"
#import "RepeatingDispatch.h"
#include <sys/sysctl.h>

static const NSTimeInterval PTAppReconnectDelay = 2.0;

@interface USBServer () <PTChannelDelegate> {
    dispatch_queue_t _sendQueue;
}

@property NSMutableArray<NSNumber *> *pendingClients;
@property int nextClientIndex;
@property PTChannel *connectedChannel;
@property (weak, nonatomic, nullable) id<USBServerDelegate> delegate;
@property (nonatomic, readwrite, strong) RepeatingDispatch *connectionDispatch;

@end

@implementation USBServer

- (instancetype)initWithConfiguration:(USBServerConfiguration *)configuration delegate:(id<USBServerDelegate> _Nullable)delegate;
{
    self = [super init];
    
    if (self)
    {
        _delegate = delegate;
        _configuration = configuration;
        _pendingClients = [NSMutableArray array];
        _nextClientIndex = 0;
        _sendQueue =  dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
        
        _connectionDispatch = [[RepeatingDispatch alloc] initWithDuration:PTAppReconnectDelay*1000 leeway:300 triggerHandler:^{
            WCLog(@"\n\n\n- Connect Dispatch trigger - ");
            [self enqueueConnectToUSBDevice];
        }];
    }
    
    return self;
}

- (void)startSocket;
{
    [self setupUsbDeviceAttachmentListeners];
    WCLog(@"Ready for connection...");
}

- (void)stopSocket;
{
    // TODO: Might be needed when app closes
}

- (void)sendData:(NSData *)data completion:(void (^)(NSError * _Nullable error))completion;
{
    if (self.connectedChannel)
    {
        dispatch_async(_sendQueue, ^{
            dispatch_data_t payload = WCPTTextDispatchDataWithData(data);
            [self.connectedChannel sendFrameOfType:WCPTFrameTypeRawData tag:PTFrameNoTag withPayload:payload callback:^(NSError *error) {
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
            WCLog(@"[usb send]: %@", data);
        });
    }
    else
    {
        WCLog(@"Can not send raw data — not connected");
        // If needed, dispatch data failure here
    }
}

- (void)sendDataArray:(NSArray<NSData *> *)dataArr completion:(void (^)(NSError * _Nullable error))completion;
{
    if (self.connectedChannel)
    {
        dispatch_async(_sendQueue, ^{
            dispatch_data_t payload = WCPTTextDispatchDataWithDataArray(dataArr);
            [self.connectedChannel sendFrameOfType:WCPTFrameTypeRawData tag:PTFrameNoTag withPayload:payload callback:^(NSError *error) {
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
            WCLog(@"[usb send]: array");
        });
    }
    else
    {
        WCLog(@"Can not send raw data — not connected");
        // If needed, dispatch data failure here
    }
}

- (void)handleChannelDisconnected:(PTChannel *)channel;
{
    [self handleChannelConnected:nil];
}

- (void)handleChannelConnected:(PTChannel *)channel;
{
    self.connectedChannel = channel;
    
    if (self.connectedChannel)
    {
        if (!self.connectionDispatch.stopped)
        {
            [self.connectionDispatch stop];
        }
    }
    else
    {
        if (self.pendingClients.count > 0)
        {
            [self enqueueConnectToUSBDevice];
            
            if (self.connectionDispatch.stopped)
            {
                [self.connectionDispatch start];
            }
        }
    }
}

- (void)sendDeviceIdentification;
{
    if (self.connectedChannel)
    {
        WCLog(@"Sending device identification %@", self.connectedChannel);
        
        NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:
                              self.configuration.identifier, @"identifier",
                              self.configuration.name ? self.configuration.name : @"Unknown Device", @"name",
                              self.configuration.hardwareModel ? self.configuration.hardwareModel : @"", @"model",
                              @(self.configuration.protocolVersion), @"pv",
                              @(self.configuration.minSupportedProtocolVersion), @"mspv",
                              @(self.configuration.clientType), @"ct",
                              nil];
        
        dispatch_data_t payload = [info createReferencingDispatchData];
        
        [self.connectedChannel sendFrameOfType:WCPTFrameTypeDeviceIdentification tag:PTFrameNoTag withPayload:payload callback:^(NSError *error) {
            if (error)
            {
                WCLog(@"Failed to send WCPTFrameTypeDeviceIdentification: %@", error);
                // If needed, dispatch identification failure here
            }
        }];
    }
}

#pragma mark - PTChannelDelegate

- (BOOL)ioFrameChannel:(PTChannel*)channel shouldAcceptFrameOfType:(uint32_t)type tag:(uint32_t)tag payloadSize:(uint32_t)payloadSize;
{
    if (type == WCPTFrameTypeDeviceIdentification ||
        type == WCPTFrameTypeRawData ||
        type == PTFrameTypeEndOfStream)
    {
        return YES;
    }
    else
    {
        WCLog(@"Unexpected frame of type %u", type);
        [channel close];
        return NO;
    }
}

- (void)ioFrameChannel:(PTChannel*)channel didReceiveFrameOfType:(uint32_t)type tag:(uint32_t)tag payload:(PTData*)payload;
{
    if (type == WCPTFrameTypeDeviceIdentification)
    {
        NSDictionary *deviceInfo = [NSDictionary dictionaryWithContentsOfDispatchData:payload.dispatchData];
        
        USBClientConfiguration *config = [[USBClientConfiguration alloc] init];
        
        config.identifier = deviceInfo[@"identifier"];
        config.name = deviceInfo[@"name"];
        config.hardwareMachine = deviceInfo[@"model"];
        config.protocolVersion = deviceInfo[@"pv"] ? [deviceInfo[@"pv"] unsignedIntValue] : 0;
        config.minSupportedProtocolVersion = deviceInfo[@"mspv"] ? [deviceInfo[@"mspv"] unsignedIntValue] : 0;
        config.clientType = deviceInfo[@"ct"] ? [deviceInfo[@"ct"] unsignedIntValue] : 0;
        
        WCLog(
              @"Identified client: %@ : %@, model: %@, pv: %u, mspv: %u",
              config.identifier, config.name, config.hardwareMachine, config.protocolVersion, config.minSupportedProtocolVersion
              );
        
        [self sendDeviceIdentification];
        
        // TODO: Consider handling of support for multiple connected iOS devices at the same time
        
        self.currectClientConfiguration = config;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.delegate && [self.delegate respondsToSelector:@selector(usbServer:didStartConnectionToClientWithConfiguration:)])
            {
                [self.delegate usbServer:self didStartConnectionToClientWithConfiguration:config];
            }
        });
    }
    else if (type == WCPTFrameTypeRawData)
    {
        WCPTDataFrame *textFrame = (WCPTDataFrame*)payload.data;
        textFrame->length = ntohl(textFrame->length);
        
        // TODO: I believe we could use an autorelease pool for this
        NSData *d = [NSData dataWithBytesNoCopy:textFrame->data length:textFrame->length freeWhenDone:NO];
        
        [self.delegate usbServer:self gotDataPacket:d];
    }
}

- (void)ioFrameChannel:(PTChannel*)channel didEndWithError:(NSError*)error;
{
    if (self.connectedChannel == channel)
    {
        WCLog(@"Disconnected from %@", channel.userInfo);
        
        [self handleChannelDisconnected:self.connectedChannel];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.delegate && [self.delegate respondsToSelector:@selector(usbServer:didEndConnectionWithError:)])
            {
                [self.delegate usbServer:self didEndConnectionWithError:error];
            }
        });
        
        // TODO: Consider handling of support for multiple connected iOS devices at the same time
        
        if (self.currectClientConfiguration)
        {
            USBClientConfiguration *config = self.currectClientConfiguration;
            self.currectClientConfiguration = nil;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (self.delegate && [self.delegate respondsToSelector:@selector(usbServer:didEndConnectionToClientWithConfiguration:error:)])
                {
                    [self.delegate usbServer:self didEndConnectionToClientWithConfiguration:config error:error];
                }
            });
        }
    }
}

#pragma mark - Wired device connections

- (void)setupUsbDeviceAttachmentListeners;
{
    __weak typeof(self) weakSelf = self;
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    
    [nc addObserverForName:PTUSBDeviceDidAttachNotification object:PTUSBHub.sharedHub queue:nil usingBlock:^(NSNotification *note) {
        NSNumber *deviceID = [note.userInfo objectForKey:@"DeviceID"];
        WCLog(@"PTUSBDeviceDidAttachNotification: %@", deviceID);
        [weakSelf clientAttached:deviceID];
    }];
    
    [nc addObserverForName:PTUSBDeviceDidDetachNotification object:PTUSBHub.sharedHub queue:nil usingBlock:^(NSNotification *note) {
        NSNumber *deviceID = [note.userInfo objectForKey:@"DeviceID"];
        WCLog(@"PTUSBDeviceDidDetachNotification: %@", deviceID);
        [weakSelf clientDetatched:deviceID];
    }];
}

- (void)clientAttached:(NSNumber *)clientId;
{
    [self removePendingClientId:clientId];
    [self.pendingClients addObject:clientId];
    self.nextClientIndex = ((int)self.pendingClients.count)-1; // To make sure next connect is to new client.
    [self.connectionDispatch stop];
    
    if (!self.connectedChannel)
    {
        [self.connectionDispatch start];
        WCLog(@"Enqueuing derectly after attach");
        [self enqueueConnectToUSBDevice];
    }
}

- (void)clientDetatched:(NSNumber *)clientId;
{
    [self removePendingClientId:clientId];
    
    if (self.connectedChannel && self.connectedChannel.userInfo && [self.connectedChannel.userInfo isEqualToNumber:clientId])
    {
        WCLog(@"Detatched client id matches connected id");
        if (self.connectedChannel)
        {
            [self.connectedChannel close];
        }
    }
    else
    {
        WCLog(@"Detatched client id does NOT match connected id!");
    }
    
    if (self.pendingClients.count == 0)
    {
        [self.connectionDispatch stop];
    }
}

- (void)removePendingClientId:(NSNumber *)clientId;
{
    for (int i = 0; i < self.pendingClients.count; i++)
    {
        if ([self.pendingClients[i] isEqualToNumber:clientId])
        {
            [self.pendingClients removeObjectAtIndex:i];
            break;
        }
    }
}

- (void)disconnectFromCurrentChannel;
{
    if (self.connectedChannel)
    {
        [self.connectedChannel close];
        [self handleChannelDisconnected:self.connectedChannel];
    }
}

- (void)enqueueConnectToUSBDevice;
{
    __weak typeof(self) weakSelf = self;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        WCLog(@"Attempting connect to new device...");
        
        if (!weakSelf.connectedChannel)
        {
            if (weakSelf.pendingClients.count > 0)
            {
                int next = weakSelf.nextClientIndex++;
                
                if (!(next < weakSelf.pendingClients.count && next >= 0))
                {
                    weakSelf.nextClientIndex = 1;
                    next = 0;
                }
                
                WCLog(@"Connecting to index: %d", next);
                [weakSelf connectToUSBDeviceWithDeviceId:weakSelf.pendingClients[next]];
            }
        }
    });
}

- (void)connectToUSBDeviceWithDeviceId:(NSNumber *)deviceId;
{
    __weak typeof(self) weakSelf = self;
    
    PTChannel *channel = [PTChannel channelWithDelegate:self];
    channel.userInfo = deviceId;
    channel.delegate = self;
    
    [channel connectToPort:WCPTProtocolIPv4PortNumber overUSBHub:PTUSBHub.sharedHub deviceID:deviceId callback:^(NSError *error) {
        if (error)
        {
            if (error.domain == PTUSBHubErrorDomain && error.code == PTUSBHubErrorConnectionRefused)
            {
                WCLog(@"Connection Refused to device #%@: %@", channel.userInfo, error);
            }
            else
            {
                WCLog(@"Failed to connect to device #%@: %@", channel.userInfo, error);
                // Failed to connect to device #253: Error Domain=PTUSBHubError Code=2 "unknown device"
            }
        }
        else
        {
            [weakSelf handleChannelConnected:channel];
            
            WCLog(@"Connected to device: %d", ((NSNumber *)weakSelf.connectedChannel.userInfo).intValue);
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(usbServerDidStartConnection:)])
                {
                    [weakSelf.delegate usbServerDidStartConnection:weakSelf];
                }
            });
        }
    }];
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
    return [self getSysInfoByName:"hw.model"];
}

@end
