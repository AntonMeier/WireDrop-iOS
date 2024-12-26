//
//  USBServer.h
//  WireDrop
//
//  Created by Anton Meier on 2020-09-04.
//

#import <Foundation/Foundation.h>
#import "StreamCommonHeader.h"
#import "USBProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@protocol USBServerDelegate;

@interface USBServer : NSObject <StreamServer, USBConnection>

- (instancetype)initWithConfiguration:(USBServerConfiguration *)configuration delegate:(id<USBServerDelegate> _Nullable)delegate;

@property (nonatomic, strong) USBServerConfiguration *configuration;
@property (nonatomic, readwrite, nullable, strong) USBClientConfiguration *currectClientConfiguration;

+ (NSString *)hardwareModel;

@end

@protocol USBServerDelegate <NSObject>

- (void)usbServer:(USBServer *)server gotDataPacket:(NSData *)frame;
- (void)usbServerDidStartConnection:(USBServer *)server; // Cable is plugged in
- (void)usbServer:(USBServer *)server didStartConnectionToClientWithConfiguration:(USBClientConfiguration *)configuration; // Client is identified
- (void)usbServer:(USBServer *)server didEndConnectionWithError:(NSError *)error;
- (void)usbServer:(USBServer *)server didEndConnectionToClientWithConfiguration:(USBClientConfiguration *)configuration error:(NSError *)error;

@end

NS_ASSUME_NONNULL_END
