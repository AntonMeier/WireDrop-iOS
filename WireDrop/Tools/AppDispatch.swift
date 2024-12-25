//
//  AppDispatch.swift
//  WireDrop
//
//  Created by Anton Meier on 2024-04-07.
//

import UIKit

// MARK: Initialization

class AppDispatch {
    private var responders = [DispatchResponder]()

    init() {
        setup()
    }
}

// MARK: Private Methods

private extension AppDispatch {
    func setup() {
        NotificationCenter.default.removeObserver(self)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(willBecomeInactive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(willEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
    }

    @objc private func didBecomeActive() {
        WDLog.log("AppDispatch: didBecomeActive")
        dispatch { $0.didBecomeActive() }
    }

    @objc private func willBecomeInactive() {
        WDLog.log("AppDispatch: willBecomeInactive")
        dispatch { $0.willBecomeInactive() }
    }

    @objc private func willEnterForeground() {
        WDLog.log("AppDispatch: willEnterForeground")
        dispatch { $0.willEnterForeground() }
    }

    @objc private func didEnterBackground() {
        WDLog.log("AppDispatch: didEnterBackground")
        dispatch { $0.didEnterBackground() }
    }

    func dispatch(dispatch: @escaping (DispatchResponder) -> Void) {
        DispatchQueue.main.async { [self] in
            let responders = self.responders.reversed()
            for responder in responders {
                DispatchQueue.main.async {
                    dispatch(responder)
                }
            }
        }
    }
}

// MARK: Public Methods

extension AppDispatch {
    func add(responder: DispatchResponder) {
        DispatchQueue.main.async { [self] in
            if self.responders.first(where: { $0 == responder }) == nil {
                self.responders.append(responder)
            }
        }
    }

    func remove(responder: DispatchResponder) {
        DispatchQueue.main.async { [self] in
            self.responders = self.responders.filter { !($0 == responder) }
        }
    }
}

// MARK: AppDispatchResponder

protocol AppDispatchResponder {
    func didBecomeActive()
    func willBecomeInactive()
    func willEnterForeground()
    func didEnterBackground()
}

// MARK: Default

extension AppDispatchResponder {
    func didBecomeActive() {}
    func willBecomeInactive() {}
    func willEnterForeground() {}
    func didEnterBackground() {}
}

// MARK: DispatchResponder

typealias DispatchResponder = AppDispatchResponder & NSObject
