import CodexBarSync
import Foundation
import Observation

/// ViewModel for the iOS app. Observes iCloud sync changes and exposes
/// the latest `SyncedUsageSnapshot` to SwiftUI views.
@Observable
@MainActor
final class SyncedUsageData {
    var snapshot: SyncedUsageSnapshot?
    var lastSyncError: String?

    private let reader: CloudSyncReader

    init(reader: CloudSyncReader = CloudSyncReader()) {
        self.reader = reader
        // Load any existing snapshot immediately
        self.snapshot = reader.latestSnapshot()
    }

    /// Starts observing iCloud KVS changes.
    func startObserving() {
        reader.startObserving { [weak self] newSnapshot in
            guard let self else { return }
            if let newSnapshot {
                self.snapshot = newSnapshot
                self.lastSyncError = nil
            }
        }
    }

    /// Force-reads the latest snapshot from iCloud.
    func refresh() {
        snapshot = reader.latestSnapshot()
    }

    /// Returns the age of the last sync in a human-readable format, or nil if no sync exists.
    var syncAge: String? {
        guard let timestamp = snapshot?.syncTimestamp else { return nil }
        let interval = Date().timeIntervalSince(timestamp)
        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes) min ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days)d ago"
        }
    }
}
