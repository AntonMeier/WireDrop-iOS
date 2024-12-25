//
//  MenuBarController.swift
//  WireDrop
//
//  Created by Anton Meier on 2024-12-22.
//

import Cocoa
import SwiftUI

// MARK: Initialization

class MenuBarController {
    private let appManager: MacAppManager
    private var statusItem: NSStatusItem?

    init(appManager: MacAppManager = .shared) {
        self.appManager = appManager
        setup()
    }
}

// MARK: Private Vars

private extension MenuBarController {
    var iconView: some View {
        ZStack(alignment: .center) {
            Image("mac_menu_item", bundle: .main)
                .padding(.bottom, 2)
        }
    }
}

// MARK: Private Methods

private extension MenuBarController {
    func setup() {
        let menuBarView = MenuBarView(viewModel: MenuBarViewModel(onClose: { [weak self] in
            self?.statusItem?.menu?.cancelTracking()
        }))

        let hostingView = NSHostingView(rootView: menuBarView)
        hostingView.frame = NSRect(x: 0, y: 0, width: 300, height: 122)
        let iconView = iconView
        let iconHostingView = NSHostingView(rootView: iconView)
        iconHostingView.frame = NSRect(x: 0, y: 0, width: 30, height: 22)
        let menuItem = NSMenuItem()
        menuItem.view = hostingView
        let menu = NSMenu()
        menu.addItem(menuItem)

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem?.menu = menu
        statusItem?.button?.addSubview(iconHostingView)
        statusItem?.button?.frame = iconHostingView.frame
    }
}
