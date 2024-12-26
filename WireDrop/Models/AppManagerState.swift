//
//  AppManagerState.swift
//  WireDrop
//
//  Created by Anton Meier on 2024-12-23.
//

import Combine
import Foundation

// MARK: Initialization

struct AppManagerState {
    let isProgressBarHiddenSubject = CurrentValueSubject<Bool, Never>(true)
    let isConnectedSubject = CurrentValueSubject<Bool, Never>(false)
    let transferProgressSubject = CurrentValueSubject<Double, Never>(0.0)
    let transferStateSubject = CurrentValueSubject<TransferState, Never>(.none)
}

// MARK: Public Vars

extension AppManagerState {
    var isProgressBarHidden: Bool {
        isProgressBarHiddenSubject.value
    }

    var isConnected: Bool {
        isConnectedSubject.value
    }

    var transferProgress: Double {
        transferProgressSubject.value
    }

    var transferState: TransferState {
        transferStateSubject.value
    }
}

// MARK: Public Methods

extension AppManagerState {
    func update(progressBarHidden hidden: Bool) {
        isProgressBarHiddenSubject.value = hidden
    }

    func update(connected: Bool) {
        isConnectedSubject.value = connected
    }

    func update(transferProgress: Double) {
        transferProgressSubject.value = transferProgress
    }

    func update(transferState: TransferState) {
        transferStateSubject.value = transferState
    }
}
