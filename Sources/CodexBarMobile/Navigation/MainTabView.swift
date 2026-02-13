import CodexBarCore
import SwiftUI

/// Root navigation for the mobile app — replaces the macOS menu bar paradigm
/// with a standard tab-based layout.
public struct MainTabView: View {
    @Bindable var store: MobileUsageStore

    public init(store: MobileUsageStore) {
        self.store = store
    }

    public var body: some View {
        TabView(selection: $store.selectedTab) {
            Tab("Dashboard", systemImage: "chart.bar.fill", value: MobileTab.dashboard) {
                NavigationStack {
                    DashboardView(store: store)
                        .navigationTitle("CodexBar")
                }
            }

            Tab("Providers", systemImage: "square.grid.2x2.fill", value: MobileTab.providers) {
                NavigationStack {
                    ProviderListView(store: store)
                        .navigationTitle("Providers")
                }
            }

            Tab("Settings", systemImage: "gearshape.fill", value: MobileTab.settings) {
                NavigationStack {
                    SettingsView(store: store)
                        .navigationTitle("Settings")
                }
            }
        }
    }
}

public enum MobileTab: Hashable, Sendable {
    case dashboard
    case providers
    case settings
}
