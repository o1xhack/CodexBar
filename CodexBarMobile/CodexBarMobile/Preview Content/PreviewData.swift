import CodexBarSync
import Foundation

enum PreviewData {
    // MARK: - Sample daily cost data (30 days)

    private static func makeDaily(
        baseCost: Double,
        tokenBase: Int,
        serviceMix: [(String, Double)] = [],
        modelMix: [(String, Double)] = []) -> [SyncDailyPoint]
    {
        let calendar = Calendar.current
        let today = Date()
        return (0..<30).reversed().map { daysAgo in
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
            let dayKey = Self.dayKeyFormatter.string(from: date)
            let dayFactor = 1 + (Double((daysAgo % 6) - 2) * 0.08)
            let cost = max(0.05, baseCost * dayFactor)
            let tokens = max(1000, Int(Double(tokenBase) * dayFactor))
            return SyncDailyPoint(
                dayKey: dayKey,
                costUSD: cost,
                totalTokens: tokens,
                modelBreakdowns: modelMix.map { label, share in
                    SyncCostBreakdown(label: label, costUSD: cost * share)
                },
                serviceBreakdowns: serviceMix.map { label, share in
                    SyncCostBreakdown(label: label, costUSD: cost * share)
                })
        }
    }

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
            sessionTokens: 12340,
            last30DaysCostUSD: 28.90,
            last30DaysTokens: 1_245_000,
            daily: makeDaily(
                baseCost: 0.96,
                tokenBase: 41500,
                modelMix: [("Claude Sonnet 4", 0.72), ("Claude Opus 4", 0.28)])),
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
                windowMinutes: 10080,
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
        providerName: "Codex",
        primary: SyncRateWindow(
            usedPercent: 78,
            windowMinutes: 180,
            resetsAt: Date().addingTimeInterval(3600),
            resetDescription: nil),
        secondary: SyncRateWindow(
            usedPercent: 55,
            windowMinutes: 10080,
            resetsAt: Date().addingTimeInterval(3600 * 24 * 2),
            resetDescription: nil),
        accountEmail: "dev@cursor.sh",
        loginMethod: "Business",
        statusMessage: nil,
        isError: false,
        lastUpdated: Date().addingTimeInterval(-300),
        costSummary: SyncCostSummary(
            sessionCostUSD: 3.18,
            sessionTokens: 28500,
            last30DaysCostUSD: 74.60,
            last30DaysTokens: 2_980_000,
            daily: makeDaily(
                baseCost: 2.48,
                tokenBase: 98000,
                serviceMix: [("Codex Run", 0.74), ("GitHub Code Review", 0.18), ("Responses API", 0.08)],
                modelMix: [("gpt-5.4", 0.52), ("gpt-5.3-codex", 0.33), ("gpt-5.1-codex-mini", 0.15)])),
        budget: SyncBudgetSnapshot(
            usedAmount: 74.60,
            limitAmount: 120.0,
            currencyCode: "USD",
            period: "Monthly",
            resetsAt: Date().addingTimeInterval(3600 * 24 * 9)))

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
        lastUpdated: Date().addingTimeInterval(-60),
        costSummary: SyncCostSummary(
            sessionCostUSD: 0.48,
            sessionTokens: 5400,
            last30DaysCostUSD: 11.80,
            last30DaysTokens: 422_000,
            daily: makeDaily(
                baseCost: 0.39,
                tokenBase: 13500,
                modelMix: [("openrouter/sonoma", 0.44), ("deepseek-chat", 0.31), ("qwen-max", 0.25)])))

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
            windowMinutes: 10080,
            resetsAt: Date().addingTimeInterval(3600 * 24 * 5),
            resetDescription: "Resets every Monday"),
        accountEmail: "user@openai.com",
        loginMethod: "Plus",
        statusMessage: nil,
        isError: false,
        lastUpdated: Date().addingTimeInterval(-600),
        costSummary: SyncCostSummary(
            sessionCostUSD: 0.92,
            sessionTokens: 9800,
            last30DaysCostUSD: 19.40,
            last30DaysTokens: 730_000,
            daily: makeDaily(
                baseCost: 0.65,
                tokenBase: 24500,
                modelMix: [("gpt-4.1", 0.58), ("gpt-4o", 0.42)])))

    static let sampleSnapshot = SyncedUsageSnapshot(
        providers: [claudeProvider, cursorProvider, openRouterProvider, chatGPTProvider],
        syncTimestamp: Date().addingTimeInterval(-45),
        deviceName: "MacBook Pro",
        appVersion: "0.18.0",
        mobileVersion: "1.0.0")

    @MainActor
    static func makeSyncedUsageData() -> SyncedUsageData {
        let data = SyncedUsageData()
        data.snapshot = self.sampleSnapshot
        return data
    }

    @MainActor
    static func makeEmptyUsageData() -> SyncedUsageData {
        SyncedUsageData()
    }
}
