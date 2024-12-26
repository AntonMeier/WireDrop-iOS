//
//  ContentViewModel.swift
//  WireDrop
//
//  Created by Anton Meier on 2024-12-20.
//

import Combine
import SwiftUI

// MARK: Initialization

final class ContentViewModel: ObservableObject {
    private let appManager: MacAppManager

    @Published var state: ContentViewState

    init(appManager: MacAppManager = .shared) {
        self.appManager = appManager
        self.state = ContentViewState(appManager: appManager)
        setup()
    }
}

// MARK: Setup

private extension ContentViewModel {
    func setup() {
        Publishers.CombineLatest4(
            appManager.state.transferStateSubject,
            appManager.state.transferProgressSubject,
            appManager.state.isProgressBarHiddenSubject,
            appManager.state.isConnectedSubject
        )
        .compactMap { [weak appManager] in
            let (transferState, progress, isProgressBarHidden, isConnected) = $0
            guard let appManager else {
                return nil
            }

            return ContentViewState(
                appManager: appManager,
                transferState: transferState,
                transferProgress: progress,
                isProgressBarHidden: isProgressBarHidden,
                isConnected: isConnected
            )
        }
        .removeDuplicates()
        .assign(to: &$state)
    }
}

// MARK: Public Methods

extension ContentViewModel {
    @MainActor
    func onAppear() {
        WDLog.log("ContentView onAppear")
    }

    @MainActor
    func onDisappear() {
        WDLog.log("ContentView onDisappear")
    }

    @MainActor
    func didDropProviders(_ providers: [NSItemProvider]) -> Bool {
        WDLog.log("ContentView didDropProviders count: \(providers.count)")
        guard state.remoteClientType == .app else {
            WDLog.log("Error: Cannot send file to app extension")
            return false
        }

        guard state.isConnected else {
            WDLog.log("Error: Cannot send file while not connected")
            return false
        }

        guard !providers.isEmpty, providers.count <= 10 else {
            WDLog.log("Error: Cannot drop more than 10 files")
            return false
        }

        startTransfer(of: providers)
        return true
    }
}

// MARK: Private Methods

private extension ContentViewModel {
    func startTransfer(of providers: [NSItemProvider]) {
        DispatchQueue.main.async { [appManager] in
            appManager.sendItems(attachments: providers)
        }
    }
}
