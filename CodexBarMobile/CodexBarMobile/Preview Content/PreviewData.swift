import CodexBarSync
import Foundation

enum PreviewData {
    static let claudeProvider = ProviderUsageSnapshot(
        providerID: "claude",
        providerName: "Claude",
        primary: SyncRateWindow(
            usedPercent: 42,
            windowMinutes: 300,
            resetsAt: Date().addingTimeInterval(3600 * 2.5),
            resetDescription: nil),
        secondary: SyncRateWindow(
            usedPercent: 18,
            windowMinutes: 10_080,
            resetsAt: Date().addingTimeInterval(3600 * 24 * 4),
            resetDescription: nil),
        accountEmail: "user@example.com",
        loginMethod: "Pro",
        statusMessage: nil,
        isError: false,
        lastUpdated: Date().addingTimeInterval(-120))

    static let cursorProvider = ProviderUsageSnapshot(
        providerID: "codex",
        providerName: "Cursor",
        primary: SyncRateWindow(
            usedPercent: 78,
            windowMinutes: 180,
            resetsAt: Date().addingTimeInterval(3600),
            resetDescription: nil),
        secondary: SyncRateWindow(
            usedPercent: 55,
            windowMinutes: 10_080,
            resetsAt: Date().addingTimeInterval(3600 * 24 * 2),
            resetDescription: nil),
        accountEmail: "dev@cursor.sh",
        loginMethod: "Business",
        statusMessage: nil,
        isError: false,
        lastUpdated: Date().addingTimeInterval(-300))

    static let openRouterProvider = ProviderUsageSnapshot(
        providerID: "openrouter",
        providerName: "OpenRouter",
        primary: SyncRateWindow(
            usedPercent: 92,
            windowMinutes: 60,
            resetsAt: Date().addingTimeInterval(600),
            resetDescription: nil),
        secondary: nil,
        accountEmail: "user@openrouter.ai",
        loginMethod: "Credits",
        statusMessage: "Rate limit approaching",
        isError: true,
        lastUpdated: Date().addingTimeInterval(-60))

    static let chatGPTProvider = ProviderUsageSnapshot(
        providerID: "chatgpt",
        providerName: "ChatGPT",
        primary: SyncRateWindow(
            usedPercent: 5,
            windowMinutes: 180,
            resetsAt: Date().addingTimeInterval(3600 * 2),
            resetDescription: nil),
        secondary: SyncRateWindow(
            usedPercent: 12,
            windowMinutes: 10_080,
            resetsAt: Date().addingTimeInterval(3600 * 24 * 5),
            resetDescription: "Resets every Monday"),
        accountEmail: "user@openai.com",
        loginMethod: "Plus",
        statusMessage: nil,
        isError: false,
        lastUpdated: Date().addingTimeInterval(-600))

    static let sampleSnapshot = SyncedUsageSnapshot(
        providers: [claudeProvider, cursorProvider, openRouterProvider, chatGPTProvider],
        syncTimestamp: Date().addingTimeInterval(-45),
        deviceName: "MacBook Pro")

    @MainActor
    static func makeSyncedUsageData() -> SyncedUsageData {
        let data = SyncedUsageData()
        data.snapshot = sampleSnapshot
        return data
    }

    @MainActor
    static func makeEmptyUsageData() -> SyncedUsageData {
        SyncedUsageData()
    }
}
