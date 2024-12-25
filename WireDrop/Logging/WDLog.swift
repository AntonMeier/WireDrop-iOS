//
//  WDLog.swift
//  WireDrop
//
//  Created by Anton Meier on 2024-04-07.
//

import Foundation

// MAKR: WDLog

#if DEBUG

enum WDLog {
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "mm:ss.SSS"
        return formatter
    }()

    static func logq(_ message: String) {
        let message = "[WDLog \(dateFormatter.string(from: Date()))] [\(Self.currentQueueName())] \(message)"
        print(message)
    }

    static func logq(_ message: String, _ obj: AnyObject) {
        logq("\(message) [\(String(format: "%02X", UInt(bitPattern: ObjectIdentifier(obj))))]")
    }

    static func log(_ message: String) {
        let message = "[WDLog \(dateFormatter.string(from: Date()))] \(message)"
        print(message)
    }

    static func log(_ message: String, _ obj: AnyObject) {
        log("\(message) [\(String(format: "%02X", UInt(bitPattern: ObjectIdentifier(obj))))]")
    }

    static func log(_ message: String, _ obj1: AnyObject, _ obj2: AnyObject) {
        log("\(message) [\(String(UInt(bitPattern: ObjectIdentifier(obj1))))] [\(String(UInt(bitPattern: ObjectIdentifier(obj2))))]")
    }

    static func currentQueueName() -> String {
        let name = __dispatch_queue_get_label(nil)
        return String(cString: name, encoding: .utf8) ?? "."
    }
}

#else

enum WDLog {
    static func logq(_: String) {}
    static func logq(_: String, _: AnyObject) {}
    static func log(_: String) {}
    static func log(_: String, _: AnyObject) {}
    static func log(_: String, _: AnyObject, _: AnyObject) {}
}

#endif
