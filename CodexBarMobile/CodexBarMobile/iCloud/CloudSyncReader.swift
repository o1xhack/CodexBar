import CodexBarSync
import Foundation

/// iOS-side wrapper around `CloudSyncManager` that provides a convenient observation interface.
///
/// Encapsulates the details of iCloud KVS observation and exposes a simple callback-based API
/// for the ViewModel layer.
final class CloudSyncReader: @unchecked Sendable {
    private let syncManager: CloudSyncManager

    init(syncManager: CloudSyncManager = .shared) {
        self.syncManager = syncManager
    }

    /// Returns the most recently synced snapshot, or `nil` if no data has been synced yet.
    func latestSnapshot() -> SyncedUsageSnapshot? {
        syncManager.fetchSnapshot()
    }

    /// Starts observing iCloud changes. The handler is called on the main actor
    /// whenever data changes externally (i.e., when the Mac pushes a new snapshot).
    func startObserving(handler: @escaping @MainActor (SyncedUsageSnapshot?) -> Void) {
        syncManager.startObserving(handler: handler)
    }

    func stopObserving() {
        syncManager.stopObserving()
    }
}
