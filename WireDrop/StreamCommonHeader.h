//
//  StreamCommonHeader.h
//  WireDrop
//
//  Created by Anton Meier on 2020-09-04.
//

#import <Foundation/Foundation.h>

#ifndef StreamCommonHeader_h
#define StreamCommonHeader_h

NS_ASSUME_NONNULL_BEGIN

@protocol USBConnection <NSObject>

- (void)sendData:(NSData *)data completion:(void (^)(NSError * _Nullable error))completion;
- (void)sendDataArray:(NSArray<NSData *> *)dataArr completion:(void (^)(NSError * _Nullable error))completion;

@end

@protocol StreamClient <NSObject>

- (void)startSocket:(void (^)(NSError *error))completion;
- (void)stopSocket;

@end

@protocol StreamServer <NSObject>

- (void)startSocket;
- (void)stopSocket;

@end

NS_ASSUME_NONNULL_END

#endif
