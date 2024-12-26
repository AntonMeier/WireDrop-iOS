//
//  ProtocolStructs.h
//  WireDrop
//
//  Created by Anton Meier on 2024-03-30.
//

#ifndef ProtocolStructs_h
#define ProtocolStructs_h

typedef NS_ENUM(NSInteger, OPCODE_FROM_CLIENT)
{
    // V0
    OPCODE_FROM_CLIENT_FILE_START,
    OPCODE_FROM_CLIENT_FILE_SEGMENT,
    OPCODE_FROM_CLIENT_FILE_END,
    OPCODE_FROM_SERVER_FILE_START_RESPONSE,
    OPCODE_FROM_SERVER_FILE_END_RESPONSE,
    OPCODE_FROM_CLIENT_BULK_START,
    OPCODE_FROM_CLIENT_BULK_END,
    OPCODE_FROM_SERVER_BULK_START_RESPONSE,
    OPCODE_FROM_SERVER_BULK_END_RESPONSE,
};

struct FileTransferHeader
{
    uint16_t opcode;
    uint16_t fileId;
} __attribute((packed));
typedef struct FileTransferHeader FileTransferHeader;

struct FileStartRequest
{
    FileTransferHeader header;
    uint16_t clientType;
    uint16_t fragments;
    uint32_t totalDataSize;
    uint16_t fileNo;
    uint16_t filenameLength;
    char filename[];
} __attribute((packed));
typedef struct FileStartRequest FileStartRequest;

struct FileEndNotification
{
    FileTransferHeader header;
} __attribute((packed));
typedef struct FileEndNotification FileEndNotification;

struct FileStartAck
{
    FileTransferHeader header;
    uint8_t accepted;
    uint8_t reason;
} __attribute((packed));
typedef struct FileStartAck FileStartAck;

struct FileEndAck
{
    FileTransferHeader header;
    uint8_t success;
    uint8_t reason;
} __attribute((packed));
typedef struct FileEndAck FileEndAck;

struct FileSegmentInd
{
    FileTransferHeader header;
    uint8_t fragmentNo;
    uint32_t fragmentSize;
    char data[];
} __attribute((packed));
typedef struct FileSegmentInd FileSegmentInd;

struct BulkTransferHeader
{
    uint16_t opcode;
    uint16_t bulkId;
} __attribute((packed));
typedef struct BulkTransferHeader BulkTransferHeader;

struct BulkStartRequest
{
    BulkTransferHeader header;
    uint16_t clientType;
    uint16_t fileCount;
} __attribute((packed));
typedef struct BulkStartRequest BulkStartRequest;

struct BulkEndRequest
{
    BulkTransferHeader header;
    uint8_t aborted;
    uint8_t reason;
} __attribute((packed));
typedef struct BulkEndRequest BulkEndRequest;

struct BulkStartResponse
{
    BulkTransferHeader header;
    uint8_t accepted;
    uint8_t reason;
} __attribute((packed));
typedef struct BulkStartResponse BulkStartResponse;

struct BulkEndResponse
{
    BulkTransferHeader header;
    uint8_t success;
    uint8_t reason;
} __attribute((packed));
typedef struct BulkEndResponse BulkEndResponse;

#endif
