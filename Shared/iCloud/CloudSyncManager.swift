import Foundation

/// Protocol for pushing usage snapshots, enabling mock injection in tests.
public protocol SyncPushing: Sendable {
    @discardableResult
    func pushSnapshot(_ snapshot: SyncedUsageSnapshot) -> Bool
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

    /// Starts observing remote iCloud KVS changes.
    /// The handler is called on the main queue whenever the snapshot changes externally.
    public func startObserving(handler: @escaping @MainActor (SyncedUsageSnapshot?) -> Void) {
        NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: store,
            queue: .main)
        { [weak self] _ in
            let snapshot = self?.fetchSnapshot()
            Task { @MainActor in
                handler(snapshot)
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
}
