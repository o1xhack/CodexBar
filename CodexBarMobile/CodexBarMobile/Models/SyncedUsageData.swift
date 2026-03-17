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
        reader.startObserving { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let newSnapshot):
                self.snapshot = newSnapshot
                self.lastSyncError = nil
            case .empty:
                // No data yet, not necessarily an error
                break
            case .quotaExceeded:
                self.lastSyncError = String(localized: "iCloud storage quota exceeded")
            case .accountChanged:
                self.lastSyncError = String(localized: "iCloud account changed")
                // Try to reload with new account
                self.snapshot = self.reader.latestSnapshot()
            case .initialSync:
                // Initial sync in progress, data may arrive soon
                self.lastSyncError = nil
            }
        }
    }

    /// Force-reads the latest snapshot from iCloud.
    func refresh() {
        let syncAttempted = self.reader.synchronize()
        self.snapshot = self.reader.latestSnapshot()
        if self.snapshot != nil {
            self.lastSyncError = nil
        } else if !syncAttempted {
            self.lastSyncError = String(localized: "iCloud sync unavailable")
        }
    }

    /// Returns the age of the last sync in a human-readable format, or nil if no sync exists.
    var syncAge: String? {
        guard let timestamp = snapshot?.syncTimestamp else { return nil }
        let interval = Date().timeIntervalSince(timestamp)
        if interval < 60 {
            return String(localized: "Just now")
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes.formatted()) \(String(localized: "min ago"))"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours.formatted())\(String(localized: "h ago"))"
        } else {
            let days = Int(interval / 86400)
            return "\(days.formatted())\(String(localized: "d ago"))"
        }
    }
}
