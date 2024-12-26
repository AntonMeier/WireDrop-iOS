//
//  USBClient.h
//  WireDrop
//
//  Created by Anton Meier on 2020-09-04.
//

#import <Foundation/Foundation.h>
#import "StreamCommonHeader.h"
#import "USBProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@protocol USBClientDelegate;

@interface USBClient : NSObject <StreamClient, USBConnection>

- (instancetype)initWithConfiguration:(USBClientConfiguration *)configuration delegate:(id<USBClientDelegate>)delegate;

@property (nonatomic, strong) USBClientConfiguration *configuration;
@property (nonatomic, strong, nullable) USBServerConfiguration *connectedServer;

+ (NSString *)hardwareModel;
- (BOOL)isListeningOnSocket;
- (void)stopSocket;
- (void)startSocket:(void (^)(NSError * _Nullable error))completion;

@end

@protocol USBClientDelegate <NSObject>

- (void)usbClient:(USBClient *)client gotDataPacket:(NSData *)packet;
- (void)usbClient:(USBClient *)client didFailToSendData:(NSData *)packet;
- (void)usbClient:(USBClient *)client didEndConnectionWithError:(NSError *)error;
- (void)usbClient:(USBClient *)client didEndConnectionToServerWithConfiguration:(USBServerConfiguration *)configuration error:(NSError *)error;
- (void)usbClientDidStartConnection:(USBClient *)client; // Cable is plugged in
- (void)usbClient:(USBClient *)client didStartConnectionToServerWithConfiguration:(USBServerConfiguration *)configuration; // Server is identified

@end
NS_ASSUME_NONNULL_END
