import CodexBarSync
import Foundation
import Testing
@testable import CodexBarMobile

@Suite("Cost history background persistence")
struct CostHistoryWorkerTests {
    private func snapshot(
        points: [SyncDailyPoint],
        updated: Date) -> SyncedUsageSnapshot
    {
        SyncedUsageSnapshot(
            providers: [ProviderUsageSnapshot(
                providerID: "codex",
                providerName: "Codex",
                primary: nil,
                secondary: nil,
                accountEmail: "history@example.invalid",
                loginMethod: nil,
                statusMessage: nil,
                isError: false,
                lastUpdated: updated,
                costSummary: SyncCostSummary(
                    sessionCostUSD: nil,
                    sessionTokens: nil,
                    last30DaysCostUSD: points.reduce(0) { $0 + $1.costUSD },
                    last30DaysTokens: SyncCounterMath.saturatingSum(points.map(\.totalTokens)),
                    daily: points,
                    bucketTimeZoneIdentifier: "UTC"))],
            syncTimestamp: updated,
            deviceName: "History Mac",
            deviceID: "history-mac")
    }

    @Test
    func `Extreme two Mac counters saturate before token activity and Cost projection`() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let worker = CostHistoryWorker(container: ModelContainerFactory.makeContainer(
            at: directory.appendingPathComponent("Store.sqlite")))
        let now = Date()
        let points = [0, -1].map { offset in
            SyncDailyPoint(
                dayKey: SyncCostSummary.iso8601DayKey(for: now.addingTimeInterval(Double(offset) * 86400)),
                costUSD: 1,
                totalTokens: Int.max,
                modelBreakdowns: [SyncCostBreakdown(
                    label: "Fixture Model", costUSD: 1, standardTokens: Int.max, priorityTokens: Int.max)])
        }
        let original = self.snapshot(points: points, updated: now)
        let other = SyncedUsageSnapshot(
            providers: original.providers,
            syncTimestamp: now,
            deviceName: "Other Fixture Mac",
            deviceID: "other-fixture-mac")
        let sources = [original, other]
        try await worker.persistFull(sources)
        let activity = try await worker.tokenActivity(providers: original.providers, sourceSnapshots: sources)
        #expect(activity.first?.days.count == 2)
        #expect(activity.first?.days.allSatisfy { $0.totalTokens == Int.max } == true)
        let aggregation = try await worker.aggregate(
            windowDays: 365, activeDeviceIDs: nil, sourceSnapshots: sources)
        #expect(aggregation.totalTokens == Int.max)
        #expect(aggregation.sortedProviderRollups.first?.totalTokens == Int.max)
        #expect(aggregation.dailyPoints.first?.modelBreakdowns.first?.standardTokens == Int.max)
        let insights = try await worker.load(.init(
            snapshot: original,
            sourceSnapshots: sources,
            activeDeviceIDs: nil,
            windowDays: 365,
            useLedger: true,
            isDemoMode: false,
            clearTombstone: nil))
        #expect(insights?.total30DayTokens == Int.max)
        #expect(CostDashboardInsights(snapshot: original).total30DayTokens == Int.max)
    }

    @Test
    func `A shorter incoming snapshot does not replace twelve thousand dollars of retained history`() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true)
        let worker = CostHistoryWorker(container: ModelContainerFactory.makeContainer(
            at: directory.appendingPathComponent("Store.sqlite")))
        let now = Date()
        let today = SyncDailyPoint(
            dayKey: SyncCostSummary.iso8601DayKey(for: now),
            costUSD: 10000,
            totalTokens: 1000)
        let earlier = SyncDailyPoint(
            dayKey: SyncCostSummary.iso8601DayKey(for: now.addingTimeInterval(-10 * 86400)),
            costUSD: 2000,
            totalTokens: 200)
        let original = self.snapshot(
            points: [earlier, today],
            updated: now)
        try await worker.persistFull([original])
        let shortened = self.snapshot(
            points: [today],
            updated: now.addingTimeInterval(1))
        try await worker.persistIncremental(
            snapshots: [shortened],
            deletedRecordNames: [],
            replacingAllDevices: false,
            zoneName: "test-zone",
            tokenData: Data([1]))
        let insights = try await worker.load(.init(
            snapshot: shortened,
            sourceSnapshots: [shortened],
            activeDeviceIDs: ["history-mac"],
            windowDays: 365,
            useLedger: true,
            isDemoMode: false,
            clearTombstone: nil))
        #expect(insights?.total30DayCost == 12000)
        let tokens = try await worker.tokenActivity(
            providers: shortened.providers,
            sourceSnapshots: [shortened],
            referenceDate: now)
        #expect(tokens.first?.days.reduce(0) { $0 + $1.totalTokens } == 1200)
        let withoutSources = try await worker.tokenActivity(
            providers: shortened.providers,
            sourceSnapshots: [],
            referenceDate: now)
        #expect(withoutSources.first?.days.reduce(0) { $0 + $1.totalTokens } == 1200)
        #expect(try await worker.loadToken(zoneName: "test-zone") == Data([1]))
    }

    @Test
    func `Cancelled queued history reads leave persisted history intact`() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true)
        let worker = CostHistoryWorker(container: ModelContainerFactory.makeContainer(
            at: directory.appendingPathComponent("Store.sqlite")))
        let now = Date()
        let original = self.snapshot(
            points: [.init(
                dayKey: SyncCostSummary.iso8601DayKey(for: now),
                costUSD: 12000,
                totalTokens: 1000)],
            updated: now)
        try await worker.persistFull([original])
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await worker.load(.init(
                snapshot: original,
                sourceSnapshots: [original],
                activeDeviceIDs: nil,
                windowDays: 365,
                useLedger: true,
                isDemoMode: false,
                clearTombstone: nil))
        }
        do {
            _ = try await task.value
            Issue.record("Cancelled load unexpectedly returned a presentation")
        } catch is CancellationError {}
        let diagnostics = try await worker.diagnostics(seed: false)
        #expect(diagnostics.rowCount == 1)
    }
}
