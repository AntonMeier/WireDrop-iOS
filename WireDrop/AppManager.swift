//
//  AppManager.swift
//  WireDrop
//
//  Created by Anton Meier on 2024-03-29.
//

import Combine
import Foundation
import UIKit

// MARK: Initialization

class AppManager: NSObject {
    static let shared = AppManager.initial

    let localClientType: ClientType
    let state = AppManagerState()

    private let appDispatch = AppDispatch()
    private let feedbackGenerator = FeedbackGenerator()

    #if !IS_APP_TARGET
    var extensionContext: (() -> NSExtensionContext?)?
    var onDismiss: (() -> Void)?
    #endif

    private lazy var usbClient = USBClient(configuration: usbClientConfiguration, delegate: self)
    private lazy var transferManager: TransferManager = {
        let state = TransferManagerState(localClientType: localClientType)
        return TransferManager(state: state, connection: usbClient, transferActions: transferActions)
    }()

    private var remoteConfiguration: USBServerConfiguration?
    private var receivedBulkFiles = [Data]()
    private var terminated = false
    private var subscribers = Set<AnyCancellable>()

    init(clientType: ClientType) {
        self.localClientType = clientType
        super.init()
        setup()
    }
}

// MARK: Private Vars

private extension AppManager {
    static var initial: AppManager {
        #if IS_APP_TARGET
        AppManager(clientType: .app)
        #else
        AppManager(clientType: .appExtension)
        #endif
    }

    var usbClientConfiguration: USBClientConfiguration {
        guard let configuration = USBClientConfiguration(
            identifier: UUID().uuidString,
            name: UIDevice.current.name,
            hardwareMachine: USBClient.hardwareModel(),
            version: UInt32(WC_CLIENT_PROTOCOL_VERSION),
            minVersion: UInt32(WC_MIN_SUPPORTED_CLIENT_PROTOCOL_VERSION),
            clientType: UInt32(localClientType.rawValue)
        ) else {
            preconditionFailure("Unable to initialize client configuration")
        }

        return configuration
    }

    var remoteHostName: String {
        remoteConfiguration?.name ?? L10n.General.Label.unknownDevice
    }

    var localHostName: String {
        usbClient.configuration.name
    }

    var transferActions: TransferActions {
        TransferActions(
            onFragmentDelivered: { _, _, _, _ in },
            onFileTransferAccepted: { [weak self] _, fileNo, total in
                if fileNo == 0, total == 1 {
                    self?.feedbackGenerator.impact()
                }
            },
            onFileTransferComplete: { _ in },
            onFileReceived: { [weak self] file, _, isBulkTransfer in
                if isBulkTransfer {
                    WDLog.log("We are performing a bulk transfer -> Postponing file export")
                    self?.receivedBulkFiles.append(file)
                } else {
                    self?.export(files: [file])
                }
            },
            onBulkTransferAccepted: { [weak self] _, _, _ in
                self?.feedbackGenerator.impact()
            },
            onBulkTransferComplete: { [weak self] success, _ in
                guard success, let self else {
                    WDLog.log("Transfer was unsuccessful -> Ignoring export")
                    return
                }

                self.export(files: self.receivedBulkFiles)
            }
        )
    }
}

// MARK: Public Vars

extension AppManager {
    var remoteClientType: ClientType? {
        ClientType(rawValue: remoteConfiguration?.clientType)
    }

    var hostNames: HostNames {
        HostNames(local: localHostName, remote: remoteHostName)
    }
}

// MARK: Private Methods

private extension AppManager {
    func setup() {
        openSockets()
        appDispatch.add(responder: self)
        setupStateSubscribers()
    }

    func setupStateSubscribers() {
        transferManager.state.currentTransferStateValue
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.transferStateChanged(state)
            }
            .store(in: &subscribers)

        transferManager.state.currentTransferProgressValue
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.state.update(transferProgress: $0)
            }
            .store(in: &subscribers)
    }

    func openSockets() {
        guard !terminated else {
            WDLog.log("This session has been terminated, not starting!")
            return
        }

        guard !state.isConnected, !usbClient.isListeningOnSocket() else {
            WDLog.log("Socket already open, not starting")
            return
        }

        WDLog.log("Open socket")
        usbClient.startSocket { WDLog.log("did open with error: \(String(describing: $0))") }
    }

    func closeSockets() {
        WDLog.log("Close socket")
        usbClient.stopSocket()
    }

    func export(files: [Data]) {
        #if IS_APP_TARGET
        WDLog.log("Exporting \(files.count) file(s)")
        receivedBulkFiles = []
        guard !files.isEmpty else {
            WDLog.log("Error: Cannot export empty file list")
            return
        }

        let activityViewController = UIActivityViewController(activityItems: files, applicationActivities: nil)
        activityViewController.excludedActivityTypes = [
            .assignToContact,
            .print,
            .collaborationCopyLink,
            .sharePlay,
            .markupAsPDF
        ]
        activityViewController.completionWithItemsHandler = { [weak self] _, _, _, _ in
            WDLog.log("Share sheet completed")
            self?.transferManager.shareSheetDidComplete()
        }

        guard let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
              let rootViewController = windowScene.keyWindow?.rootViewController
        else {
            WDLog.log("Error: Unable to locate root view controller")
            return
        }

        rootViewController.present(activityViewController, animated: true, completion: nil)
        #endif
    }

    func transferStateChanged(_ transferState: TransferState) {
        WDLog.log("Transfer state changed: \(transferState)")
        state.update(transferState: transferState)
        switch transferState {
        case .complete:
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
                self?.feedbackGenerator.notification()
                self?.state.update(progressBarHidden: true)
            }
        case .failed, .sending, .waiting, .none:
            state.update(progressBarHidden: transferState.isProgressBarHidden)
        }
    }

    func disableIdleTimer() {
        #if IS_APP_TARGET
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            UIApplication.shared.isIdleTimerDisabled = false
            UIApplication.shared.isIdleTimerDisabled = true
        }
        #endif
    }

    func enableIdleTimer() {
        #if IS_APP_TARGET
        UIApplication.shared.isIdleTimerDisabled = false
        #endif
    }
}

// MARK: Public Methods

extension AppManager {
    func terminate() {
        guard !terminated else {
            return
        }

        WDLog.log("Terminate")
        terminated = true
        transferManager.didDisconnect()
        closeSockets()
        appDispatch.remove(responder: self)
    }

    func sendItems(attachments: [NSItemProvider]) {
        guard !attachments.isEmpty else {
            return
        }

        WDLog.log("AppManager will start new transfer with \(attachments.count) file(s)")
        transferManager.prepareForNewTransfer()
        guard attachments.count > 1 else {
            transferManager.sendFiles(attachments: attachments, files: attachments.count) { _ in }
            return
        }

        transferManager.startBulkTransfer(with: attachments, files: attachments.count)
    }
}

// MARK: AppManager+USBClientDelegate

extension AppManager: USBClientDelegate {
    func usbClientDidStartConnection(_: USBClient) {
        WDLog.log("usbClientDidStartConnection:")
    }

    func usbClient(_: USBClient, didEndConnectionWithError _: any Error) {
        WDLog.log("client:didEndConnectionWithError:")
    }

    func usbClient(_: USBClient, didFailToSend _: Data) {
        WDLog.log("client:didFailToSend:")
    }

    func usbClient(_: USBClient, gotDataPacket packet: Data) {
        WDLog.log("client:gotDataPacket: size: \(packet.count)")
        transferManager.didReceive(packet: packet)
    }

    func usbClient(_: USBClient, didStartConnectionToServerWith configuration: USBServerConfiguration) {
        WDLog.log("client:didStartConnectionToServerWithConfiguration:")
        transferManager.didConnect()
        remoteConfiguration = configuration
        state.update(connected: true)
        let versionState = ConnectionVersion(
            localVersion: usbClient.configuration.protocolVersion,
            localMinVersion: usbClient.configuration.minSupportedProtocolVersion,
            remoteVersion: configuration.protocolVersion,
            remoteMinVersion: configuration.minSupportedProtocolVersion
        )
        transferManager.didUpdate(versionState: versionState)
    }

    func usbClient(_: USBClient, didEndConnectionToServerWith _: USBServerConfiguration, error _: any Error) {
        WDLog.log("client:didEndConnectionToServerWith:")
        transferManager.didDisconnect()
        state.update(connected: false)
        remoteConfiguration = nil
        transferManager.resetParser()
    }
}

// MARK: AppManager+AppDispatchResponder

extension AppManager: AppDispatchResponder {
    func didBecomeActive() {
        openSockets()
        disableIdleTimer()
    }

    func willBecomeInactive() {
        enableIdleTimer()
    }

    func didEnterBackground() {
        closeSockets()
    }
}
