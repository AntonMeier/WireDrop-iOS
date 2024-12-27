//
//  WDDataParser.m
//  WireDrop
//
//  Created by Anton Meier on 2024-03-30.
//

#import "DataParser.h"
#import "WCLog.h"
#import "ProtocolStructs.h"
#import "FileTransferState.h"

#include <stdlib.h>

@interface DataParser (WDMessageHandler)

- (void)handleFileStartRequest:(FileStartRequest *)packet;
- (void)handleFileStartResponse:(FileStartAck *)packet;
- (void)handleFileEndRequest:(FileEndNotification *)packet;
- (void)handleFileEndResponse:(FileEndAck *)packet;
- (void)handleFileSegment:(FileSegmentInd *)packet frame:(NSData *)frame;
- (void)handleBulkStartRequest:(BulkStartRequest *)packet;
- (void)handleBulkStartResponse:(BulkStartResponse *)packet;
- (void)handleBulkEndRequest:(BulkEndRequest *)packet;
- (void)handleBulkEndResponse:(BulkEndResponse *)packet;

@end

@interface DataParser ()

@property (weak, nonatomic, nullable) id<WDDataParserDelegate> delegate;
@property FileTransferState *transferState;
@property CLIENT_TYPE clientType;
@property (nonatomic, copy, nullable) void (^fileCompletion)(NSError *);
@property (nonatomic, copy, nullable) void (^onBulkAccepted)(int);
@property (nonatomic, copy, nullable) void (^onBulkCompletion)(int);

@end

@implementation DataParser

- (instancetype)initWithDelegate:(id<WDDataParserDelegate> _Nullable)delegate
                      clientType:(CLIENT_TYPE)clientType
                      connection:(NSObject<USBConnection> *)connection;
{
    self = [super init];
    
    if (self)
    {
        _delegate = delegate;
        _clientType = clientType;
        _connection = connection;
        _transferState = [[FileTransferState alloc] init];
    }
    
    return self;
}

- (int)currentFileNo;
{
    return self.transferState.fileNo;
}

- (int)totalFilesToTransfer;
{
    return self.transferState.totalFiles;
}

- (void)startBulkTransferWithTotal:(int)total onAccepted:(void (^)(int))onAccepted;
{
    self.onBulkAccepted = onAccepted;
    self.transferState = [[FileTransferState alloc] init];
    self.transferState.bulkId = arc4random_uniform(65535);
    self.transferState.totalFiles = total;
    
    BulkStartRequest request = {0};
    
    request.header.opcode = OPCODE_FROM_CLIENT_BULK_START;
    request.header.bulkId = self.transferState.bulkId;
    request.clientType = TransferDirectionTransceive;
    request.fileCount = self.transferState.totalFiles;
    
    WCLog(@"Sending BulkStartRequest count: %u, bulkId: %u", request.fileCount, request.header.bulkId);

    [self sendData:[NSData dataWithBytes:&request length:sizeof(request)]];
}

- (void)endBulkTransferWithCompletion:(void (^)(int))completion;
{
    self.onBulkCompletion = completion;
    
    BulkEndRequest request = {0};
    
    request.header.opcode = OPCODE_FROM_CLIENT_BULK_END;
    request.header.bulkId = self.transferState.bulkId;
    request.aborted = 0;
    request.reason = 0;
    
    WCLog(@"Sending BulkEndRequest bulkId: %u", request.header.bulkId);

    [self sendData:[NSData dataWithBytes:&request length:sizeof(request)]];
}

- (void)cleanupTransferData;
{
    self.transferState.transceiveData = [[NSData alloc] init];
    self.transferState.receiveSegments = [[NSMutableArray alloc] init];
}

- (void)sendFile:(NSData *)data fileNo:(int)fileNo total:(int)total filename:(NSString *)filename completion:(void (^)(NSError *error))completion;
{
    self.fileCompletion = completion;
    self.transferState.fileId++;
    self.transferState.transceiveData = data;
    self.transferState.direction = TransferDirectionTransceive;
    self.transferState.filename = filename;
    self.transferState.fileId = total;
    self.transferState.fragmentSize = 1000000;
    self.transferState.totalSize = (unsigned int)data.length;
    self.transferState.totalFragments = self.transferState.totalSize / self.transferState.fragmentSize + (self.transferState.totalSize % self.transferState.fragmentSize != 0);
    self.transferState.currentFragment = 0;
    self.transferState.fileNo = fileNo;
    
    if (self.transferState.totalFragments == 1)
    {
        self.transferState.totalFragments = 2;
        self.transferState.fragmentSize = (self.transferState.totalSize / 2) + 1;
    }

    NSData *stringBytes = [filename dataUsingEncoding:NSUTF8StringEncoding];
    uint32_t filename_len = (uint32_t)stringBytes.length;
    unsigned char requestArray[sizeof(FileStartRequest)+filename_len];
    
    FileStartRequest *request = (FileStartRequest *)requestArray;
    
    request->header.opcode = OPCODE_FROM_CLIENT_FILE_START;
    request->header.fileId = self.transferState.fileId;
    request->clientType = self.clientType;
    request->fragments = self.transferState.totalFragments;
    request->fileNo = self.transferState.fileNo;
    request->totalDataSize = self.transferState.totalSize;
    request->filenameLength = filename_len;
    [stringBytes getBytes:request->filename length:filename_len];
    
    WCLog(@"Sending FileStartRequest fileNo: %u, totalDataSize: %u", request->fileNo, request->totalDataSize);
    
    [self sendData:[NSData dataWithBytes:request length:sizeof(requestArray)]];
}

- (void)sendSegment:(int)segment position:(unsigned int)position size:(unsigned int)size completion:(void (^)(NSError *error))completion;
{
    if (segment >= self.transferState.totalFragments)
    {
        WCLog("Error: Segment out of bounds");
        return;
    }
    
    FileSegmentInd ind = {0};
    
    ind.header.opcode = OPCODE_FROM_CLIENT_FILE_SEGMENT;
    ind.header.fileId = self.transferState.fileId;
    ind.fragmentNo = segment;
    
    unsigned int safeSize = ((segment+1) * size) > self.transferState.totalSize ? self.transferState.totalSize - (segment * size) : size;
    
    if (safeSize > self.transferState.fragmentSize)
    {
        WCLog("Error: Invalid fragment size");
        return;
    }
    
    ind.fragmentSize = safeSize;
    
    if (!self.isUSBConnected)
    {
        WCLog("Error: Cannot send fragment while USB is not connected");
        return;
    }
    
    NSArray *sendArray = @[
        [NSData dataWithBytes:&ind length:sizeof(ind)],
        [self.transferState.transceiveData subdataWithRange:NSMakeRange(position, safeSize)]
    ];
    
    [self.connection sendDataArray:sendArray completion:^(NSError * _Nullable error) {
        [self.delegate parser:self didSendFragment:segment + 1 total:self.transferState.totalFragments];
        completion(error);
    }];
}

- (void)sendSegments;
{
    if (self.transferState.totalFragments == self.transferState.currentFragment)
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.transferState.isBulk ? 0.0 : 0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self sendFileComplete];
        });
    }
    else
    {
        unsigned int position = self.transferState.currentFragment * self.transferState.fragmentSize;

        [self sendSegment:self.transferState.currentFragment position:position size:self.transferState.fragmentSize completion:^(NSError *error) {
            self.transferState.currentFragment += 1;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self sendSegments];
            });
        }];
    }
}

- (void)sendFileComplete;
{
    FileEndNotification endNot = {0};
    
    endNot.header.opcode = OPCODE_FROM_CLIENT_FILE_END;
    endNot.header.fileId = self.transferState.fileId;
    
    WCLog(@"Sending FileEndNotification fileId: %u", endNot.header.fileId);
    
    [self sendData:[NSData dataWithBytes:&endNot length:sizeof(endNot)]];
}

- (void)didReceiveData:(NSData *)frame;
{
    uint16_t *opcode = (uint16_t *)frame.bytes;
    
    if ([self opcodeIsFileTransferOpcode:*opcode])
    {
        [self handleFileTransferPacket:frame];
    }
    else
    {
        [self handleBulkTransferPacket:frame];
    }
}

- (BOOL)opcodeIsFileTransferOpcode:(uint16_t)opcode;
{
    return (opcode < OPCODE_FROM_CLIENT_BULK_START);
}

- (void)handleFileTransferPacket:(NSData *)frame;
{
    FileTransferHeader *header = (FileTransferHeader *)frame.bytes;
    
    if (self.transferState.isTransferring)
    {
        if (header->fileId != self.transferState.fileId)
        {
            WCLog(@"Error: Invalid fileId: %d, expected: %d", header->fileId, self.transferState.fileId);
            return;
        }
        
        switch (header->opcode) {
            case OPCODE_FROM_CLIENT_FILE_SEGMENT:
            {
                WCLog(@"OPCODE_FROM_CLIENT_FILE_SEGMENT");
                [self handleFileSegment:(FileSegmentInd *)frame.bytes frame:frame];
            }
                break;
            case OPCODE_FROM_CLIENT_FILE_END:
            {
                WCLog(@"OPCODE_FROM_CLIENT_FILE_END");
                [self handleFileEndRequest:(FileEndNotification *)frame.bytes];
            }
                break;
            case OPCODE_FROM_SERVER_FILE_END_RESPONSE:
            {
                WCLog(@"OPCODE_FROM_SERVER_FILE_END_RESPONSE");
                [self handleFileEndResponse:(FileEndAck *)frame.bytes];
            }
                break;
            default:
                WCLog(@"Error: Received invalid opcode while transferring in progress (%d)", header->opcode);
                break;
        }
    }
    else
    {
        switch (header->opcode) {
            case OPCODE_FROM_CLIENT_FILE_START:
            {
                WCLog(@"OPCODE_FROM_CLIENT_FILE_START");
                [self handleFileStartRequest:(FileStartRequest *)frame.bytes];
            }
                break;
            case OPCODE_FROM_SERVER_FILE_START_RESPONSE:
            {
                WCLog(@"OPCODE_FROM_SERVER_FILE_START_RESPONSE");
                [self handleFileStartResponse:(FileStartAck *)frame.bytes];
            }
                break;
            default:
                WCLog(@"Error: Received transfer opcode while transferring is not in progress (%d)", header->opcode);
                break;
        }
    }
}

- (void)handleBulkTransferPacket:(NSData *)frame;
{
    BulkTransferHeader *header = (BulkTransferHeader *)frame.bytes;
    
    if (self.transferState.isBulkTransferring)
    {
        if (header->bulkId != self.transferState.bulkId)
        {
            WCLog(@"Error: Invalid bulkId: %d, expected: %d", header->bulkId, self.transferState.bulkId);
            return;
        }
        
        switch (header->opcode) {
            case OPCODE_FROM_CLIENT_BULK_END:
            {
                WCLog(@"OPCODE_FROM_CLIENT_BULK_END");
                [self handleBulkEndRequest:(BulkEndRequest *)frame.bytes];
            }
                break;
            case OPCODE_FROM_SERVER_BULK_END_RESPONSE:
            {
                WCLog(@"OPCODE_FROM_SERVER_BULK_END_RESPONSE");
                [self handleBulkEndResponse:(BulkEndResponse *)frame.bytes];
            }
                break;
            default:
                WCLog(@"Error: Received invalid opcode while bulk transferring in progress (%d)", header->opcode);
                break;
        }
    }
    else
    {
        switch (header->opcode) {
            case OPCODE_FROM_CLIENT_BULK_START:
            {
                WCLog(@"OPCODE_FROM_CLIENT_BULK_START");
                [self handleBulkStartRequest:(BulkStartRequest *)frame.bytes];
            }
                break;
            case OPCODE_FROM_SERVER_BULK_START_RESPONSE:
            {
                WCLog(@"OPCODE_FROM_SERVER_BULK_START_RESPONSE");
                [self handleBulkStartResponse:(BulkStartResponse *)frame.bytes];
            }
                break;
            default:
                WCLog(@"Error: Received bulk transfer related opcode while transferring is not in progress (%d)", header->opcode);
                break;
        }
    }
}

- (void)sendData:(NSData *)data;
{
    if (!self.isUSBConnected) {
        WCLog(@"Error: Cannot send data while USB is not connected");
        return;
    }
    
    [self.connection sendData:data completion:^(NSError * _Nullable error) {
        WCLog(@"Did send data with count: %lu", data.length);
    }];
}

@end

#pragma mark - DataParser+WDMessageHandler

@implementation DataParser (WDMessageHandler)

- (void)sendFileTransferResponseAccepted:(BOOL)accepted;
{
    FileStartAck startAck = {0};
    
    startAck.header.opcode = OPCODE_FROM_SERVER_FILE_START_RESPONSE;
    startAck.header.fileId = self.transferState.fileId;
    startAck.accepted = accepted;
    startAck.reason = accepted ? 0 : 1;
    
    self.transferState.isTransferring = accepted ? true : false;
    
    WCLog(@"Sending FileStartAck accepted: %d, fileId: %u", startAck.accepted, startAck.header.fileId);

    [self sendData:[NSData dataWithBytes:&startAck length:sizeof(startAck)]];
}

- (void)sendFileTransferCompletedResponse;
{
    FileEndAck endAck = {0};
    
    endAck.header.opcode = OPCODE_FROM_SERVER_FILE_END_RESPONSE;
    endAck.header.fileId = self.transferState.fileId;
    endAck.success = 1;
    
    self.transferState.isTransferring = false;
    
    WCLog(@"Sending FileEndAck fileId: %u", endAck.header.fileId);

    [self sendData:[NSData dataWithBytes:&endAck length:sizeof(endAck)]];
}

- (void)handleFileStartRequest:(FileStartRequest *)packet;
{
    if (self.clientType == CLIENT_TYPE_IOS_EXTENSION)
    {
        WCLog(@"Error: Cannot accept incoming transfer in extension target");
        [self sendFileTransferResponseAccepted:false];
        return;
    }

    if (self.versionState != nil)
    {
        if (self.versionState.localMinVersion < self.versionState.remoteMinVersion)
        {
            WCLog(
                  @"Error: Cannot allow incoming transfer request due to minimum version mismatch: (%u, %u)",
                  self.versionState.localMinVersion, self.versionState.remoteMinVersion
                  );
            [self sendFileTransferResponseAccepted:false];
            return;
        }
    }
    
    self.transferState.direction = TransferDirectionReceive;
    self.transferState.fileId = packet->header.fileId;
    self.transferState.fileNo = packet->fileNo;
    self.transferState.totalFragments = packet->fragments;
    self.transferState.receiveSegments = [[NSMutableArray alloc] init];
    
    uint32_t numChars = packet->filenameLength;
    char filenameArray[numChars];
    memcpy(filenameArray, packet->filename, numChars);
    NSString *filename = [[NSString alloc] initWithBytes:filenameArray length:numChars encoding:NSUTF8StringEncoding];
    
    self.transferState.filename = filename;
    
    WCLog(
          @"Filename: %@, fileNo: %u, totalFiles: %u, fileId: %u, totalDataSize: %ul, fragments: %ul",
          filename, packet->fileNo, self.transferState.totalFiles, packet->header.fileId, packet->totalDataSize, packet->fragments
          );
    
    [self.delegate parser:self fileTransferWasAccepted:packet->header.fileId fileNo:packet->fileNo total:self.transferState.totalFiles];
    
    if (self.transferState.fileNo == 0)
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self sendFileTransferResponseAccepted:true];
        });
    }
    else
    {
        [self sendFileTransferResponseAccepted:true];
    }
}

- (void)handleFileStartResponse:(FileStartAck *)packet;
{
    if (packet->accepted == 0)
    {
        WCLog(@"Error: Transfer was rejected");
        return;
    }
    
    self.transferState.isTransferring = true;
    [self.delegate parser:self fileTransferWasAccepted:packet->header.fileId fileNo:self.transferState.fileNo total:self.transferState.totalFiles];
    [self sendSegments];
}

- (void)handleFileEndRequest:(FileEndNotification *)packet;
{
    if (self.transferState.receiveSegments.count == self.transferState.totalFragments)
    {
        WCLog(@"We have received all segments (%lu) -> assembling file data...", (unsigned long)self.transferState.receiveSegments.count);
        NSMutableData *fileData = [NSMutableData data];
        for (NSData *segment in self.transferState.receiveSegments)
        {
            [fileData appendData:segment];
        }
        
        WCLog(@"File data length: %lu", (unsigned long)fileData.length);
        
        self.transferState.receiveSegments = [[NSMutableArray alloc] init];
        self.transferState.receiveSegments = [[NSMutableArray alloc] init];
        self.transferState.filesReceived++;
        
        [self.delegate parser:self fileTransferWasCompleted:packet->header.fileId];
        [self.delegate parser:self receivedFile:fileData filename: self.transferState.filename];
    }
    
    [self sendFileTransferCompletedResponse];
}

- (void)handleFileEndResponse:(FileEndAck *)packet;
{
    self.transferState.filesReceived++;
    self.transferState.isTransferring = false;
    self.transferState.transceiveData = [[NSData alloc] init];
    
    [self.delegate parser:self fileTransferWasCompleted:packet->header.fileId];

    if (self.fileCompletion != nil) {
        void (^completion)(NSError *) = self.fileCompletion;
        self.fileCompletion = nil;
        completion(nil);
    }
}

- (void)handleFileSegment:(FileSegmentInd *)packet frame:(NSData *)frame;
{
#if IS_APP_TARGET
    NSData *segment = [frame subdataWithRange:NSMakeRange(sizeof(FileSegmentInd), packet->fragmentSize)];
    WCLog(@"Segment %d, size: %ul datasize: %lu", packet->fragmentNo, packet->fragmentSize, segment.length);
    [self.transferState.receiveSegments addObject:segment];
    [self.delegate parser:self didReceiveFragment:(packet->fragmentNo) + 1 total:self.transferState.totalFragments];
#endif
}

- (void)sendBulkTransferResponseAccepted:(BOOL)accepted bulkId:(uint16_t)bulkId;
{
    BulkStartResponse startResponse = {0};
    
    startResponse.header.opcode = OPCODE_FROM_SERVER_BULK_START_RESPONSE;
    startResponse.header.bulkId = self.transferState.bulkId;
    startResponse.accepted = accepted;
    startResponse.reason = accepted ? 0 : 1;
    
    self.transferState.isBulkTransferring = accepted ? true : false;
    
    WCLog(@"Sending BulkStartResponse accepted: %d, bulkId: %u", startResponse.accepted, startResponse.header.bulkId);
    
    [self sendData:[NSData dataWithBytes:&startResponse length:sizeof(startResponse)]];
}

- (void)sendBulkTransferEndSuccess:(uint8_t)success reason:(uint8_t)reason bulkId:(uint16_t)bulkId;
{
    BulkEndResponse endResponse = {0};
    
    endResponse.header.opcode = OPCODE_FROM_SERVER_BULK_END_RESPONSE;
    endResponse.header.bulkId = self.transferState.bulkId;
    endResponse.success = success;
    
    self.transferState.isBulkTransferring = success ? 0 : 1;

    WCLog(@"Sending BulkEndResponse success: %d, bulkId: %u", endResponse.success, endResponse.header.bulkId);

    [self sendData:[NSData dataWithBytes:&endResponse length:sizeof(endResponse)]];
}


- (void)handleBulkStartRequest:(BulkStartRequest *)packet;
{
    if (self.clientType == CLIENT_TYPE_IOS_EXTENSION)
    {
        WCLog(@"Error: Cannot accept incoming transfer in extension target");
        [self sendBulkTransferResponseAccepted:false bulkId: packet->header.bulkId];
        return;
    }
    
    if (self.versionState != nil)
    {
        if (self.versionState.localMinVersion < self.versionState.remoteMinVersion)
        {
            WCLog(
                  @"Error: Cannot allow incoming transfer request due to minimum version mismatch: (%u, %u)",
                  self.versionState.localMinVersion, self.versionState.remoteMinVersion
                  );
            [self sendBulkTransferResponseAccepted:false bulkId: packet->header.bulkId];
            return;
        }
    }
    
    self.transferState.direction = TransferDirectionReceive;
    self.transferState.bulkId = packet->header.bulkId;
    self.transferState.totalFiles = packet->fileCount;
    self.transferState.filesReceived = 0;
    
    WCLog(@"bulkId: %u, totalFiles: %u", packet->header.bulkId, packet->fileCount);
    
    [self.delegate parser:self bulkTransferWasAccepted:true bulkId:packet->header.bulkId total:packet->fileCount];
    [self sendBulkTransferResponseAccepted:true bulkId:packet->header.bulkId];
}

- (void)handleBulkStartResponse:(BulkStartResponse *)packet;
{
    if (packet->accepted == 0)
    {
        WCLog(@"Error: Bulk transfer was rejected");
        self.transferState.isBulkTransferring = false;
    }
    else
    {
        WCLog(@"Bulk transfer was accepted, resetting transfer state");
        self.transferState.filesReceived = 0;
        self.transferState.isBulkTransferring = true;
    }
    
    if (self.onBulkAccepted != nil)
    {
        void (^bulkAccepted)(int) = self.onBulkAccepted;
        self.onBulkAccepted = nil;
        bulkAccepted(packet->accepted == 1 ? 0 : -1);
    }

    [self.delegate parser:self bulkTransferWasAccepted:packet->accepted bulkId:packet->header.bulkId total:self.transferState.totalFiles];
}

- (void)handleBulkEndRequest:(BulkEndRequest *)packet;
{
    BOOL success = true;
    
    if (self.transferState.filesReceived == self.transferState.totalFiles && !(packet->aborted))
    {
        WCLog(@"We have received all files (%u) -> finalizing bulk transfer", self.transferState.filesReceived);
        [self sendBulkTransferEndSuccess:true reason:0 bulkId:self.transferState.bulkId];
    }
    else
    {
        WCLog(@"Error: Bulk transfer aborted or failed (%u) (%u) (%u)", self.transferState.filesReceived, self.transferState.totalFiles, packet->reason);
        success = false;
        [self sendBulkTransferEndSuccess:false reason:0 bulkId:self.transferState.bulkId];
    }
    
    self.transferState.filesReceived = 0;
    [self.delegate parser:self bulkTransferEndedWithSuccess:success bulkId:self.transferState.bulkId];
}

- (void)handleBulkEndResponse:(BulkEndResponse *)packet;
{
    BOOL success = packet->success;
    WCLog(@"Bulk transfer ended with success: %u", success);
    
    if (self.onBulkCompletion != nil)
    {
        void (^bulkCompletion)(int) = self.onBulkCompletion;
        self.onBulkCompletion = nil;
        bulkCompletion(success ? 0 : -1);
    }
    
    [self.delegate parser:self bulkTransferEndedWithSuccess:success bulkId:self.transferState.bulkId];
}

@end
