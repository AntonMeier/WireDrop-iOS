//
//  ConnectionVersion.m
//  WireDrop
//
//  Created by Anton Meier on 2024-12-23.
//

#import "ConnectionVersion.h"

@implementation ConnectionVersion

- (instancetype)initWithLocalVersion:(uint32_t)localVersion
                     localMinVersion:(uint32_t)localMinVersion
                       remoteVersion:(uint32_t)remoteVersion
                    remoteMinVersion:(uint32_t)remoteMinVersion;
{
    self = [super init];
    
    if (self)
    {
        _localVersion = localVersion;
        _localMinVersion = localMinVersion;
        _remoteVersion = remoteVersion;
        _remoteMinVersion = remoteMinVersion;
    }
    
    return self;
}

@end
