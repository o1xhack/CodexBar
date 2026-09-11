import CodexBarSync
import Foundation
import SwiftData
import Testing
@testable import CodexBarMobile

@Suite("Token Activity data semantics")
struct TokenActivityTests {
    @Test func `Catch up publications invalidate token history even when usage and device timestamps stay fixed`() {
        let now = Date(timeIntervalSince1970: 1_789_084_800)
        let provider = ProviderUsageSnapshot(
            providerID: "codex",
            providerName: "Codex",
            primary: nil,
            secondary: nil,
            accountEmail: nil,
            loginMethod: nil,
            statusMessage: nil,
            isError: false,
            lastUpdated: now)
        func snapshot(publication: Date) -> SyncedUsageSnapshot {
            SyncedUsageSnapshot(
                providers: [provider],
                syncTimestamp: now,
                deviceName: "Fixture Mac",
                deviceID: "fixture-mac",
                providerPublicationTimestamps: [SyncedUsageSnapshot.providerPublicationKey(for: provider): publication])
        }
        let old = snapshot(publication: now)
        let catchUp = snapshot(publication: now.addingTimeInterval(60))
        #expect(old.syncTimestamp == catchUp.syncTimestamp)
        #expect(old.providers.first?.lastUpdated == catchUp.providers.first?.lastUpdated)
        #expect(TokenActivity.sourceRevision([old]) != TokenActivity.sourceRevision([catchUp]))
        #expect(TokenActivity.sourceRevision([old, catchUp]) == TokenActivity.sourceRevision([catchUp, old]))
    }

    @Test func `Extreme synced counters do not overflow daily token combination`() {
        let points = TokenActivity.combine([
            SyncDailyPoint(dayKey: "2026-09-10", costUSD: 0, totalTokens: Int.max),
            SyncDailyPoint(dayKey: "2026-09-10", costUSD: 0, totalTokens: 1),
        ])
        #expect(points.first?.totalTokens == Int.max)
    }

    @Test func `Confirmed zero token history keeps the Cost entry point reachable without the ledger`() throws {
        let now = Date()
        let provider = ProviderUsageSnapshot(
            providerID: "codex",
            providerName: "Codex",
            primary: nil,
            secondary: nil,
            accountEmail: nil,
            loginMethod: nil,
            statusMessage: nil,
            isError: false,
            lastUpdated: now,
            costSummary: SyncCostSummary(
                sessionCostUSD: nil,
                sessionTokens: nil,
                last30DaysCostUSD: nil,
                last30DaysTokens: nil,
                daily: [SyncDailyPoint(
                    dayKey: TokenActivity.dayKey(now, calendar: Calendar(identifier: .gregorian)),
                    costUSD: 0,
                    totalTokens: 0,
                    costIsKnown: false,
                    tokenCountIsKnown: true)]))
        let snapshot = SyncedUsageSnapshot(providers: [provider], syncTimestamp: now, deviceName: "Fixture Mac")
        let insights = try #require(CostTabInsightsResolver.make(
            snapshot: snapshot,
            ledgerAggregation: nil,
            isLedgerEnabled: false,
            isDemoMode: false,
            localHistoryClearedAt: nil))
        #expect(insights.providerRows.count == 1)
        #expect(insights.total30DayCostIsKnown == false)
        let series = TokenActivity.series(providers: [provider], rollups: nil, referenceDate: now)
        #expect(series.count == 1)
        #expect(TokenActivity.knownTokens(series.first?.days.first) == 0)
    }

    @Test func `Unknown and absent token counts differ from confirmed zero`() {
        #expect(TokenActivity.knownTokens(nil) == nil)
        #expect(TokenActivity.knownTokens(SyncDailyPoint(
            dayKey: "2026-09-10",
            costUSD: 0,
            totalTokens: 0,
            tokenCountIsKnown: false)) == nil)
        #expect(TokenActivity.knownTokens(SyncDailyPoint(
            dayKey: "2026-09-10",
            costUSD: 0,
            totalTokens: 0,
            tokenCountIsKnown: true)) == 0)
    }

    @Test func `Known tokens remain available without a monetary cost`() {
        let point = SyncDailyPoint(
            dayKey: "2026-09-10",
            costUSD: 0,
            totalTokens: 1234,
            costIsKnown: false,
            tokenCountIsKnown: true)
        #expect(TokenActivity.knownTokens(point) == 1234)
        #expect(TokenActivity.intensity(1234) == 0.25)
    }

    @Test func `Unknown contributions cannot turn a daily total into a confirmed complete value`() {
        let points = TokenActivity.combine([
            SyncDailyPoint(dayKey: "2026-09-10", costUSD: 0, totalTokens: 100),
            SyncDailyPoint(dayKey: "2026-09-10", costUSD: 0, totalTokens: 0, tokenCountIsKnown: false),
        ])
        #expect(points.count == 1)
        #expect(points[0].totalTokens == 100)
        #expect(points[0].tokenCountIsKnown == false)
    }

    @Test func `Cleared or unmatched ledger never falls back to the current snapshot`() {
        let now = Date(timeIntervalSince1970: 1_789_084_800)
        let provider = ProviderUsageSnapshot(
            providerID: "codex",
            providerName: "Codex",
            primary: nil,
            secondary: nil,
            accountEmail: "test@example.invalid",
            loginMethod: nil,
            statusMessage: nil,
            isError: false,
            lastUpdated: now,
            costSummary: SyncCostSummary(
                sessionCostUSD: nil,
                sessionTokens: nil,
                last30DaysCostUSD: nil,
                last30DaysTokens: nil,
                daily: [
                    SyncDailyPoint(
                        dayKey: TokenActivity.dayKey(
                            now,
                            calendar: Calendar(identifier: .gregorian)),
                        costUSD: 0,
                        totalTokens: 100,
                        costIsKnown: false),
                ]))
        #expect(TokenActivity.series(providers: [provider], rollups: [], referenceDate: now).isEmpty)
        #expect(TokenActivity.series(providers: [provider], rollups: nil, referenceDate: now).count == 1)
    }

    @Test func `Intensity thresholds stay fixed across chart reloads`() {
        #expect([0, 99999, 100_000, 999_999, 1_000_000, 9_999_999, 10_000_000].map(TokenActivity.intensity) == [
            0,
            0.25,
            0.5,
            0.5,
            0.75,
            0.75,
            1,
        ])
    }

    @Test func `Snapshot window excludes old and future rows and maps producer today to reader today`() {
        let now = Date(timeIntervalSince1970: 1_789_084_800)
        let summary = SyncCostSummary(
            sessionCostUSD: nil,
            sessionTokens: nil,
            last30DaysCostUSD: nil,
            last30DaysTokens: nil,
            daily: [
                SyncDailyPoint(dayKey: "2026-09-10", costUSD: 0, totalTokens: 100),
                SyncDailyPoint(dayKey: "2026-09-11", costUSD: 0, totalTokens: 200),
                SyncDailyPoint(dayKey: "2024-09-09", costUSD: 0, totalTokens: 300),
            ],
            bucketTimeZoneIdentifier: "America/Los_Angeles")
        let days = TokenActivity.snapshotDays(summary, referenceDate: now, readerTimeZone: .gmt)
        #expect(days.count == 1)
        #expect(days.first?.totalTokens == 100)
        #expect(days.first?.dayKey == "2026-09-11")
    }

    @Test @MainActor func `A missing writer count preserves the other writer contribution as a lower bound`() throws {
        let container = try ModelContainer(
            for: DailyCostPoint.self,
            configurations: ModelConfiguration(
                isStoredInMemoryOnly: true,
                cloudKitDatabase: .none))
        let context = ModelContext(container)
        let now = Date(timeIntervalSince1970: 1_789_084_800)
        for device in ["mac-A", "mac-B"] {
            try CostLedgerService.upsertDayPoint(
                deviceID: device,
                providerID: "codex",
                dayKey: "2026-09-10",
                costUSD: 0,
                totalTokens: device == "mac-A" ? 100 : 999,
                tokenCountIsKnown: device == "mac-A",
                costIsKnown: false,
                isEstimated: nil,
                modelBreakdowns: [],
                serviceBreakdowns: [],
                lastUpdated: now,
                in: context)
        }
        let result = try CostLedgerService.aggregate(
            windowDays: 365,
            in: context,
            asOf: now,
            readerTimeZone: #require(TimeZone(secondsFromGMT: 0)))
        #expect(result.totalTokens == 100)
        #expect(result.dailyPoints.first?.totalTokens == 100)
        #expect(result.dailyPoints.first?.tokenCountIsKnown == false)
        #expect(result.sortedProviderRollups.first?.dailyPoints.first?.totalTokens == 100)
    }

    @Test @MainActor func `Two local Macs sum once and repeated updates preserve token availability`() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        let container = try ModelContainer(for: DailyCostPoint.self, configurations: config)
        let context = ModelContext(container)
        let now = Date(timeIntervalSince1970: 1_789_084_800)
        for device in ["mac-A", "mac-B", "mac-A"] {
            try CostLedgerService.upsertDayPoint(
                deviceID: device,
                providerID: "codex",
                dayKey: "2026-09-10",
                costUSD: 0,
                totalTokens: device == "mac-A" ? 100 : 200,
                tokenCountIsKnown: true,
                costIsKnown: false,
                isEstimated: nil,
                modelBreakdowns: [],
                serviceBreakdowns: [],
                lastUpdated: now,
                in: context)
        }
        try context.save()
        let result = try CostLedgerService.aggregate(
            windowDays: 365,
            in: context,
            asOf: now,
            readerTimeZone: #require(TimeZone(secondsFromGMT: 0)))
        #expect(try context.fetchCount(FetchDescriptor<DailyCostPoint>()) == 2)
        #expect(result.totalTokens == 300)
        #expect(result.dailyPoints.first?.tokenCountIsKnown == true)
    }
}
