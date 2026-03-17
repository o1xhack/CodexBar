import Foundation
#if canImport(OSLog)
import OSLog
#endif
#if canImport(Security)
import Security
#endif

/// Protocol for pushing usage snapshots, enabling mock injection in tests.
public protocol SyncPushing: Sendable {
    @discardableResult
    func pushSnapshot(_ snapshot: SyncedUsageSnapshot) -> SyncPushResult
}

public struct SyncPushResult: Sendable, Equatable {
    public let succeeded: Bool
    public let message: String?

    public init(succeeded: Bool, message: String? = nil) {
        self.succeeded = succeeded
        self.message = message
    }

    public static let success = SyncPushResult(succeeded: true)

    public static func failure(_ message: String) -> SyncPushResult {
        SyncPushResult(succeeded: false, message: message)
    }
}

/// Result of an iCloud KVS sync event.
public enum SyncResult: Sendable {
    /// Successfully received a new snapshot.
    case success(SyncedUsageSnapshot)
    /// Remote change arrived but no snapshot data found (possibly deleted).
    case empty
    /// iCloud KVS quota exceeded — data was not saved.
    case quotaExceeded
    /// A local change conflicted with a server change.
    case accountChanged
    /// Initial download from iCloud is in progress.
    case initialSync
}

/// Manages reading/writing usage snapshots to NSUbiquitousKeyValueStore for iCloud sync.
///
/// - Mac side calls `pushSnapshot(_:)` after each refresh.
/// - iOS side calls `startObserving(handler:)` to receive updates.
public final class CloudSyncManager: SyncPushing, @unchecked Sendable {
    public static let shared = CloudSyncManager()

    private let store = NSUbiquitousKeyValueStore.default
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private var observerToken: NSObjectProtocol?

    #if canImport(OSLog)
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.o1xhack.codexbar",
        category: "icloud-sync")
    #endif

    private init() {
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    // MARK: - Write (Mac side)

    /// Pushes the latest usage snapshot to iCloud KVS.
    /// Returns `true` if the write succeeded.
    @discardableResult
    public func pushSnapshot(_ snapshot: SyncedUsageSnapshot) -> SyncPushResult {
        if !self.hasUbiquityKVStoreEntitlement() {
            let message = "iCloud sync unavailable: app is missing the ubiquity KVS entitlement."
            self.logError(message)
            return .failure(message)
        }
        if FileManager.default.ubiquityIdentityToken == nil {
            let message = "iCloud sync unavailable: no iCloud account is active for this app."
            self.logError(message)
            return .failure(message)
        }
        guard let data = try? encoder.encode(snapshot) else {
            let message = "iCloud sync failed: could not encode the snapshot payload."
            self.logError(message)
            return .failure(message)
        }
        guard data.count <= CloudSyncConstants.maxPayloadBytes else {
            let message = "iCloud sync failed: snapshot exceeds the iCloud Key-Value Store size limit."
            self.logError(message)
            return .failure(message)
        }
        store.set(data, forKey: CloudSyncConstants.snapshotKey)
        guard store.synchronize() else {
            let message = "iCloud sync failed: Key-Value Store synchronize() returned unavailable."
            self.logError(message)
            return .failure(message)
        }
        self.logInfo("Pushed usage snapshot to iCloud", metadata: [
            "providers": "\(snapshot.providers.count)",
            "bytes": "\(data.count)",
        ])
        return .success
    }

    // MARK: - Read (iOS side)

    /// Fetches the latest snapshot from iCloud KVS, if available.
    public func fetchSnapshot() -> SyncedUsageSnapshot? {
        guard let data = store.data(forKey: CloudSyncConstants.snapshotKey) else { return nil }
        return try? decoder.decode(SyncedUsageSnapshot.self, from: data)
    }

    @discardableResult
    public func synchronizeStore() -> Bool {
        let result = store.synchronize()
        if !result {
            self.logError("iCloud Key-Value Store synchronize() returned unavailable")
        }
        return result
    }

    /// Starts observing remote iCloud KVS changes with detailed result.
    /// The handler is called on the main queue whenever the snapshot changes externally.
    public func startObserving(handler: @escaping @MainActor (SyncResult) -> Void) {
        self.stopObserving()
        self.observerToken = NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: store,
            queue: .main)
        { [weak self] notification in
            let result = self?.parseSyncResult(from: notification) ?? .empty
            Task { @MainActor in
                handler(result)
            }
        }
        // Trigger initial sync
        _ = self.synchronizeStore()
    }

    /// Stops observing remote changes.
    public func stopObserving() {
        guard let observerToken else { return }
        NotificationCenter.default.removeObserver(observerToken)
        self.observerToken = nil
    }

    // MARK: - Private

    private func parseSyncResult(from notification: Notification) -> SyncResult {
        let reason = notification.userInfo?[NSUbiquitousKeyValueStoreChangeReasonKey] as? Int

        switch reason {
        case NSUbiquitousKeyValueStoreQuotaViolationChange:
            return .quotaExceeded
        case NSUbiquitousKeyValueStoreAccountChange:
            // Account changed — re-fetch in case data is now different
            if let snapshot = fetchSnapshot() {
                return .success(snapshot)
            }
            return .accountChanged
        case NSUbiquitousKeyValueStoreInitialSyncChange:
            // Initial download completed — try to read data
            if let snapshot = fetchSnapshot() {
                return .success(snapshot)
            }
            return .initialSync
        default:
            // NSUbiquitousKeyValueStoreServerChange or unknown
            if let snapshot = fetchSnapshot() {
                return .success(snapshot)
            }
            return .empty
        }
    }

    private func hasUbiquityKVStoreEntitlement() -> Bool {
        #if canImport(Security) && os(macOS)
        guard let task = SecTaskCreateFromSelf(nil) else { return true }
        let value = SecTaskCopyValueForEntitlement(
            task,
            "com.apple.developer.ubiquity-kvstore-identifier" as CFString,
            nil)
        return value != nil
        #else
        return true
        #endif
    }

    private func logInfo(_ message: String, metadata: [String: String]? = nil) {
        #if canImport(OSLog)
        if let metadata, !metadata.isEmpty {
            let rendered = metadata
                .sorted(by: { $0.key < $1.key })
                .map { "\($0.key)=\($0.value)" }
                .joined(separator: " ")
            logger.info("\(message, privacy: .public) \(rendered, privacy: .public)")
        } else {
            logger.info("\(message, privacy: .public)")
        }
        #endif
    }

    private func logError(_ message: String) {
        #if canImport(OSLog)
        logger.error("\(message, privacy: .public)")
        #endif
    }
}
