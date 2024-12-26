//
//  FileTransferState.h
//  WireDrop
//
//  Created by Anton Meier on 2024-12-23.
//

#import <Foundation/Foundation.h>

#ifndef FileTransferState_h
#define FileTransferState_h

typedef NS_ENUM(NSInteger, TransferDirection)
{
    TransferDirectionReceive,
    TransferDirectionTransceive
};

@interface FileTransferState : NSObject

@property TransferDirection direction;
@property BOOL isTransferring;
@property BOOL isBulkTransferring;
@property BOOL isBulk;
@property uint16_t bulkId;
@property uint16_t totalFiles;
@property uint16_t filesReceived;
@property uint16_t fileId;
@property uint16_t fileNo;
@property uint16_t totalFragments;
@property uint16_t currentFragment;
@property uint32_t fragmentSize;
@property uint32_t totalSize;
@property NSString *filename;
@property NSData *transceiveData;
@property NSMutableArray<NSData *> *receiveSegments;

@end

#endif
