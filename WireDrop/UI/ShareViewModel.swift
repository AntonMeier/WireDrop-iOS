//
//  ShareViewModel.swift
//  WireDrop
//
//  Created by Anton Meier on 2024-12-15.
//

import Combine
import SwiftUI

// MARK: Initialization

final class ShareViewModel: ObservableObject {
    private let appManager: AppManager

    @Published var state: ShareViewState

    init(appManager: AppManager = .shared) {
        self.appManager = appManager
        self.state = ShareViewState(appManager: appManager)
        setup()
    }
}

// MARK: Setup

private extension ShareViewModel {
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

            return ShareViewState(
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

extension ShareViewModel {
    @MainActor
    func didTapDevice() {
        WDLog.log("ShareView didTapDevice")
        startTransfer()
    }

    @MainActor
    func didTapDone() {
        WDLog.log("ShareView didTapDone")
        stopTransfer()
    }

    @MainActor
    func onAppear() {
        WDLog.log("ShareView onAppear")
    }

    @MainActor
    func onDisappear() {
        WDLog.log("ShareView onDisappear")
    }
}

// MARK: Private Methods

private extension ShareViewModel {
    func startTransfer() {
        #if !IS_APP_TARGET
        guard let extensionContext = appManager.extensionContext?(),
              let attachments = (extensionContext.inputItems.first as? NSExtensionItem)?.attachments
        else {
            WDLog.log("Error: Unable to locate attachments")
            return
        }

        DispatchQueue.main.async { [appManager] in
            appManager.sendItems(attachments: attachments)
        }
        #endif
    }

    func stopTransfer() {
        DispatchQueue.main.async { [appManager] in
            appManager.terminate()
            #if !IS_APP_TARGET
            appManager.onDismiss?()
            #endif
        }
    }
}
