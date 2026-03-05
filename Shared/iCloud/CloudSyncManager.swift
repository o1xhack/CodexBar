import Foundation

/// Protocol for pushing usage snapshots, enabling mock injection in tests.
public protocol SyncPushing: Sendable {
    @discardableResult
    func pushSnapshot(_ snapshot: SyncedUsageSnapshot) -> Bool
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

    private init() {
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    // MARK: - Write (Mac side)

    /// Pushes the latest usage snapshot to iCloud KVS.
    /// Returns `true` if the write succeeded.
    @discardableResult
    public func pushSnapshot(_ snapshot: SyncedUsageSnapshot) -> Bool {
        guard let data = try? encoder.encode(snapshot) else { return false }
        guard data.count <= CloudSyncConstants.maxPayloadBytes else { return false }
        store.set(data, forKey: CloudSyncConstants.snapshotKey)
        store.synchronize()
        return true
    }

    // MARK: - Read (iOS side)

    /// Fetches the latest snapshot from iCloud KVS, if available.
    public func fetchSnapshot() -> SyncedUsageSnapshot? {
        guard let data = store.data(forKey: CloudSyncConstants.snapshotKey) else { return nil }
        return try? decoder.decode(SyncedUsageSnapshot.self, from: data)
    }

    /// Starts observing remote iCloud KVS changes with detailed result.
    /// The handler is called on the main queue whenever the snapshot changes externally.
    public func startObserving(handler: @escaping @MainActor (SyncResult) -> Void) {
        NotificationCenter.default.addObserver(
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
        store.synchronize()
    }

    /// Stops observing remote changes.
    public func stopObserving() {
        NotificationCenter.default.removeObserver(
            self,
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: store)
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
}
