import CodexBarCore
import SwiftUI

/// Main dashboard showing usage cards for all enabled providers.
/// Replaces the macOS NSMenu dropdown with a scrollable card list.
public struct DashboardView: View {
    let store: MobileUsageStore

    public init(store: MobileUsageStore) {
        self.store = store
    }

    public var body: some View {
        ScrollView {
            if store.enabledProviders.isEmpty {
                ContentUnavailableView(
                    "No Providers Enabled",
                    systemImage: "square.grid.2x2",
                    description: Text("Go to the Providers tab to enable AI coding assistants."))
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(store.enabledProviders, id: \.self) { provider in
                        ProviderCardView(
                            provider: provider,
                            snapshot: store.snapshots[provider],
                            status: store.statuses[provider])
                    }
                }
                .padding()
            }
        }
        .refreshable {
            await store.refresh()
        }
        .overlay {
            if store.isRefreshing && store.snapshots.isEmpty {
                ProgressView("Loading...")
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task { await store.refresh() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(store.isRefreshing)
            }
        }
    }
}
