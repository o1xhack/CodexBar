import Foundation
import Testing
@testable import CodexBar
@testable import CodexBarCore
@testable import CodexBarSync

@MainActor
struct SyncCoordinatorV058MapperTests {
    @Test
    func `Moonshot upstream CNY and USD formatting preserves grouped zero and negative balances`() throws {
        for region in [MoonshotRegion.china, .international] {
            for balance in [1234.5, 0, -12.5] {
                let source = MoonshotUsageSummary(
                    availableBalance: balance,
                    voucherBalance: 0,
                    cashBalance: balance,
                    updatedAt: Date(timeIntervalSince1970: 100),
                    region: region).toUsageSnapshot()
                let mapped = try #require(SyncCoordinator.mapMoonshotBalance(
                    provider: .moonshot,
                    snapshot: source,
                    primaryWindow: nil))
                #expect(mapped.balanceAmount == balance)
                #expect(mapped.balanceCurrency == (region == .china ? "CNY" : "USD"))
            }
        }
    }

    @Test
    func `credits-only refresh publishes and clears the active purchased balance`() async throws {
        let suite = "SyncCoord-v058-credits-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let settings = SettingsStore(
            userDefaults: defaults,
            configStore: testConfigStore(suiteName: suite),
            zaiTokenStore: NoopZaiTokenStore(),
            syntheticTokenStore: NoopSyntheticTokenStore())
        settings.iCloudSyncEnabled = true
        try settings.setProviderEnabled(
            provider: .codex,
            metadata: #require(ProviderDefaults.metadata[.codex]),
            enabled: true)
        let store = UsageStore(
            fetcher: UsageFetcher(environment: [:]),
            browserDetection: BrowserDetection(cacheTTL: 0),
            settings: settings)
        store.snapshots[.codex] = UsageSnapshot(
            primary: RateWindow(
                usedPercent: 10,
                windowMinutes: 300,
                resetsAt: nil,
                resetDescription: nil),
            secondary: nil,
            updatedAt: Date(timeIntervalSince1970: 100))
        let pusher = V058RecordingPusher()
        let coordinator = SyncCoordinator(
            store: store,
            settings: settings,
            syncManager: pusher)
        coordinator.startObserving()
        defer { coordinator.stopObserving() }
        for balance in [25.0, 0.0] {
            store.credits = CreditsSnapshot(
                remaining: balance,
                events: [],
                updatedAt: Date(timeIntervalSince1970: 200 + 25 - balance))
            let deadline = ContinuousClock.now.advanced(by: .seconds(5))
            while await pusher.amount() != balance, ContinuousClock.now < deadline {
                try await Task.sleep(for: .milliseconds(10))
            }
            #expect(await pusher.amount() == balance)
        }
    }

    @Test
    func `Codex purchased balance keeps its own observation time and confirmed zero`() throws {
        let old = Date(timeIntervalSince1970: 100)
        let recent = Date(timeIntervalSince1970: 200)
        for balance: Double? in [25, nil] {
            let cost = ProviderCostSnapshot(
                used: 10,
                limit: 100,
                currencyCode: "Credits",
                period: "Monthly credit limit",
                balance: balance,
                balanceUpdatedAt: recent,
                updatedAt: old)
            let amount = try #require(SyncCoordinator.mapProviderAmount(
                provider: .codex,
                snapshot: nil,
                providerCost: cost))
            #expect(amount.amount == balance ?? 0)
            #expect(amount.observedAt == recent)
            #expect(amount.currencyCode == "Credits")
        }
    }

    @Test
    func `Codex cap alone does not invent a purchased balance observation`() {
        let cost = ProviderCostSnapshot(
            used: 10,
            limit: 100,
            currencyCode: "Credits",
            period: "Monthly credit limit",
            updatedAt: Date(timeIntervalSince1970: 100))
        #expect(SyncCoordinator.mapProviderAmount(
            provider: .codex,
            snapshot: nil,
            providerCost: cost) == nil)
    }

    @Test
    func `legacy amount decodes without new freshness metadata`() throws {
        let payload = Data(#"{"kind":"balance","amount":12,"currencyCode":"USD","isEstimated":false}"#.utf8)
        let amount = try JSONDecoder().decode(
            SyncProviderAmount.self,
            from: payload)
        #expect(amount.amount == 12)
        #expect(amount.observedAt == nil)
    }
}

private actor V058RecordingPusher: SyncPushing {
    private var latest: SyncedUsageSnapshot?

    func pushSnapshot(_ snapshot: SyncedUsageSnapshot) async -> SyncPushResult {
        self.latest = snapshot
        return .success
    }

    func amount() -> Double? {
        self.latest?.providers.first { $0.providerID == "codex" }?.providerAmount?.amount
    }
}
