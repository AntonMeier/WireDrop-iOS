//
//  TransferManagerState.swift
//  WireDrop
//
//  Created by Anton Meier on 2024-12-18.
//

import Combine
import Foundation

// MARK: Initialization

final class TransferManagerState {
    let localClientType: ClientType
    let currentTransferStateValue = CurrentValueSubject<TransferState, Never>(.none)
    let currentTransferProgressValue = CurrentValueSubject<Double, Never>(0.0)

    var fileTransferState: TransferState {
        didSet {
            guard !isBulkTransfer else {
                return
            }

            currentTransferStateValue.value = fileTransferState
        }
    }

    var bulkTransferState: TransferState {
        didSet {
            guard oldValue != .none || isBulkTransfer else {
                return
            }

            currentTransferStateValue.value = bulkTransferState
        }
    }

    var fileProgress = 0.0 {
        didSet {
            guard !isBulkTransfer else {
                return
            }

            currentTransferProgressValue.value = fileProgress
        }
    }

    var bulkProgress = 0.0 {
        didSet {
            guard isBulkTransfer else {
                return
            }

            currentTransferProgressValue.value = bulkProgress
        }
    }

    init(localClientType: ClientType, fileTransferState: TransferState = .none, bulkTransferState: TransferState = .none) {
        self.localClientType = localClientType
        self.fileTransferState = fileTransferState
        self.bulkTransferState = bulkTransferState
    }
}

// MARK: Public Vars

extension TransferManagerState {
    var isTransferAllowed: Bool {
        fileTransferState == .none || localClientType == .macOSApp
    }

    var isBulkTransfer: Bool {
        bulkTransferState != .none
    }
}
