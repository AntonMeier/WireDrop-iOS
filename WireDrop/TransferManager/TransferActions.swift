//
//  TransferActions.swift
//  WireDrop
//
//  Created by Anton Meier on 2024-12-18.
//

// MARK: Initialization

struct TransferActions {
    let onFragmentDelivered: (_ fragment: Int32, _ currentFileNo: Int32, _ fragments: Int32, _ files: Int32) -> Void
    let onFileTransferAccepted: (_ fileId: Int32, _ fileNo: Int32, _ total: Int32) -> Void
    let onFileTransferComplete: (_ fileId: Int32) -> Void
    let onFileReceived: (_ file: Data, _ filename: String?, _ isBulkTransfer: Bool) -> Void
    let onBulkTransferAccepted: (_ accepted: Bool, _ bulkId: Int32, _ total: Int32) -> Void
    let onBulkTransferComplete: (_ success: Bool, _ bulkId: Int32) -> Void
}
