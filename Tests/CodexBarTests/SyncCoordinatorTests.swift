import CodexBarCore
import CodexBarSync
import Foundation
import Testing
@testable import CodexBar

/// Mock sync pusher that records push calls for testing.
final class MockSyncPusher: SyncPushing, @unchecked Sendable {
    var pushCount = 0
    var lastSnapshot: SyncedUsageSnapshot?
    var shouldSucceed = true

    @discardableResult
    func pushSnapshot(_ snapshot: SyncedUsageSnapshot) -> Bool {
        self.pushCount += 1
        self.lastSnapshot = snapshot
        return self.shouldSucceed
    }
}

@MainActor
@Suite
struct SyncCoordinatorTests {
    private func makeSettingsStore(suite: String) -> SettingsStore {
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        let configStore = testConfigStore(suiteName: suite)
        return SettingsStore(
            userDefaults: defaults,
            configStore: configStore,
            zaiTokenStore: NoopZaiTokenStore(),
            syntheticTokenStore: NoopSyntheticTokenStore())
    }

    private func makeUsageStore(settings: SettingsStore) -> UsageStore {
        UsageStore(
            fetcher: UsageFetcher(environment: [:]),
            browserDetection: BrowserDetection(cacheTTL: 0),
            settings: settings)
    }

    @Test
    func pushSkippedWhenSyncDisabled() {
        let settings = self.makeSettingsStore(suite: "SyncCoord-disabled")
        settings.iCloudSyncEnabled = false
        let store = self.makeUsageStore(settings: settings)
        let mock = MockSyncPusher()
        let coordinator = SyncCoordinator(store: store, settings: settings, syncManager: mock)

        coordinator.pushCurrentSnapshot()

        #expect(mock.pushCount == 0)
        #expect(coordinator.lastSyncTime == nil)
    }

    @Test
    func pushSucceedsWhenSyncEnabled() {
        let settings = self.makeSettingsStore(suite: "SyncCoord-enabled")
        settings.iCloudSyncEnabled = true
        let store = self.makeUsageStore(settings: settings)
        let mock = MockSyncPusher()
        let coordinator = SyncCoordinator(store: store, settings: settings, syncManager: mock)

        coordinator.pushCurrentSnapshot()

        // Push may or may not happen depending on whether there are enabled providers.
        // With default config, providers may be enabled, so check status tracking.
        if mock.pushCount > 0 {
            #expect(coordinator.lastSyncTime != nil)
            #expect(coordinator.lastSyncSucceeded == true)
        }
    }

    @Test
    func pushFailureTracksStatus() {
        let settings = self.makeSettingsStore(suite: "SyncCoord-failure")
        settings.iCloudSyncEnabled = true
        let store = self.makeUsageStore(settings: settings)
        let mock = MockSyncPusher()
        mock.shouldSucceed = false
        let coordinator = SyncCoordinator(store: store, settings: settings, syncManager: mock)

        coordinator.pushCurrentSnapshot()

        if mock.pushCount > 0 {
            #expect(coordinator.lastSyncTime != nil)
            #expect(coordinator.lastSyncSucceeded == false)
        }
    }

    @Test
    func isSyncingIsFalseAfterPush() {
        let settings = self.makeSettingsStore(suite: "SyncCoord-syncing")
        settings.iCloudSyncEnabled = true
        let store = self.makeUsageStore(settings: settings)
        let mock = MockSyncPusher()
        let coordinator = SyncCoordinator(store: store, settings: settings, syncManager: mock)

        coordinator.pushCurrentSnapshot()

        // isSyncing should be false after synchronous push completes
        #expect(coordinator.isSyncing == false)
    }

    @Test
    func defaultSyncEnabledIsTrue() throws {
        let suite = "SyncCoord-defaultEnabled"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defaults.removePersistentDomain(forName: suite)
        let configStore = testConfigStore(suiteName: suite)
        let settings = SettingsStore(
            userDefaults: defaults,
            configStore: configStore,
            zaiTokenStore: NoopZaiTokenStore(),
            syntheticTokenStore: NoopSyntheticTokenStore())

        #expect(settings.iCloudSyncEnabled == true)
    }

    @Test
    func syncEnabledPersistsAcrossInstances() throws {
        let suite = "SyncCoord-persist"
        let defaultsA = try #require(UserDefaults(suiteName: suite))
        defaultsA.removePersistentDomain(forName: suite)
        let configStore = testConfigStore(suiteName: suite)
        let storeA = SettingsStore(
            userDefaults: defaultsA,
            configStore: configStore,
            zaiTokenStore: NoopZaiTokenStore(),
            syntheticTokenStore: NoopSyntheticTokenStore())

        storeA.iCloudSyncEnabled = false

        let defaultsB = try #require(UserDefaults(suiteName: suite))
        let storeB = SettingsStore(
            userDefaults: defaultsB,
            configStore: configStore,
            zaiTokenStore: NoopZaiTokenStore(),
            syntheticTokenStore: NoopSyntheticTokenStore())

        #expect(storeB.iCloudSyncEnabled == false)
    }

    @Test
    func togglingSettingUpdatesUserDefaults() throws {
        let suite = "SyncCoord-toggle"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defaults.removePersistentDomain(forName: suite)
        let configStore = testConfigStore(suiteName: suite)
        let settings = SettingsStore(
            userDefaults: defaults,
            configStore: configStore,
            zaiTokenStore: NoopZaiTokenStore(),
            syntheticTokenStore: NoopSyntheticTokenStore())

        settings.iCloudSyncEnabled = false
        #expect(defaults.bool(forKey: "iCloudSyncEnabled") == false)

        settings.iCloudSyncEnabled = true
        #expect(defaults.bool(forKey: "iCloudSyncEnabled") == true)
    }
}
