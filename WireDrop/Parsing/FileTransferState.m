//
//  FileTransferState.m
//  WireDrop
//
//  Created by Anton Meier on 2024-12-23.
//

#import "FileTransferState.h"

@implementation FileTransferState

- (instancetype)init;
{
    self = [super init];
    
    if (self)
    {
        self.totalFiles = 1;
    }

    return self;
}

@end
