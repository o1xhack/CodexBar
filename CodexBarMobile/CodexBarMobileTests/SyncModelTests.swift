import CodexBarSync
import Foundation
import Testing

@Suite("Sync Model Codable Tests")
struct SyncModelTests {
    @Test("ProviderUsageSnapshot round-trips through JSON")
    func providerSnapshotCodable() throws {
        let snapshot = ProviderUsageSnapshot(
            providerID: "claude",
            providerName: "Claude",
            primary: SyncRateWindow(
                usedPercent: 42.5,
                windowMinutes: 300,
                resetsAt: Date(timeIntervalSince1970: 1_700_000_000),
                resetDescription: "Resets in 2h 30m"),
            secondary: SyncRateWindow(
                usedPercent: 15.0,
                windowMinutes: 10_080,
                resetsAt: nil,
                resetDescription: "Resets Monday"),
            accountEmail: "user@example.com",
            loginMethod: "Pro",
            statusMessage: nil,
            isError: false,
            lastUpdated: Date(timeIntervalSince1970: 1_700_000_000))

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(snapshot)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(ProviderUsageSnapshot.self, from: data)

        #expect(decoded.providerID == "claude")
        #expect(decoded.providerName == "Claude")
        #expect(decoded.primary?.usedPercent == 42.5)
        #expect(decoded.primary?.windowMinutes == 300)
        #expect(decoded.primary?.remainingPercent == 57.5)
        #expect(decoded.secondary?.usedPercent == 15.0)
        #expect(decoded.accountEmail == "user@example.com")
        #expect(decoded.loginMethod == "Pro")
        #expect(decoded.isError == false)
        #expect(decoded.costSummary == nil)
        #expect(decoded.budget == nil)
    }

    @Test("SyncedUsageSnapshot round-trips through JSON")
    func syncedSnapshotCodable() throws {
        let provider = ProviderUsageSnapshot(
            providerID: "codex",
            providerName: "Codex",
            primary: SyncRateWindow(
                usedPercent: 80.0,
                windowMinutes: 300,
                resetsAt: nil,
                resetDescription: nil),
            secondary: nil,
            accountEmail: nil,
            loginMethod: nil,
            statusMessage: "Rate limited",
            isError: true,
            lastUpdated: Date(timeIntervalSince1970: 1_700_000_000))

        let synced = SyncedUsageSnapshot(
            providers: [provider],
            syncTimestamp: Date(timeIntervalSince1970: 1_700_000_000),
            deviceName: "Test Mac")

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(synced)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(SyncedUsageSnapshot.self, from: data)

        #expect(decoded.providers.count == 1)
        #expect(decoded.providers[0].providerID == "codex")
        #expect(decoded.providers[0].isError == true)
        #expect(decoded.deviceName == "Test Mac")
    }

    @Test("SyncRateWindow remainingPercent clamps to zero")
    func remainingPercentClamped() {
        let window = SyncRateWindow(
            usedPercent: 150.0,
            windowMinutes: 300,
            resetsAt: nil,
            resetDescription: nil)
        #expect(window.remainingPercent == 0)
    }

    @Test("Empty provider list encodes correctly")
    func emptyProviders() throws {
        let synced = SyncedUsageSnapshot(
            providers: [],
            syncTimestamp: Date(timeIntervalSince1970: 1_700_000_000),
            deviceName: "Empty Mac")

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(synced)
        #expect(data.count < CloudSyncConstants.maxPayloadBytes)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(SyncedUsageSnapshot.self, from: data)
        #expect(decoded.providers.isEmpty)
    }

    // MARK: - Backward Compatibility

    @Test("Old JSON without cost fields decodes correctly")
    func backwardCompatibility() throws {
        // Simulate a payload from an older Mac app that doesn't include costSummary/budget
        let oldJSON = """
        {
            "providerID": "claude",
            "providerName": "Claude",
            "primary": {
                "usedPercent": 42.5,
                "windowMinutes": 300
            },
            "accountEmail": "user@example.com",
            "loginMethod": "Pro",
            "isError": false,
            "lastUpdated": "2023-11-14T22:13:20Z"
        }
        """

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(ProviderUsageSnapshot.self, from: Data(oldJSON.utf8))

        #expect(decoded.providerID == "claude")
        #expect(decoded.primary?.usedPercent == 42.5)
        #expect(decoded.costSummary == nil)
        #expect(decoded.budget == nil)
        #expect(decoded.secondary == nil)
        #expect(decoded.statusMessage == nil)
    }

    // MARK: - Cost Data Round-Trip

    @Test("Cost summary and budget round-trip through JSON")
    func costDataRoundTrip() throws {
        let daily = [
            SyncDailyPoint(dayKey: "2024-01-15", costUSD: 1.42, totalTokens: 12_340),
            SyncDailyPoint(dayKey: "2024-01-16", costUSD: 2.10, totalTokens: 18_500),
        ]

        let snapshot = ProviderUsageSnapshot(
            providerID: "claude",
            providerName: "Claude",
            primary: nil,
            secondary: nil,
            accountEmail: nil,
            loginMethod: nil,
            statusMessage: nil,
            isError: false,
            lastUpdated: Date(timeIntervalSince1970: 1_700_000_000),
            costSummary: SyncCostSummary(
                sessionCostUSD: 1.42,
                sessionTokens: 12_340,
                last30DaysCostUSD: 28.90,
                last30DaysTokens: 1_245_000,
                daily: daily),
            budget: SyncBudgetSnapshot(
                usedAmount: 42.50,
                limitAmount: 100.0,
                currencyCode: "USD",
                period: "Monthly",
                resetsAt: Date(timeIntervalSince1970: 1_701_000_000)))

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(snapshot)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(ProviderUsageSnapshot.self, from: data)

        #expect(decoded.costSummary?.sessionCostUSD == 1.42)
        #expect(decoded.costSummary?.sessionTokens == 12_340)
        #expect(decoded.costSummary?.last30DaysCostUSD == 28.90)
        #expect(decoded.costSummary?.last30DaysTokens == 1_245_000)
        #expect(decoded.costSummary?.daily.count == 2)
        #expect(decoded.costSummary?.daily[0].dayKey == "2024-01-15")
        #expect(decoded.costSummary?.daily[0].costUSD == 1.42)
        #expect(decoded.costSummary?.daily[0].totalTokens == 12_340)

        #expect(decoded.budget?.usedAmount == 42.50)
        #expect(decoded.budget?.limitAmount == 100.0)
        #expect(decoded.budget?.currencyCode == "USD")
        #expect(decoded.budget?.period == "Monthly")
        #expect(decoded.budget?.resetsAt != nil)
    }

    // MARK: - Payload Size

    // MARK: - Version Fields

    @Test("SyncedUsageSnapshot includes appVersion and mobileVersion")
    func versionFieldsRoundTrip() throws {
        let synced = SyncedUsageSnapshot(
            providers: [],
            syncTimestamp: Date(timeIntervalSince1970: 1_700_000_000),
            deviceName: "Test Mac",
            appVersion: "0.18.0-beta.3",
            mobileVersion: "0.1.1")

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(synced)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(SyncedUsageSnapshot.self, from: data)

        #expect(decoded.appVersion == "0.18.0-beta.3")
        #expect(decoded.mobileVersion == "0.1.1")
    }

    @Test("Legacy syncVersion key decodes into mobileVersion")
    func legacySyncVersionBackwardCompat() throws {
        let legacyJSON = """
        {
            "providers": [],
            "syncTimestamp": "2023-11-14T22:13:20Z",
            "deviceName": "Old Mac",
            "appVersion": "0.17.0",
            "syncVersion": "0.1.0"
        }
        """

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(SyncedUsageSnapshot.self, from: Data(legacyJSON.utf8))

        #expect(decoded.mobileVersion == "0.1.0")
    }

    @Test("Old payload without version fields decodes with nil")
    func versionFieldsBackwardCompat() throws {
        let oldJSON = """
        {
            "providers": [],
            "syncTimestamp": "2023-11-14T22:13:20Z",
            "deviceName": "Old Mac"
        }
        """

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(SyncedUsageSnapshot.self, from: Data(oldJSON.utf8))

        #expect(decoded.deviceName == "Old Mac")
        #expect(decoded.appVersion == nil)
        #expect(decoded.mobileVersion == nil)
    }

    // MARK: - Payload Size

    @Test("6 providers x 30 days stays under 1MB KVS limit")
    func payloadSizeCheck() throws {
        let daily = (0..<30).map { day in
            SyncDailyPoint(
                dayKey: "2024-01-\(String(format: "%02d", day + 1))",
                costUSD: Double.random(in: 0.10...5.00),
                totalTokens: Int.random(in: 1_000...100_000))
        }

        let costSummary = SyncCostSummary(
            sessionCostUSD: 2.50,
            sessionTokens: 25_000,
            last30DaysCostUSD: 45.00,
            last30DaysTokens: 2_000_000,
            daily: daily)

        let budget = SyncBudgetSnapshot(
            usedAmount: 60.0,
            limitAmount: 100.0,
            currencyCode: "USD",
            period: "Monthly",
            resetsAt: Date(timeIntervalSince1970: 1_701_000_000))

        let providers = (0..<6).map { i in
            ProviderUsageSnapshot(
                providerID: "provider-\(i)",
                providerName: "Provider \(i)",
                primary: SyncRateWindow(
                    usedPercent: Double(i * 15),
                    windowMinutes: 300,
                    resetsAt: Date(timeIntervalSince1970: 1_700_000_000),
                    resetDescription: nil),
                secondary: SyncRateWindow(
                    usedPercent: Double(i * 10),
                    windowMinutes: 10_080,
                    resetsAt: nil,
                    resetDescription: nil),
                accountEmail: "user\(i)@example.com",
                loginMethod: "Pro",
                statusMessage: nil,
                isError: false,
                lastUpdated: Date(timeIntervalSince1970: 1_700_000_000),
                costSummary: costSummary,
                budget: budget)
        }

        let synced = SyncedUsageSnapshot(
            providers: providers,
            syncTimestamp: Date(timeIntervalSince1970: 1_700_000_000),
            deviceName: "Test Mac")

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(synced)

        // iCloud KVS limit is 1MB per key
        #expect(data.count < CloudSyncConstants.maxPayloadBytes)
    }
}
