import CodexBarSync
import SwiftUI

struct ContentView: View {
    let usageData: SyncedUsageData
    @State private var isDemoMode = false

    var body: some View {
        TabView {
            UsageTab(usageData: self.usageData, isDemoMode: self.$isDemoMode)
                .tabItem {
                    Label("Usage", systemImage: "chart.bar.fill")
                }

            AboutTab(usageData: self.usageData)
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .modifier(TabBarMinimizeModifier())
    }
}

/// Applies `.tabBarMinimizeBehavior(.onScrollDown)` on iOS 26+, no-op on older systems.
private struct TabBarMinimizeModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content.tabBarMinimizeBehavior(.onScrollDown)
        } else {
            content
        }
    }
}

// MARK: - Usage Tab

private struct UsageTab: View {
    let usageData: SyncedUsageData
    @Binding var isDemoMode: Bool

    private var displaySnapshot: SyncedUsageSnapshot? {
        if self.isDemoMode {
            return PreviewData.sampleSnapshot
        }
        return self.usageData.snapshot
    }

    var body: some View {
        NavigationStack {
            Group {
                if let snapshot = self.displaySnapshot {
                    if snapshot.providers.isEmpty {
                        EmptyStateView(
                            title: "No Providers Enabled",
                            message: "Enable providers in CodexBar on your Mac to see usage data here.",
                            systemImage: "slider.horizontal.3")
                    } else {
                        ProviderListView(snapshot: snapshot)
                    }
                } else {
                    EmptyStateView(
                        title: "Waiting for Sync",
                        message: "Open CodexBar on your Mac to sync usage data via iCloud.",
                        systemImage: "icloud.and.arrow.down",
                        onDemo: { self.isDemoMode = true })
                }
            }
            .navigationTitle(self.isDemoMode ? "CodexBar (Demo)" : "CodexBar")
            .toolbar {
                if self.isDemoMode {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            self.isDemoMode = false
                        } label: {
                            Text("Exit Demo")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                    }
                }
                ToolbarItem(placement: .bottomBar) {
                    if self.isDemoMode {
                        Label("Showing demo data", systemImage: "sparkles")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    } else {
                        SyncStatusBar(usageData: self.usageData)
                    }
                }
            }
        }
    }
}

// MARK: - Provider List

private struct ProviderListView: View {
    let snapshot: SyncedUsageSnapshot

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(self.snapshot.providers, id: \.providerID) { provider in
                    ProviderUsageView(provider: provider)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .modifier(SoftScrollEdgeModifier())
    }
}

/// Applies `.scrollEdgeEffectStyle(.soft)` on iOS 26+, no-op on older systems.
private struct SoftScrollEdgeModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content.scrollEdgeEffectStyle(.soft, for: .all)
        } else {
            content
        }
    }
}

// MARK: - Sync Status Bar

private struct SyncStatusBar: View {
    let usageData: SyncedUsageData

    var body: some View {
        if let snapshot = self.usageData.snapshot {
            HStack(spacing: 6) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(snapshot.syncTimestamp.formatted(.relative(presentation: .named)))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("·")
                    .foregroundStyle(.quaternary)
                Image(systemName: "laptopcomputer")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Text(snapshot.deviceName)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}

// MARK: - About Tab

private struct AboutTab: View {
    let usageData: SyncedUsageData

    var body: some View {
        NavigationStack {
            List {
                Section("App") {
                    LabeledContent("Version", value: "1.0.0")
                    LabeledContent("Platform", value: "iOS")
                }

                Section("Sync") {
                    if let snapshot = self.usageData.snapshot {
                        LabeledContent("Last Sync", value: snapshot.syncTimestamp.formatted(date: .abbreviated, time: .shortened))
                        LabeledContent("Source Device", value: snapshot.deviceName)
                        LabeledContent("Providers", value: "\(snapshot.providers.count)")
                    } else {
                        Text("Not yet synced")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("How It Works") {
                    Label("CodexBar on your Mac pushes usage data to iCloud", systemImage: "laptopcomputer")
                    Label("This app reads the latest snapshot via iCloud Key-Value Store", systemImage: "icloud")
                    Label("Data syncs automatically when both devices are online", systemImage: "arrow.triangle.2.circlepath")
                }
            }
            .navigationTitle("About")
        }
    }
}

// MARK: - Previews

#Preview("With Data") {
    ContentView(usageData: PreviewData.makeSyncedUsageData())
}

#Preview("Empty State") {
    ContentView(usageData: PreviewData.makeEmptyUsageData())
}
