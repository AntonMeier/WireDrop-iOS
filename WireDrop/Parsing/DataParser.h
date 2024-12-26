//
//  DataParser.h
//  WireDrop
//
//  Created by Anton Meier on 2024-03-30.
//

#import <Foundation/Foundation.h>
#import "StreamCommonHeader.h"
#import "ConnectionVersion.h"

#ifndef WDDataParser_h
#define WDDataParser_h

typedef NS_ENUM(NSInteger, CLIENT_TYPE)
{
    CLIENT_TYPE_MAC_APP,
    CLIENT_TYPE_IOS_APP,
    CLIENT_TYPE_IOS_EXTENSION,
};

NS_ASSUME_NONNULL_BEGIN

@protocol WDDataParserDelegate;

@interface DataParser : NSObject

- (instancetype)initWithDelegate:(id<WDDataParserDelegate> _Nullable)delegate
                      clientType:(CLIENT_TYPE)clientType
                      connection:(NSObject<USBConnection> *)connection;

@property BOOL isUSBConnected;
@property NSObject<USBConnection> * _Nullable connection;
@property ConnectionVersion * _Nullable versionState;

- (void)didReceiveData:(NSData *)data;
- (void)startBulkTransferWithTotal:(int)total onAccepted:(void (^)(int))onAccepted;
- (void)endBulkTransferWithCompletion:(void (^)(int))completion;
- (void)sendFile:(NSData *)data fileNo:(int)fileNo total:(int)total filename:(NSString *)filename completion:(void (^)(NSError *error))completion;
- (void)cleanupTransferData;
- (int)currentFileNo;
- (int)totalFilesToTransfer;

@end

@protocol WDDataParserDelegate <NSObject>

- (void)parser:(DataParser *)parser receivedFile:(NSData *)file filename:(nullable NSString *)filename;
- (void)parser:(DataParser *)parser didReceiveFragment:(int)fragment total:(int)total;
- (void)parser:(DataParser *)parser didSendFragment:(int)fragment total:(int)total;
- (void)parser:(DataParser *)parser fileTransferWasAccepted:(int)fileId fileNo:(int)fileNo total:(int)total;
- (void)parser:(DataParser *)parser fileTransferWasCompleted:(int)fileId;
- (void)parser:(DataParser *)parser bulkTransferWasAccepted:(BOOL)accepted bulkId:(int)bulkId total:(int)total;
- (void)parser:(DataParser *)parser bulkTransferEndedWithSuccess:(BOOL)success bulkId:(int)bulkId;

@end

NS_ASSUME_NONNULL_END

#endif
