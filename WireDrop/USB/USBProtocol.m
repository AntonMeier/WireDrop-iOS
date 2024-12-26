//
//  USBProtocol.m
//  WireDrop
//
//  Created by Anton Meier on 2020-09-20.
//

#import "USBProtocol.h"

@implementation USBServerConfiguration

- (instancetype)initWithIdentifier:(NSString *)identifier
                              name:(NSString *)name
                     hardwareModel:(NSString *)hardwareModel
                           version:(uint32_t)version
                        minVersion:(uint32_t)minVersion
                        clientType:(uint32_t)clientType;
{
    self = [super init];
    
    if (self)
    {
        _identifier = identifier;
        _name = name;
        _hardwareModel = hardwareModel;
        _protocolVersion = version;
        _minSupportedProtocolVersion = minVersion;
        _clientType = clientType;
    }
    
    return self;
}

@end

@implementation USBClientConfiguration

- (instancetype)initWithIdentifier:(NSString *)identifier
                              name:(NSString *)name
                   hardwareMachine:(NSString *)hardwareMachine
                           version:(uint32_t)version
                        minVersion:(uint32_t)minVersion
                        clientType:(uint32_t)clientType;
{
    self = [super init];
    
    if (self)
    {
        _identifier = identifier;
        _name = name;
        _hardwareMachine = hardwareMachine;
        _protocolVersion = version;
        _minSupportedProtocolVersion = minVersion;
        _clientType = clientType;
    }
    
    return self;
}

@end
