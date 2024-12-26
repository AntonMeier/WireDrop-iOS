//
//  String+Localized.swift
//  WireDrop
//
//  Created by Anton Meier on 2024-12-23.
//

import Foundation

// MARK: String+Localized

private extension String {
    func localized() -> String {
        // TODO: If we decide to add language translations in the future, make sure that we load
        // the correct lproj bundles and fallback to 'EN' where necessary.
        NSLocalizedString(
            self,
            tableName: "General",
            bundle: .main,
            value: "", // Fallback value, currently unused.
            comment: ""
        )
    }
}

enum L10n {
    enum General {
        enum Constants {
            static var appName: String { "wire_drop".localized() }
        }

        enum Button {
            static var sendFile: String { "button.send_file".localized() }
            static var quit: String { "button.quit".localized() }
            static var done: String { "button.done".localized() }
        }

        enum Label {
            static var noDeviceAttached: String { "label.no_device_attached".localized() }
            static var cantSeeYourDevice: String { "label.cant_see_your_device".localized() }
            static var openAppOnIos: String { "label.open_app_on_ios".localized() }
            static var openAppOnMac: String { "label.open_app_on_mac".localized() }
            static var waitingForDevice: String { "label.waiting_for_device".localized() }
            static var sendCopyWith: String { "label.send_copy_with".localized() }
            static var devices: String { "label.devices".localized() }
            static var appearAs: String { "label.appear_as".localized() }
            static var unknownDevice: String { "label.unknown_device".localized() }
            static var waiting: String { "label.waiting".localized() }
            static var sending: String { "label.sending".localized() }
            static var sent: String { "label.sent".localized() }
            static var receiving: String { "label.receiving".localized() }
            static var received: String { "label.received".localized() }
            static var failed: String { "label.failed".localized() }
            static var transferFailed: String { "label.transfer_failed".localized() }
            static var waitingToReceiveFiles: String { "label.waiting_to_receive_files".localized() }
            static var dropYourFilesHere: String { "label.drop_your_files_here".localized() }
        }
    }
}
