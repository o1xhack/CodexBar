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
}
