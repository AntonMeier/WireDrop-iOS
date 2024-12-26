//
//  TransferManager.swift
//  WireDrop
//
//  Created by Anton Meier on 2024-12-16.
//

// MARK: Initialization

final class TransferManager: NSObject {
    let state: TransferManagerState

    private let transferActions: TransferActions
    private var connection: USBConnection
    private lazy var dataParser = DataParser(delegate: self, clientType: state.localClientType.clientParserType, connection: connection)

    init(state: TransferManagerState, connection: USBConnection, transferActions: TransferActions) {
        self.state = state
        self.connection = connection
        self.transferActions = transferActions
    }
}

// MARK: Public Methods

extension TransferManager {
    func sendFiles(attachments: [NSItemProvider], force: Bool = false, files: Int, fileNo: Int = 0, completion: @escaping (Bool) -> Void) {
        guard state.isTransferAllowed || force, let provider = attachments.first else {
            WDLog.log("Error: Cannot start transfer of files")
            return
        }

        provider.loadItem(forTypeIdentifier: "public.content") { [self] data, _ in
            guard let url = data as? URL, let fileData = try? Data(contentsOf: url, options: .alwaysMapped) else {
                WDLog.log("Error: Unable to load file data")
                return
            }

            let filename = url.lastPathComponent
            WDLog.log("Data read successful - sending count: \(fileData.count)")
            DispatchQueue.main.async {
                let attachments = attachments
                self.sendData(fileData, fileNo: fileNo, files: attachments.count, filename: filename) {
                    guard attachments.count > 1 else {
                        completion(true)
                        return
                    }

                    let remaining = Array(attachments.suffix(from: 1))
                    self.sendFiles(attachments: remaining, force: true, files: files, fileNo: fileNo + 1, completion: completion)
                }
            }
        }
    }

    func startBulkTransfer(with attachments: [NSItemProvider], files: Int, fileNo _: Int = 0) {
        guard state.isTransferAllowed else {
            WDLog.log("Error: Transfer not allowed")
            return
        }

        requestBulkTransfer(files: files) { [self] success in
            WDLog.log("Bulk transfer started with success: \(success)")
            guard success else {
                return
            }

            self.sendFiles(attachments: attachments, files: attachments.count) { _ in
                WDLog.log("\(files) files completed, ending bulk tranfer...")
                self.endBulkTransfer(files: files) {
                    WDLog.log("Bulk transfer ended with success: \($0)")
                }
            }
        }
    }

    func didConnect() {
        dataParser.isUSBConnected = true
        resetTransferStates()
    }

    func didDisconnect() {
        dataParser.isUSBConnected = false
        dataParser.versionState = nil
        resetTransferStates()
        resetProgress()
    }

    func shareSheetDidComplete() {
        resetTransferStates()
        resetProgress()
    }

    func didReceive(packet: Data) {
        dataParser.didReceive(packet)
    }

    func didUpdate(versionState: ConnectionVersion) {
        dataParser.versionState = versionState
    }

    func resetParser() {
        dataParser = DataParser(delegate: self, clientType: state.localClientType.clientParserType, connection: connection)
    }

    func prepareForNewTransfer() {
        resetTransferStates()
    }
}

// MARK: Private Methods

private extension TransferManager {
    func sendData(_ data: Data, fileNo: Int, files: Int, filename: String, completion: @escaping (() -> Void)) {
        state.fileTransferState = .waiting
        dataParser.sendFile(data, fileNo: Int32(fileNo), total: Int32(files), filename: filename) { _ in
            DispatchQueue.main.async {
                completion()
            }
        }
    }

    func requestBulkTransfer(files: Int, completion: @escaping ((Bool) -> Void)) {
        state.bulkTransferState = .waiting
        dataParser.startBulkTransfer(withTotal: Int32(files)) { error in
            DispatchQueue.main.async {
                completion(error == 0)
            }
        }
    }

    func endBulkTransfer(files _: Int, completion: @escaping ((Bool) -> Void)) {
        dataParser.endBulkTransfer { error in
            DispatchQueue.main.async {
                completion(error == 0)
            }
        }
    }

    func resetTransferStates() {
        state.fileTransferState = .none
        state.bulkTransferState = .none
    }

    func resetProgress() {
        state.fileProgress = 0.0
        state.bulkProgress = 0.0
    }

    func makeProgressCalculations(fileNo: Int32, totalFiles: Int32, fragmentNo: Int32, totalFragments: Int32) {
        let progress = Double(fragmentNo) / Double(totalFragments)
        let fileNo = Double(fileNo)
        let totalFiles = Double(totalFiles)
        state.fileProgress = progress
        state.bulkProgress = (fileNo / totalFiles) + (progress / totalFiles)
        WDLog.log("Fragment: \(fragmentNo) / \(totalFragments), progress: \(progress) : \(state.bulkProgress), file: \(fileNo) / \(totalFiles)")
    }
}

// MARK: TransferManager+WDDataParserDelegate

extension TransferManager: WDDataParserDelegate {
    func parser(_: DataParser, receivedFile file: Data, filename: String?) {
        WDLog.log("Did receive file with name: \(filename ?? ""), count: \(file.count)")
        let isBulkTransfer = state.bulkTransferState != .none
        DispatchQueue.main.async { [transferActions] in
            transferActions.onFileReceived(file, filename, isBulkTransfer)
        }
    }

    func parser(_ parser: DataParser, didReceiveFragment fragment: Int32, total: Int32) {
        let fileNo = parser.currentFileNo()
        let totalFiles = parser.totalFilesToTransfer()
        makeProgressCalculations(fileNo: fileNo, totalFiles: totalFiles, fragmentNo: fragment, totalFragments: total)
        DispatchQueue.main.async { [transferActions] in
            transferActions.onFragmentDelivered(fragment, fileNo, total, totalFiles)
        }
    }

    func parser(_ parser: DataParser, didSendFragment fragment: Int32, total: Int32) {
        // Progress calculations are handled the same on both sender on receiver.
        self.parser(parser, didReceiveFragment: fragment, total: total)
    }

    func parser(_: DataParser, fileTransferWasAccepted fileId: Int32, fileNo: Int32, total: Int32) {
        WDLog.log("File transfer was accepted for fileId: \(fileId), fileNo: \(fileNo), total: \(total)")
        state.fileTransferState = .sending
        if fileNo == 0, total == 1 {
            resetProgress()
        }
        DispatchQueue.main.async { [transferActions] in
            transferActions.onFileTransferAccepted(fileId, fileNo, total)
        }
    }

    func parser(_: DataParser, fileTransferWasCompleted fileId: Int32) {
        WDLog.log("File transfer was completed for fileId: \(fileId)")
        state.fileTransferState = .complete
        DispatchQueue.main.async { [transferActions] in
            transferActions.onFileTransferComplete(fileId)
        }
    }

    func parser(_: DataParser, bulkTransferWasAccepted accepted: Bool, bulkId: Int32, total: Int32) {
        WDLog.log("Bulk transfer was accepted: \(accepted), bulkId: \(bulkId), total: \(total)")
        state.bulkTransferState = accepted ? .sending : .failed
        resetProgress()
        DispatchQueue.main.async { [transferActions] in
            transferActions.onBulkTransferAccepted(accepted, bulkId, total)
        }
    }

    func parser(_: DataParser, bulkTransferEndedWithSuccess success: Bool, bulkId: Int32) {
        WDLog.log("Bulk transfer ended with success: \(success), bulkId: \(bulkId)")
        state.bulkTransferState = success ? .complete : .failed
        DispatchQueue.main.async { [transferActions] in
            transferActions.onBulkTransferComplete(success, bulkId)
        }
    }
}
