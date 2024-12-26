//
//  MenuBarViewModel.swift
//  WireDrop
//
//  Created by Anton Meier on 2024-12-22.
//

import Combine
import SwiftUI

// MARK: Initialization

final class MenuBarViewModel: ObservableObject {
    private let appManager: MacAppManager
    private let onClose: () -> Void
    private let focusStateSubject = CurrentValueSubject<MenuBarViewState.FocusState, Never>(.none)
    private let isMenuOpenSubject = CurrentValueSubject<Bool, Never>(false)

    @Published var state: MenuBarViewState

    init(appManager: MacAppManager = .shared, onClose: @escaping () -> Void) {
        self.appManager = appManager
        self.onClose = onClose
        self.state = MenuBarViewState(appManager: appManager)
        setup()
    }
}

// MARK: Setup

private extension MenuBarViewModel {
    func setup() {
        Publishers.CombineLatest(
            Publishers.CombineLatest4(
                appManager.state.transferStateSubject,
                appManager.state.transferProgressSubject,
                appManager.state.isConnectedSubject,
                focusStateSubject
            ),
            isMenuOpenSubject
        )
        .compactMap { [weak appManager] in
            let (transferState, progress, isConnected, focusState) = $0.0
            let isMenuOpen = $0.1
            guard let appManager else {
                return nil
            }

            return MenuBarViewState(
                appManager: appManager,
                transferState: transferState,
                transferProgress: progress,
                isConnected: isConnected,
                focusState: focusState,
                isMenuOpen: isMenuOpen
            )
        }
        .removeDuplicates()
        .assign(to: &$state)
    }
}

// MARK: Private Vars

private extension MenuBarViewModel {
    var isMainWindowOpen: Bool {
        mainWindow != nil
    }

    var mainWindow: NSWindow? {
        NSApp.windows.first { $0.title == L10n.General.Constants.appName }
    }
}

// MARK: Public Methods

extension MenuBarViewModel {
    @MainActor
    func onAppear() {
        WDLog.log("MenuBarView onAppear")
        isMenuOpenSubject.value = true
    }

    @MainActor
    func onDisappear() {
        WDLog.log("MenuBarView onDisappear")
        isMenuOpenSubject.value = false
    }

    @MainActor
    func didTapQuit() {
        WDLog.log("MenuBarView didTapQuit")
        appManager.terminate()
        NSApplication.shared.terminate(self)
    }

    @MainActor
    func didTapSendFile(_ openWindow: (String) -> Void) {
        WDLog.log("MenuBarView didTapSendFile")
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate(ignoringOtherApps: true)

        if !isMainWindowOpen {
            openWindow(WireDropMacApp.windowGroupID)
        }

        if let window = mainWindow {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                window.makeKeyAndOrderFront(nil)
            }
        }

        onClose()
    }

    @MainActor
    func didChangeFocusState(_ state: MenuBarViewState.FocusState) {
        WDLog.log("MenuBarView didChangeFocusState: \(state)")
        focusStateSubject.value = state
    }
}
