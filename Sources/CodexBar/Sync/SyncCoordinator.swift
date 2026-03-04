import CodexBarCore
import CodexBarSync
import Foundation
import Observation

/// Observes `UsageStore` changes and pushes usage snapshots to iCloud via `CloudSyncManager`.
///
/// This class bridges the existing Mac app data to the shared iCloud layer without
/// modifying any existing source files. It uses Swift Observation to track `UsageStore.snapshots`.
@MainActor
@Observable
final class SyncCoordinator {
    private let store: UsageStore
    private let settings: SettingsStore
    private let syncManager: any SyncPushing
    private var isObserving = false

    // Observable sync status for UI
    private(set) var lastSyncTime: Date?
    private(set) var lastSyncSucceeded: Bool = true
    private(set) var isSyncing: Bool = false

    init(store: UsageStore, settings: SettingsStore, syncManager: any SyncPushing = CloudSyncManager.shared) {
        self.store = store
        self.settings = settings
        self.syncManager = syncManager
    }

    /// Starts observing `UsageStore` snapshot changes.
    /// Each time the snapshots dictionary changes, a new `SyncedUsageSnapshot` is pushed to iCloud.
    func startObserving() {
        guard !self.isObserving else { return }
        self.isObserving = true
        self.observeLoop()
    }

    private func observeLoop() {
        withObservationTracking {
            _ = self.store.snapshots
            _ = self.store.errors
            _ = self.settings.iCloudSyncEnabled
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                guard let self, self.isObserving else { return }
                self.pushCurrentSnapshot()
                self.observeLoop()
            }
        }
    }

    /// Builds and pushes the current state to iCloud.
    func pushCurrentSnapshot() {
        guard self.settings.iCloudSyncEnabled else { return }

        let enabledProviders = self.store.enabledProviders()
        guard !enabledProviders.isEmpty else { return }

        self.isSyncing = true
        defer { self.isSyncing = false }

        var providerSnapshots: [ProviderUsageSnapshot] = []

        for provider in enabledProviders {
            let snapshot = self.store.snapshots[provider]
            let error = self.store.errors[provider]
            let meta = self.store.providerMetadata[provider]

            let primaryWindow: SyncRateWindow? = snapshot?.primary.map {
                SyncRateWindow(
                    usedPercent: $0.usedPercent,
                    windowMinutes: $0.windowMinutes,
                    resetsAt: $0.resetsAt,
                    resetDescription: $0.resetDescription)
            }

            let secondaryWindow: SyncRateWindow? = snapshot?.secondary.map {
                SyncRateWindow(
                    usedPercent: $0.usedPercent,
                    windowMinutes: $0.windowMinutes,
                    resetsAt: $0.resetsAt,
                    resetDescription: $0.resetDescription)
            }

            let providerSnapshot = ProviderUsageSnapshot(
                providerID: provider.rawValue,
                providerName: meta?.displayName ?? provider.rawValue.capitalized,
                primary: primaryWindow,
                secondary: secondaryWindow,
                accountEmail: snapshot?.identity?.accountEmail,
                loginMethod: snapshot?.identity?.loginMethod,
                statusMessage: error,
                isError: error != nil,
                lastUpdated: snapshot?.updatedAt ?? Date())

            providerSnapshots.append(providerSnapshot)
        }

        let deviceName = Host.current().localizedName ?? "Mac"
        let synced = SyncedUsageSnapshot(
            providers: providerSnapshots,
            syncTimestamp: Date(),
            deviceName: deviceName)

        let success = self.syncManager.pushSnapshot(synced)
        self.lastSyncTime = Date()
        self.lastSyncSucceeded = success
    }

    func stopObserving() {
        self.isObserving = false
    }
}
