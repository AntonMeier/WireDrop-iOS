//
//  TransferState.swift
//  WireDrop
//
//  Created by Anton Meier on 2024-03-31.
//

import Foundation
import SwiftUI

// MARK: TransferState

enum TransferState {
    case none
    case waiting
    case sending
    case complete
    case failed
}

// MARK: Public Vars

extension TransferState {
    var title: String {
        switch self {
        case .none: ""
        case .waiting: L10n.General.Label.waiting
        case .sending: L10n.General.Label.sending
        case .complete: L10n.General.Label.sent
        case .failed: L10n.General.Label.failed
        }
    }

    var receiverTitle: String {
        switch self {
        case .none: L10n.General.Label.waitingToReceiveFiles
        case .waiting: L10n.General.Label.waitingToReceiveFiles
        case .sending: L10n.General.Label.receiving
        case .complete: L10n.General.Label.received
        case .failed: L10n.General.Label.transferFailed
        }
    }

    var macSenderTitle: String {
        switch self {
        case .none: L10n.General.Label.dropYourFilesHere
        case .waiting: L10n.General.Label.waiting
        case .sending: L10n.General.Label.sending
        case .complete: L10n.General.Label.sent
        case .failed: L10n.General.Label.transferFailed
        }
    }

    var tintColor: Color {
        switch self {
        case .complete: Colors.main
        case .failed: Colors.red
        case .none, .sending, .waiting: .secondary
        }
    }

    var isProgressBarHidden: Bool {
        switch self {
        case .complete, .failed, .none: true
        case .sending, .waiting: false
        }
    }
}
