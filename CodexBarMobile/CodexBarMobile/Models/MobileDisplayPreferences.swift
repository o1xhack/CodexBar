import CodexBarSync
import Foundation

enum MobileSettingsKeys {
    static let usageCostChartStyle = "usageCostChartStyle"
    static let dashboardCostChartStyle = "dashboardCostChartStyle"
    static let hidePersonalInfo = "hidePersonalInfo"
    static let openCostByDefault = "openCostByDefault"
    static let usagePercentDisplayMode = "usagePercentDisplayMode"
    static let showRemainingUsage = "showRemainingUsage"
}

enum UsagePercentDisplayMode: String, CaseIterable, Identifiable {
    case used
    case remaining

    var id: String {
        self.rawValue
    }

    var percentSuffix: String {
        switch self {
        case .used:
            String(localized: "used")
        case .remaining:
            String(localized: "left")
        }
    }

    func displayedPercent(for window: SyncRateWindow) -> Double {
        switch self {
        case .used:
            window.usedPercent
        case .remaining:
            window.remainingPercent
        }
    }

    func progressFraction(for window: SyncRateWindow) -> Double {
        min(max(self.displayedPercent(for: window) / 100, 0), 1)
    }

    func percentageValueText(for window: SyncRateWindow) -> String {
        let roundedValue = Int(self.displayedPercent(for: window).rounded())
        return "\(roundedValue)%"
    }

    func percentageText(for window: SyncRateWindow) -> String {
        "\(self.percentageValueText(for: window)) \(self.percentSuffix)"
    }
}
