//
//  WCLog.h
//  WireDrop
//
//  Created by Anton Meier on 2020-09-04.
//

#import <Foundation/Foundation.h>

#define WCLoggingActive 0

#if WCLoggingActive == 1
    #define WCLog(args...) do { NSLog(args); } while(0)
#else
    #define WCLog(args...) do {} while(0)
    #define WCLogFunc(args...) do {} while(0)
#endif
