//
//  ContentViewState.swift
//  WireDrop
//
//  Created by Anton Meier on 2024-12-20.
//

import Foundation
import SwiftUI

// MARK: Initialization

struct ContentViewState: Equatable {
    let localClientType: ClientType
    let remoteClientType: ClientType?
    let hostNames: HostNames
    let transferState: TransferState
    let transferProgress: Double
    let isProgressBarHidden: Bool
    let isConnected: Bool
}

// MARK: Convenience

extension ContentViewState {
    init(
        appManager: MacAppManager,
        transferState: TransferState,
        transferProgress: Double,
        isProgressBarHidden: Bool,
        isConnected: Bool
    ) {
        self.init(
            localClientType: appManager.localClientType,
            remoteClientType: appManager.remoteClientType,
            hostNames: appManager.hostNames,
            transferState: transferState,
            transferProgress: transferProgress,
            isProgressBarHidden: isProgressBarHidden,
            isConnected: isConnected
        )
    }

    init(appManager: MacAppManager) {
        self.init(
            localClientType: appManager.localClientType,
            remoteClientType: appManager.remoteClientType,
            hostNames: appManager.hostNames,
            transferState: appManager.state.transferState,
            transferProgress: appManager.state.transferProgress,
            isProgressBarHidden: appManager.state.isProgressBarHidden,
            isConnected: appManager.state.isConnected
        )
    }
}

// MARK: Public Vars

extension ContentViewState {
    var progressAnimationType: Animation? {
        transferProgress != 0.0 ? .easeIn : .none
    }

    var deviceImageName: String {
        "iphone"
    }

    var addImageName: String {
        "plus.circle.fill"
    }
}
