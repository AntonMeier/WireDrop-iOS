//
//  ShareViewState.swift
//  WireDrop
//
//  Created by Anton Meier on 2024-12-15.
//

import Foundation

// MARK: Initialization

struct ShareViewState: Equatable {
    let localClientType: ClientType
    let remoteClientType: ClientType?
    let hostNames: HostNames
    let transferState: TransferState
    let transferProgress: Double
    let isProgressBarHidden: Bool
    let isConnected: Bool
}

// MARK: Convenience

extension ShareViewState {
    init(
        appManager: AppManager,
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

    init(appManager: AppManager) {
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

extension ShareViewState {
    var avatarImageName: String {
        "person.crop.circle.fill"
    }

    var deviceImageName: String {
        "laptopcomputer"
    }
}
