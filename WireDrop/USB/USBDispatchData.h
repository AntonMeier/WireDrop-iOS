//
//  USBDispatchData.h
//  WireDrop
//
//  Created by Anton Meier on 2021-01-15.
//  Based on PTExampleProtocol in rsms/peertalk
//

#ifndef USBDispatchData_h
#define USBDispatchData_h

static dispatch_data_t WCPTTextDispatchDataWithData(NSData *data)
{
    size_t length = data.length;
    
    WCPTDataFrame *dataFrame = CFAllocatorAllocate(nil, sizeof(WCPTDataFrame) + length, 0);
    
    [data getBytes:dataFrame->data length:length];
    dataFrame->length = htonl(length); // Convert integer to network byte order
    
    // Wrap the textFrame in a dispatch data object
    return dispatch_data_create((const void*)dataFrame, sizeof(WCPTDataFrame)+length, nil, ^{
        CFAllocatorDeallocate(nil, dataFrame);
    });
}

static dispatch_data_t WCPTTextDispatchDataWithDataArray(NSArray<NSData *> *dataArr)
{
    size_t length = 0;
    
    for (NSData *d in dataArr)
    {
        length += d.length;
    }
    
    WCPTDataFrame *dataFrame = CFAllocatorAllocate(nil, sizeof(WCPTDataFrame) + length, 0);
    
    int i = 0;
    
    for (NSData *d in dataArr)
    {
        [d getBytes:(dataFrame->data)+i length:d.length];
        i += d.length;
    }
    
    dataFrame->length = htonl(length); // Convert integer to network byte order
    
    // Wrap the textFrame in a dispatch data object
    return dispatch_data_create((const void*)dataFrame, sizeof(WCPTDataFrame)+length, nil, ^
    {
        CFAllocatorDeallocate(nil, dataFrame);
    });
}

#endif /* USBDispatchData_h */
