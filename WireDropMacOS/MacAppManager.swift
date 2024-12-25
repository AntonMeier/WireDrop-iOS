//
//  MacAppManager.swift
//  WireDropMacOS
//
//  Created by Anton Meier on 2024-03-29.
//

import Cocoa
import Combine
import Foundation

// MARK: Initialization

class MacAppManager: NSObject {
    static let shared = MacAppManager()

    let localClientType: ClientType = .macOSApp
    let state = AppManagerState()

    private lazy var usbServer = USBServer(configuration: usbServerConfiguration, delegate: self)
    private lazy var transferManager = TransferManager(
        state: TransferManagerState(localClientType: localClientType),
        connection: usbServer,
        transferActions: transferActions
    )
    private lazy var watchdog = RepeatingDispatch(duration: 15000, leeway: 1000) { [weak self] in
        self?.watchdogEvent()
    }

    private var remoteConfiguration: USBClientConfiguration?
    private var terminated = false
    private var subscribers = Set<AnyCancellable>()

    override init() {
        super.init()
        setup()
    }
}

// MARK: Private Vars

private extension MacAppManager {
    var usbServerConfiguration: USBServerConfiguration {
        guard let configuration = USBServerConfiguration(
            identifier: UUID().uuidString,
            name: Host.current().localizedName ?? L10n.General.Label.unknownDevice,
            hardwareModel: USBServer.hardwareModel(),
            version: UInt32(WC_CLIENT_PROTOCOL_VERSION),
            minVersion: UInt32(WC_MIN_SUPPORTED_CLIENT_PROTOCOL_VERSION),
            clientType: UInt32(localClientType.rawValue)
        ) else {
            preconditionFailure("Unable to initialize server configuration")
        }

        return configuration
    }

    var remoteHostName: String {
        remoteConfiguration?.name ?? L10n.General.Label.unknownDevice
    }

    var localHostName: String {
        usbServer.configuration.name
    }
}

// MARK: Public Vars

extension MacAppManager {
    var remoteClientType: ClientType? {
        ClientType(rawValue: remoteConfiguration?.clientType)
    }

    var hostNames: HostNames {
        HostNames(local: localHostName, remote: remoteHostName)
    }
}

// MARK: Private Methods

private extension MacAppManager {
    func setup() {
        openSockets()
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
        WDLog.log("Open sockets")
        usbServer.startSocket()
    }

    func closeSockets() {
        WDLog.log("Close sockets")
        usbServer.stopSocket()
    }

    func transferStateChanged(_ transferState: TransferState) {
        WDLog.log("Transfer state changed: \(transferState)")
        state.update(transferState: transferState)
        switch transferState {
        case .complete:
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
                self?.state.update(progressBarHidden: true)
            }
        case .failed, .sending, .waiting, .none:
            state.update(progressBarHidden: transferState.isProgressBarHidden)
        }
    }

    func export(file: Data, fileName: String?) {
        let fileName = fileName ?? "\(L10n.General.Constants.appName) (\(String(UUID().uuidString.suffix(12))))"
        let fileUrl = fileName.asFileNameInDownloadsDirectory

        do {
            try file.write(to: fileUrl, options: [.withoutOverwriting])
            WDLog.log("Successfully wrote file!")
        } catch {
            WDLog.log("Error: Unable to write file with error: \(error)")
            let nsError = error as NSError
            if nsError.domain == NSCocoaErrorDomain, nsError.code == 516 {
                guard !fileUrl.pathExtension.isEmpty else {
                    WDLog.log("Error: Unable to export file: Missing path extension")
                    return
                }

                // File already exists
                let newFileUrl = fileUrl.urlByAppendingRandomUUID
                WDLog.log("File name already in use -> Trying a different name: \(newFileUrl.absoluteString)")
                try? file.write(to: newFileUrl, options: [.withoutOverwriting])
                WDLog.log("Successfully wrote adjusted file!")
            } else {
                WDLog.log("Error: Unable to export file: Unhandled error")
            }
        }
    }

    var transferActions: TransferActions {
        TransferActions(
            onFragmentDelivered: { _, _, _, _ in },
            onFileTransferAccepted: { [weak self] _, _, _ in
                self?.watchdog.stop()
            },
            onFileTransferComplete: { [weak self] _ in
                if self?.transferManager.state.isBulkTransfer == false {
                    self?.watchdog.start()
                }
            },
            onFileReceived: { [weak self] file, fileName, _ in
                self?.export(file: file, fileName: fileName)
            },
            onBulkTransferAccepted: { [weak self] _, _, _ in
                self?.watchdog.stop()
            },
            onBulkTransferComplete: { [weak self] _, _ in
                self?.watchdog.start()
            }
        )
    }

    func watchdogEvent() {
        watchdog.stop()
        transferManager.prepareForNewTransfer()
    }
}

// MARK: Public Methods

extension MacAppManager {
    func terminate() {
        guard !terminated else {
            return
        }

        WDLog.log("Terminate")
        terminated = true
        closeSockets()
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

// MARK: MacAppManager+USBServerDelegate

extension MacAppManager: USBServerDelegate {
    func usbServerDidStartConnection(_: USBServer) {
        WDLog.log("usbServerDidStartConnection:")
    }

    func usbServer(_: USBServer, didEndConnectionWithError _: any Error) {
        WDLog.log("server:didEndConnectionWithError:")
    }

    func usbServer(_: USBServer, gotDataPacket packet: Data) {
        WDLog.log("server:gotDataPacket: size: \(packet.count)")
        transferManager.didReceive(packet: packet)
    }

    func usbServer(_: USBServer, didStartConnectionToClientWith configuration: USBClientConfiguration) {
        WDLog.log("server:didStartConnectionToClientWithConfiguration:")
        transferManager.didConnect()
        remoteConfiguration = configuration
        state.update(connected: true)
        let versionState = ConnectionVersion(
            localVersion: usbServer.configuration.protocolVersion,
            localMinVersion: usbServer.configuration.minSupportedProtocolVersion,
            remoteVersion: configuration.protocolVersion,
            remoteMinVersion: configuration.minSupportedProtocolVersion
        )
        transferManager.didUpdate(versionState: versionState)
    }

    func usbServer(_: USBServer, didEndConnectionToClientWith _: USBClientConfiguration, error _: any Error) {
        WDLog.log("server:didEndConnectionToClientWithError:")
        transferManager.didDisconnect()
        watchdog.stop()
        state.update(connected: false)
        remoteConfiguration = nil
        transferManager.resetParser()
    }
}

// MARK: URL+Filenames

private extension URL {
    static var userDomainDownloadsDirectory: URL {
        guard let path = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first else {
            preconditionFailure("Unable to read path for downloads directory")
        }

        return path
    }

    var urlByAppendingRandomUUID: URL {
        let fileNameLessExt = deletingPathExtension().lastPathComponent
        let newFileName = "\(fileNameLessExt) (\(String(UUID().uuidString.suffix(12)))).\(pathExtension)"
        return newFileName.asFileNameInDownloadsDirectory
    }
}

// MARK: String+DownloadsDirectory

private extension String {
    var asFileNameInDownloadsDirectory: URL {
        URL.userDomainDownloadsDirectory.appendingPathComponent(self)
    }
}
