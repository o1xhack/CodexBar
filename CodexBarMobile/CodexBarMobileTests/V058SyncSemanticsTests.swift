import CodexBarSync
import Foundation
import SwiftUI
import Testing
@testable import CodexBarMobile

struct V058SyncSemanticsTests {
    private static let encoder = CloudSyncConstants.makeJSONEncoder()
    private static let decoder = CloudSyncConstants.makeJSONDecoder()
    private static let timestamp = Date(timeIntervalSince1970: 1_789_000_000)

    @Test
    @MainActor
    func `production daily and credit cards render at standard and accessibility text sizes`() throws {
        let daily = [
            SyncDailyPoint(
                dayKey: "2026-09-10",
                costUSD: 1.25,
                totalTokens: 12345,
                isEstimated: true,
                costIsKnown: true,
                requestCount: 12,
                tokenCountIsKnown: true),
            SyncDailyPoint(
                dayKey: "2026-09-09",
                costUSD: 0,
                totalTokens: 0,
                costIsKnown: false,
                requestCount: nil,
                tokenCountIsKnown: false),
        ]
        let summary = SyncCostSummary(
            sessionCostUSD: 1.25,
            sessionTokens: 12345,
            last30DaysCostUSD: 1.25,
            last30DaysTokens: 12345,
            daily: daily)
        for (label, size) in [("standard", DynamicTypeSize.large), ("accessibility", DynamicTypeSize.accessibility3)] {
            let card = VStack(spacing: 16) {
                ProviderAmountCard(amount: SyncProviderAmount(
                    kind: "balance",
                    amount: 0,
                    currencyCode: "Credits",
                    period: "Extra usage",
                    isEstimated: false), tintColor: .green)
                SyncedDailyActivityView(summary: summary)
            }
            .padding(20).frame(width: 390).background(Color(uiColor: .systemBackground))
            .environment(\.dynamicTypeSize, size)
            let renderer = ImageRenderer(content: card)
            renderer.scale = 2
            let data = try #require(renderer.uiImage?.pngData())
            let path = FileManager.default.temporaryDirectory.appendingPathComponent("v058-cards-" + label + ".png")
            try data.write(to: path)
            print("V058_RENDER " + path.path)
        }
    }

    private struct LegacyDaily: Decodable {
        let dayKey: String
        let costUSD: Double
        let totalTokens: Int
    }

    @Test
    @MainActor
    func `daily counters preserve unknowns and decode on legacy readers`() throws {
        let old = Data(#"{"dayKey":"2026-09-10","costUSD":0,"totalTokens":0}"#.utf8)
        let decoded = try Self.decoder.decode(SyncDailyPoint.self, from: old)
        #expect(decoded.requestCount == nil)
        #expect(decoded.tokenCountIsKnown == nil)
        let oldBudget = Data(#"{"usedAmount":1,"limitAmount":100,"currencyCode":"Credits"}"#.utf8)
        #expect(try Self.decoder.decode(SyncBudgetSnapshot.self, from: oldBudget).observedAt == nil)
        #expect(SyncedDailyActivityView.requestText(decoded) == String(localized: "Unavailable"))
        let point = SyncDailyPoint(
            dayKey: "2026-09-10",
            costUSD: 0,
            totalTokens: 0,
            costIsKnown: false,
            requestCount: 0,
            tokenCountIsKnown: false)
        let encoded = try Self.encoder.encode(point)
        #expect(try Self.decoder.decode(LegacyDaily.self, from: encoded).totalTokens == 0)
        #expect(try Self.decoder.decode(SyncDailyPoint.self, from: encoded) == point)
        #expect(SyncedDailyActivityView.requestText(point) == "0")
        #expect(SyncedDailyActivityView.tokenText(point) == String(localized: "Unavailable"))
        #expect(SyncedDailyActivityView.costText(point, currencyCode: "USD") == String(localized: "Unavailable"))
    }

    @Test(arguments: [false, true])
    func `daily request merge never presents partial or overflowing counts as complete`(unknown: Bool) throws {
        func snapshot(_ id: String, _ count: Int?) -> SyncedUsageSnapshot {
            let day = SyncDailyPoint(
                dayKey: "2026-09-10",
                costUSD: 1,
                totalTokens: 5,
                requestCount: count,
                tokenCountIsKnown: true)
            let cost = SyncCostSummary(
                sessionCostUSD: 1,
                sessionTokens: 5,
                last30DaysCostUSD: 1,
                last30DaysTokens: 5,
                daily: [day])
            let provider = ProviderUsageSnapshot(
                providerID: "claude",
                providerName: "Claude",
                primary: nil,
                secondary: nil,
                accountEmail: "fixture@example.invalid",
                loginMethod: nil,
                statusMessage: nil,
                isError: false,
                lastUpdated: Self.timestamp,
                costSummary: cost)
            return SyncedUsageSnapshot(
                providers: [provider],
                syncTimestamp: Self.timestamp,
                deviceName: id,
                deviceID: id,
                appVersion: "0.58.0.1")
        }
        let merged = try #require(ProviderSnapshotMerger.mergeSnapshots([
            snapshot("mac-a", unknown ? 5 : Int.max), snapshot("mac-b", unknown ? nil : 1),
        ]))
        let day = try #require(merged.providers.first?.costSummary?.daily.first)
        #expect(day.requestCount == nil)
        #expect(day.totalTokens == 10)
        let known = try #require(ProviderSnapshotMerger.mergeSnapshots([
            snapshot("mac-a", 5), snapshot("mac-b", 3),
        ]))
        #expect(known.providers.first?.costSummary?.daily.first?.requestCount == 8)
    }

    @Test
    func `session-only known cost does not invent daily tokens or requests`() throws {
        let key = "2026-09-10"
        func snapshot(_ id: String, daily: [SyncDailyPoint], tokens: Int?) -> SyncedUsageSnapshot {
            let summary = SyncCostSummary(sessionCostUSD: 1, sessionTokens: tokens,
                last30DaysCostUSD: 1, last30DaysTokens: tokens, daily: daily,
                sourceUpdatedAt: Self.timestamp, sourceDayKey: key, sessionDayKey: key,
                sessionCostIsKnown: true, historyCoverageIsEstablished: true)
            let provider = ProviderUsageSnapshot(providerID: "claude", providerName: "Claude",
                primary: nil, secondary: nil, accountEmail: "fixture@example.invalid", loginMethod: nil,
                statusMessage: nil, isError: false, lastUpdated: Self.timestamp, costSummary: summary)
            return SyncedUsageSnapshot(providers: [provider], syncTimestamp: Self.timestamp,
                deviceName: id, deviceID: id, appVersion: "0.58.0.1")
        }
        let known = SyncDailyPoint(dayKey: key, costUSD: 1, totalTokens: 5,
            costIsKnown: true, requestCount: 2, tokenCountIsKnown: true)
        let merged = try #require(ProviderSnapshotMerger.mergeSnapshots([
            snapshot("mac-a", daily: [known], tokens: 5), snapshot("mac-b", daily: [], tokens: nil)]))
        let point = try #require(merged.providers.first?.costSummary?.daily.first)
        #expect(point.costUSD == 2)
        #expect(point.costIsKnown == true)
        #expect(point.tokenCountIsKnown == false)
        #expect(point.requestCount == nil)
    }

    /// Frozen pre-v058 amount shape: unknown keys are ignored, amount itself is still required.
    private struct LegacyAmount: Decodable {
        let kind: String
        let amount: Double
        let currencyCode: String
        let period: String?
        let isEstimated: Bool
    }

    private static func writer(
        _ deviceID: String,
        new: Bool,
        amount: Double,
        observed: Int,
        quota: Int) -> SyncedUsageSnapshot
    {
        let provider = ProviderUsageSnapshot(
            providerID: "codex", providerName: "Codex",
            primary: SyncRateWindow(usedPercent: 10, windowMinutes: 300, resetsAt: nil, resetDescription: nil),
            secondary: nil,
            accountEmail: "fixture@example.invalid", loginMethod: nil, statusMessage: nil, isError: false,
            lastUpdated: Self.timestamp.addingTimeInterval(Double(quota)),
            budget: SyncBudgetSnapshot(
                usedAmount: 1,
                limitAmount: amount + 100,
                currencyCode: "Credits",
                period: "Monthly credit limit",
                resetsAt: nil,
                observedAt: new ? Self.timestamp.addingTimeInterval(Double(observed)) : nil),
            providerAmount: new ? SyncProviderAmount(
                kind: "balance", amount: amount, currencyCode: "Credits", period: "Extra usage",
                isEstimated: false, observedAt: Self.timestamp.addingTimeInterval(Double(observed))) : nil)
        return SyncedUsageSnapshot(
            providers: [provider], syncTimestamp: Self.timestamp.addingTimeInterval(Double(quota)),
            deviceName: deviceID, deviceID: deviceID, appVersion: new ? "0.58.0.1" : "0.56.0.1",
            mobileVersion: "1.23.0", notificationPushEnabled: true)
    }

    @Test
    func `new balance observation defeats a newer quota timestamp and survives cache persistence`() throws {
        let stale = Self.writer("mac-a", new: true, amount: 25, observed: 1, quota: 100)
        let cleared = Self.writer("mac-b", new: true, amount: 0, observed: 2, quota: 2)
        for input in [[stale, cleared], [cleared, stale]] {
            let merged = try #require(ProviderSnapshotMerger.mergeSnapshots(input))
            #expect(merged.providers.count == 1)
            #expect(merged.providers[0].providerAmount?.amount == 0)
            #expect(merged.providers[0].budget?.limitAmount == 100)
            let restored = try Self.decoder.decode(SyncedUsageSnapshot.self, from: Self.encoder.encode(merged))
            #expect(restored.providers[0].providerAmount?.observedAt == Self.timestamp.addingTimeInterval(2))
        }
    }

    @Test(arguments: Array(0..<16))
    func `two distinct writers and independent old-new reader caches preserve supported amounts`(mask: Int) throws {
        let macANew = mask & 8 != 0
        let macBNew = mask & 4 != 0
        let writers = [
            Self.writer("mac-a", new: macANew, amount: 25, observed: 1, quota: 1),
            Self.writer("mac-b", new: macBNew, amount: 0, observed: 2, quota: 2),
        ]
        let expected: Double? = macBNew ? 0 : macANew ? 25 : nil
        for (readerNew, ordered) in [(mask & 2 != 0, writers), (mask & 1 != 0, Array(writers.reversed()))] {
            var cache = SnapshotCache()
            for writer in ordered {
                let encoded = try Self.encoder.encode(writer)
                let decoded = try Self.decoder.decode(SyncedUsageSnapshot.self, from: encoded)
                cache.applyDelta(upserted: decoded.providers.map {
                    ProviderUsageEnvelope(
                        deviceID: writer.deviceID!, deviceName: writer.deviceName,
                        appVersion: writer.appVersion, mobileVersion: writer.mobileVersion,
                        syncTimestamp: writer.syncTimestamp, notificationPushEnabled: true, provider: $0)
                }, deletedRecordNames: [])
            }
            let snapshots = cache.buildDeviceSnapshots()
            let merged = try #require(ProviderSnapshotMerger.mergeSnapshots(snapshots))
            #expect(merged.providers.count == 1)
            let amount = merged.providers[0].providerAmount
            if readerNew {
                #expect(amount?.amount == expected)
            } else {
                #expect(try Self.oldReaderAmount(snapshots)?.amount == expected)
            }
        }
    }

    /// Frozen v0.56 providerAmount selection: latestNonNil sorted by quota lastUpdated, then device ID.
    /// This is a narrow old-reader substitute, not a physical-device claim.
    private static func oldReaderAmount(_ snapshots: [SyncedUsageSnapshot]) throws -> LegacyAmount? {
        let entries = snapshots.flatMap { snapshot in
            snapshot.providers.map { (provider: $0, deviceID: snapshot.deviceID ?? "") }
        }
        let selected = entries.sorted { lhs, rhs in
            lhs.provider.lastUpdated == rhs.provider.lastUpdated
                ? lhs.deviceID > rhs.deviceID
                : lhs.provider.lastUpdated > rhs.provider.lastUpdated
        }.first { $0.provider.providerAmount != nil }
        guard let amount = selected?.provider.providerAmount else { return nil }
        return try Self.decoder.decode(LegacyAmount.self, from: Self.encoder.encode(amount))
    }

    @Test
    func `old readers retain their documented quota-time ordering limitation`() throws {
        let writers = [
            Self.writer("mac-a", new: true, amount: 25, observed: 1, quota: 100),
            Self.writer("mac-b", new: true, amount: 0, observed: 2, quota: 2),
        ]
        #expect(try Self.oldReaderAmount(writers)?.amount == 25)
        #expect(ProviderSnapshotMerger.mergeSnapshots(writers)?.providers.first?.providerAmount?.amount == 0)
    }

    @Test
    @MainActor
    func `credits render as units rather than an invented ISO currency`() {
        let rendered = ProviderAmountCard.formattedAmount(25, currencyCode: "Credits")
        #expect(rendered.contains("25"))
        #expect(!rendered.contains("$"))
        #expect(!BudgetProgressView.formatCurrency(25, code: "Credits").contains("$"))
        for (locale, expected) in [
            ("en", "Monthly credit limit"),
            ("zh-Hans", "月度点数限额"),
            ("zh-Hant", "月度點數限額"),
            ("ja", "月間クレジット上限"),
        ] {
            #expect(BudgetProgressView.localizedPeriod(
                "Monthly credit limit", providerID: "codex", locale: Locale(identifier: locale)) == expected)
        }
    }
}
