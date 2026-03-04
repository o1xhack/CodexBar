import CodexBarSync
import SwiftUI

@main
struct CodexBarMobileApp: App {
    @State private var usageData = SyncedUsageData()

    var body: some Scene {
        WindowGroup {
            ContentView(usageData: usageData)
                .onAppear {
                    usageData.startObserving()
                }
        }
    }
}
