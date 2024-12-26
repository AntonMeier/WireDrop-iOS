//
//  MenuBarViewState.swift
//  WireDrop
//
//  Created by Anton Meier on 2024-12-22.
//

import Foundation
import SwiftUI

// MARK: Initialization

struct MenuBarViewState: Equatable {
    let remoteClientType: ClientType?
    let hostNames: HostNames
    let transferState: TransferState
    let transferProgress: Double
    let isConnected: Bool
    let focusState: FocusState
    let isMenuOpen: Bool
}

// MARK: Convenience

extension MenuBarViewState {
    init(
        appManager: MacAppManager,
        transferState: TransferState,
        transferProgress: Double,
        isConnected: Bool,
        focusState: FocusState,
        isMenuOpen: Bool
    ) {
        self.init(
            remoteClientType: appManager.remoteClientType,
            hostNames: appManager.hostNames,
            transferState: transferState,
            transferProgress: transferProgress,
            isConnected: isConnected,
            focusState: focusState,
            isMenuOpen: isMenuOpen
        )
    }

    init(appManager: MacAppManager) {
        self.init(
            remoteClientType: appManager.remoteClientType,
            hostNames: appManager.hostNames,
            transferState: appManager.state.transferState,
            transferProgress: appManager.state.transferProgress,
            isConnected: appManager.state.isConnected,
            focusState: .none,
            isMenuOpen: false
        )
    }
}

// MARK: Public Vars

extension MenuBarViewState {
    var progressAnimationType: Animation? {
        transferProgress != 0.0 && isMenuOpen ? .easeIn : .none
    }

    var deviceImageName: String {
        "iphone"
    }
}

// MARK: FocusState

extension MenuBarViewState {
    enum FocusState {
        case none
        case sendFile
        case quit
    }
}
