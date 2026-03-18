import CodexBarSync
import SwiftUI

@main
struct CodexBarMobileApp: App {
    @State private var usageData: SyncedUsageData

    init() {
        let arguments = ProcessInfo.processInfo.arguments
        let currentVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"

        if arguments.contains("UI_TEST_RESET_DEFAULTS") {
            let defaults = UserDefaults.standard
            defaults.removeObject(forKey: MobileSettingsKeys.usageCostChartStyle)
            defaults.removeObject(forKey: MobileSettingsKeys.dashboardCostChartStyle)
            defaults.removeObject(forKey: MobileSettingsKeys.hidePersonalInfo)
            defaults.removeObject(forKey: MobileSettingsKeys.openCostByDefault)
            defaults.removeObject(forKey: MobileSettingsKeys.usagePercentDisplayMode)
            defaults.removeObject(forKey: MobileSettingsKeys.showRemainingUsage)
            defaults.removeObject(forKey: "onboardingSeenVersion")
        }

        if arguments.contains("UI_TEST_SKIP_ONBOARDING") {
            UserDefaults.standard.set(currentVersion, forKey: "onboardingSeenVersion")
        }

        if arguments.contains("UI_TEST_PREVIEW_DATA") {
            _usageData = State(initialValue: PreviewData.makeSyncedUsageData())
        } else {
            _usageData = State(initialValue: SyncedUsageData())
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView(usageData: usageData)
                .onAppear {
                    guard !ProcessInfo.processInfo.arguments.contains("UI_TEST_PREVIEW_DATA") else { return }
                    usageData.startObserving()
                }
        }
    }
}
