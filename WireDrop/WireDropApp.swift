//
//  WireDropApp.swift
//  WireDrop
//
//  Created by Anton Meier on 2024-03-29.
//

import SwiftUI

// MARK: Initialization

@main
struct WireDropApp: App {}

// MARK: Body

extension WireDropApp {
    var body: some Scene {
        WindowGroup {
            ShareView(viewModel: ShareViewModel())
        }
    }
}
