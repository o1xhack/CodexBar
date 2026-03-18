import CodexBarSync
import Testing
@testable import CodexBarMobile

@Suite("Mobile Display Formatting")
struct MobileDisplayFormattingTests {
    @Test("Used mode shows used percent and fill")
    func usedModeValues() {
        let window = SyncRateWindow(usedPercent: 78, windowMinutes: 300, resetsAt: nil, resetDescription: nil)

        #expect(UsagePercentDisplayMode.used.displayedPercent(for: window) == 78)
        #expect(UsagePercentDisplayMode.used.progressFraction(for: window) == 0.78)
        #expect(UsagePercentDisplayMode.used.percentageText(for: window) == "78% \(String(localized: "used"))")
    }

    @Test("Remaining mode shows inverse percent and fill")
    func remainingModeValues() {
        let window = SyncRateWindow(usedPercent: 78, windowMinutes: 300, resetsAt: nil, resetDescription: nil)

        #expect(UsagePercentDisplayMode.remaining.displayedPercent(for: window) == 22)
        #expect(UsagePercentDisplayMode.remaining.progressFraction(for: window) == 0.22)
        #expect(UsagePercentDisplayMode.remaining.percentageText(for: window) == "22% \(String(localized: "left"))")
    }

    @Test("Axis formatter uses clean integer ticks for large values")
    func axisFormatterLargeValues() {
        #expect(MobileChartAxisFormatter.axisValues(for: [12.4, 64.3, 152.71]) == [0, 50, 100, 150, 200])
    }

    @Test("Axis formatter avoids decimal tick labels for small values")
    func axisFormatterSmallValues() {
        #expect(MobileChartAxisFormatter.axisValues(for: [0.18, 1.42, 2.48]) == [0, 1, 2, 3])
        #expect(MobileChartAxisFormatter.axisLabel(for: 3) == "3")
    }
}
