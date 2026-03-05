import CodexBarSync
import Foundation

enum PreviewData {
    // MARK: - Sample daily cost data (30 days)

    private static let sampleDaily: [SyncDailyPoint] = {
        let calendar = Calendar.current
        let today = Date()
        return (0..<30).reversed().map { daysAgo in
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
            let dayKey = Self.dayKeyFormatter.string(from: date)
            let cost = Double.random(in: 0.20...3.50)
            let tokens = Int.random(in: 5_000...80_000)
            return SyncDailyPoint(dayKey: dayKey, costUSD: cost, totalTokens: tokens)
        }
    }()

    private static let dayKeyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    // MARK: - Providers

    static let claudeProvider = ProviderUsageSnapshot(
        providerID: "claude",
        providerName: "Claude",
        primary: nil,
        secondary: nil,
        accountEmail: "user@example.com",
        loginMethod: "Max",
        statusMessage: nil,
        isError: false,
        lastUpdated: Date().addingTimeInterval(-120),
        costSummary: SyncCostSummary(
            sessionCostUSD: 1.42,
            sessionTokens: 12_340,
            last30DaysCostUSD: 28.90,
            last30DaysTokens: 1_245_000,
            daily: sampleDaily),
        budget: SyncBudgetSnapshot(
            usedAmount: 42.50,
            limitAmount: 100.0,
            currencyCode: "USD",
            period: "Monthly",
            resetsAt: Date().addingTimeInterval(3600 * 24 * 12)),
        rateWindows: [
            SyncRateWindow(
                label: "Session",
                usedPercent: 3,
                windowMinutes: 300,
                resetsAt: Date().addingTimeInterval(3600 * 2.5),
                resetDescription: nil),
            SyncRateWindow(
                label: "Weekly",
                usedPercent: 4,
                windowMinutes: 10_080,
                resetsAt: Date().addingTimeInterval(3600 * 24 * 4),
                resetDescription: nil),
            SyncRateWindow(
                label: "Sonnet",
                usedPercent: 0,
                windowMinutes: 300,
                resetsAt: Date().addingTimeInterval(3600 * 4.5),
                resetDescription: nil),
        ])

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
