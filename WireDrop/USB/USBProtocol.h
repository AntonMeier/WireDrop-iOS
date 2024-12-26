//
//  USBProtocol.h
//  WireDrop
//
//  Created by Anton Meier on 2020-09-04.
//  Based on PTExampleProtocol in rsms/peertalk
//

#ifndef USBProtocol_h
#define USBProtocol_h

#import <Foundation/Foundation.h>
#include <stdint.h>

static const int WCPTProtocolIPv4PortNumber = 2431;

enum
{
    WCPTFrameTypeDeviceIdentification = 100,
    WCPTFrameTypeRawData = 104,
};

typedef struct _WCPTTextFrame
{
    uint32_t length;
    uint8_t utf8text[0];
} WCPTTextFrame;

typedef struct _WCPTDataFrame
{
    uint32_t length;
    uint8_t data[0];
} WCPTDataFrame;

@interface USBClientConfiguration : NSObject

- (instancetype)initWithIdentifier:(NSString *)identifier
                              name:(NSString *)name
                   hardwareMachine:(NSString *)hardwareMachine
                           version:(uint32_t)version
                        minVersion:(uint32_t)minVersion
                        clientType:(uint32_t)clientType;

@property (nonatomic, strong) NSString *identifier;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *hardwareMachine;
@property (nonatomic) uint32_t protocolVersion;
@property (nonatomic) uint32_t minSupportedProtocolVersion;
@property (nonatomic) uint32_t clientType;

@end

@interface USBServerConfiguration : NSObject

- (instancetype)initWithIdentifier:(NSString *)identifier
                              name:(NSString *)name
                     hardwareModel:(NSString *)hardwareModel
                           version:(uint32_t)version
                        minVersion:(uint32_t)minVersion
                        clientType:(uint32_t)clientType;

@property (nonatomic, strong) NSString *identifier;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *hardwareModel;
@property (nonatomic) uint32_t protocolVersion;
@property (nonatomic) uint32_t minSupportedProtocolVersion;
@property (nonatomic) uint32_t clientType;

@end

#endif /* USBProtocol_h */
