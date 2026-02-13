import CodexBarCore
import CodexBarMobile
import SwiftUI

@main
struct CodexBariOSApp: App {
    @State private var store = MobileUsageStore(
        capabilities: .iOS)

    var body: some Scene {
        WindowGroup {
            MainTabView(store: store)
                .task {
                    await store.refresh()
                }
        }
    }
}
