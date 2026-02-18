import CodexBarSync
import SwiftUI

struct ContentView: View {
    let usageData: SyncedUsageData

    var body: some View {
        NavigationStack {
            Group {
                if let snapshot = usageData.snapshot {
                    if snapshot.providers.isEmpty {
                        EmptyStateView(
                            title: "No Providers Enabled",
                            message: "Enable providers in CodexBar on your Mac to see usage data here.")
                    } else {
                        providerList(snapshot: snapshot)
                    }
                } else {
                    EmptyStateView(
                        title: "Waiting for Sync",
                        message: "Open CodexBar on your Mac to sync usage data via iCloud.")
                }
            }
            .navigationTitle("CodexBar")
            #if os(iOS)
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    syncStatusFooter
                }
            }
            #else
            .safeAreaInset(edge: .bottom) {
                syncStatusFooter
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
            #endif
        }
    }

    private func providerList(snapshot: SyncedUsageSnapshot) -> some View {
        List {
            ForEach(snapshot.providers, id: \.providerID) { provider in
                ProviderUsageView(provider: provider)
            }
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        #endif
    }

    @ViewBuilder
    private var syncStatusFooter: some View {
        if let snapshot = usageData.snapshot {
            VStack(spacing: 2) {
                Text("Last sync: \(snapshot.syncTimestamp.formatted(.relative(presentation: .named)))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("From: \(snapshot.deviceName)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}
