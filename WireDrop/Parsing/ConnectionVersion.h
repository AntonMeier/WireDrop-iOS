//
//  ConnectionVersion.h
//  WireDrop
//
//  Created by Anton Meier on 2024-12-23.
//

#import <Foundation/Foundation.h>

#ifndef ConnectionVersion_h
#define ConnectionVersion_h

NS_ASSUME_NONNULL_BEGIN

@interface ConnectionVersion : NSObject

- (instancetype)initWithLocalVersion:(uint32_t)localVersion
                     localMinVersion:(uint32_t)localMinVersion
                       remoteVersion:(uint32_t)remoteVersion
                    remoteMinVersion:(uint32_t)remoteMinVersion;

@property (nonatomic) uint32_t localVersion;
@property (nonatomic) uint32_t localMinVersion;
@property (nonatomic) uint32_t remoteVersion;
@property (nonatomic) uint32_t remoteMinVersion;

@end

NS_ASSUME_NONNULL_END

#endif
