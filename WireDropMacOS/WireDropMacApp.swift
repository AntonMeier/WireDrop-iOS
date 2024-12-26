//
//  WireDropMacApp.swift
//  WireDropMacOS
//
//  Created by Anton Meier on 2024-03-29.
//

import AppKit
import Cocoa
import SwiftUI

// MARK: Initialization

@main
struct WireDropMacApp: App {
    static let windowGroupID = "WireDrop-MainWindow"

    private let mainMenu: MenuBarController

    init() {
        self.mainMenu = MenuBarController()
    }
}

// MARK: Body

extension WireDropMacApp {
    var body: some Scene {
        WindowGroup(L10n.General.Constants.appName, id: WireDropMacApp.windowGroupID) {
            ContentView(viewModel: ContentViewModel())
                .frame(width: 500)
                .onDisappear {
                    NSApplication.shared.setActivationPolicy(.accessory)
                }
        }
        .windowResizabilityContentSize()
    }
}

// MARK: Scene+Resizability

private extension Scene {
    func windowResizabilityContentSize() -> some Scene {
        if #available(macOS 13.0, *) {
            return windowResizability(.contentSize)
        } else {
            return self
        }
    }
}
