//
//  RepeatingDispatch.h
//  WireDrop
//
//  Created by Anton Meier on 2021-01-23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RepeatingDispatch : NSObject

@property (readonly) BOOL stopped;
@property (readonly) NSTimeInterval durationMs;
@property (readonly) NSTimeInterval leewayMs;

- (instancetype)initWithDuration:(NSTimeInterval)durationMs leeway:(NSTimeInterval)leewayMs triggerHandler:(void (^)(void))handler;
- (void)start;
- (void)stop;

@end

NS_ASSUME_NONNULL_END
