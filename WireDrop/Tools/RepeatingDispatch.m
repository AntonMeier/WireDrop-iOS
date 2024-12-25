//
//  RepeatingDispatch.m
//  WireDrop
//
//  Created by Anton Meier on 2021-01-23.
//

#import "RepeatingDispatch.h"
#import "WCLog.h"

@interface RepeatingDispatch ()

@property (nullable) dispatch_block_t repeatingDispatchBlock;
@property (nullable) dispatch_source_t repeatingTimerSource;
@property (nonatomic, copy) void (^handler)(void);

@end

@implementation RepeatingDispatch

- (instancetype)initWithDuration:(NSTimeInterval)durationMs leeway:(NSTimeInterval)leewayMs triggerHandler:(void (^)(void))handler;
{
    self = [super init];
    
    if (self)
    {
        _handler = handler;
        _durationMs = durationMs;
        _leewayMs = leewayMs;
    }
    
    return self;
}

- (BOOL)stopped;
{
    return self.repeatingTimerSource == nil;
}

- (void)start;
{
    if (!self.stopped)
    {
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    
    self.repeatingDispatchBlock = dispatch_block_create(DISPATCH_BLOCK_INHERIT_QOS_CLASS, ^
    {
        if (weakSelf.handler)
        {
            dispatch_async(dispatch_get_main_queue(), ^
            {
                if (weakSelf.handler != NULL)
                {
                    weakSelf.handler();
                }
            });
        }
    });

    dispatch_queue_t timerQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    dispatch_source_t tmpTimerSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, DISPATCH_TIMER_STRICT, timerQueue);
        
    if (tmpTimerSource)
    {
        dispatch_time_t start = dispatch_time(DISPATCH_TIME_NOW, self.durationMs * NSEC_PER_MSEC);
        uint64_t interval = self.durationMs * NSEC_PER_MSEC;
            
        dispatch_source_set_timer(tmpTimerSource, start, interval, self.leewayMs * NSEC_PER_MSEC);
        dispatch_source_set_event_handler(tmpTimerSource, self.repeatingDispatchBlock);

        self.repeatingTimerSource = tmpTimerSource;
        dispatch_resume(self.repeatingTimerSource);
    }
}

- (void)stop;
{
    if (self.repeatingTimerSource != nil)
    {
        dispatch_source_cancel(self.repeatingTimerSource);
        self.repeatingTimerSource = nil;
    }
}

@end
