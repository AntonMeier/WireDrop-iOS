//
//  ClientType.swift
//  WireDrop
//
//  Created by Anton Meier on 2024-04-09.
//

import Foundation

// MARK: ClientType

public enum ClientType: UInt32 {
    case macOSApp
    case app
    case appExtension
}

// MAKR: Convenience

extension ClientType {
    init?(rawValue: UInt32?) {
        guard let rawValue else {
            return nil
        }

        self.init(rawValue: rawValue)
    }
}

// MARK: Public Vars

extension ClientType {
    var clientParserType: CLIENT_TYPE {
        switch self {
        case .macOSApp: .MAC_APP
        case .app: .IOS_APP
        case .appExtension: .IOS_EXTENSION
        }
    }
}
