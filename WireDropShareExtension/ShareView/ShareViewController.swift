//
//  ShareViewController.swift
//  WireDropShareExtension
//
//  Created by Anton Meier on 2024-03-29.
//

import CoreServices
import SwiftUI
import UIKit

// MARK: Initialization

@objc(PrincipalClassName)
class ShareViewController: UIViewController {
    private let appManager = AppManager.shared
}

// MARK: Private Methods

private extension ShareViewController {
    func setup() {
        setupHandlers()
        setupView()
    }

    func setupHandlers() {
        appManager.extensionContext = { [weak self] in
            self?.extensionContext
        }
        appManager.onDismiss = { [weak self] in
            self?.dismiss(animated: true) {
                self?.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
            }
        }
    }

    func setupView() {
        let shareView = ShareView(viewModel: ShareViewModel(appManager: appManager))
        let hostingController = UIHostingController(rootView: shareView)
        let containerView = UIView()

        containerView.backgroundColor = .systemBackground
        view.addSubview(containerView)
        containerView.addSubview(hostingController.view)
        hostingController.view.pinToEdges(of: containerView)
        containerView.pinToEdges(of: view)

        addChild(hostingController)
    }
}

// MARK: ShareViewController+UIViewController

extension ShareViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        guard (extensionContext?.inputItems.first as? NSExtensionItem)?.attachments != nil else {
            WDLog.log("Error: Attachments missing")
            return
        }

        setup()
    }

    override func viewWillAppear(_: Bool) {
        WDLog.log("ShareViewController viewWillAppear")
        appManager.didBecomeActive()
    }

    override func viewDidDisappear(_: Bool) {
        WDLog.log("ShareViewController viewDidDisappear")
        appManager.terminate()
    }
}

// MARK: UIView+PinToEdges

private extension UIView {
    func pinToEdges(of containerView: UIView) {
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            topAnchor.constraint(equalTo: containerView.topAnchor),
            bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
    }
}
