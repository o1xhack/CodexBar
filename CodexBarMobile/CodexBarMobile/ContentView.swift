import CodexBarSync
import SwiftUI

struct ContentView: View {
    let usageData: SyncedUsageData
    @State private var isDemoMode = false
    @AppStorage("onboardingSeenVersion") private var onboardingSeenVersion = ""

    private var currentVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
    }

    private var shouldShowOnboarding: Bool {
        self.onboardingSeenVersion != self.currentVersion
    }

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
        .fullScreenCover(isPresented: .init(
            get: { self.shouldShowOnboarding },
            set: { if !$0 { self.onboardingSeenVersion = self.currentVersion } }
        )) {
            OnboardingSheet(onDismiss: {
                self.onboardingSeenVersion = self.currentVersion
            }, onDemo: {
                self.onboardingSeenVersion = self.currentVersion
                self.isDemoMode = true
            })
        }
    }
}

private struct OnboardingSheet: View {
    let onDismiss: () -> Void
    let onDemo: () -> Void

    var body: some View {
        NavigationStack {
            OnboardingView(onDemo: self.onDemo)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") {
                            self.onDismiss()
                        }
                        .fontWeight(.semibold)
                    }
                }
        }
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
                        ProviderListView(
                            snapshot: snapshot,
                            usageData: self.usageData,
                            isDemoMode: self.isDemoMode)
                    }
                } else {
                    OnboardingView(onDemo: { self.isDemoMode = true })
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
            }
        }
    }
}

// MARK: - Provider List

private struct ProviderListView: View {
    let snapshot: SyncedUsageSnapshot
    let usageData: SyncedUsageData
    let isDemoMode: Bool

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(self.snapshot.providers, id: \.providerID) { provider in
                    NavigationLink {
                        ProviderDetailView(provider: provider)
                    } label: {
                        ProviderUsageView(provider: provider)
                    }
                    .buttonStyle(.plain)
                }

                // Sync status at scroll bottom
                if self.isDemoMode {
                    Label("Showing demo data", systemImage: "sparkles")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                } else {
                    SyncStatusBar(usageData: self.usageData)
                        .padding(.top, 4)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .refreshable {
            self.usageData.refresh()
        }
        .modifier(SoftScrollEdgeModifier())
    }
}

/// Applies `.scrollEdgeEffectStyle(.soft)` on iOS 26+, no-op on older systems.
private struct SoftScrollEdgeModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content.scrollEdgeEffectStyle(.soft, for: .top)
        } else {
            content
        }
    }
}

// MARK: - Sync Status Bar

private struct SyncStatusBar: View {
    let usageData: SyncedUsageData

    var body: some View {
        VStack(spacing: 4) {
            if let error = self.usageData.lastSyncError {
                HStack(spacing: 5) {
                    Image(systemName: "exclamationmark.icloud.fill")
                        .font(.caption2)
                        .foregroundStyle(.red)
                    Text(error)
                        .font(.caption2)
                        .foregroundStyle(.red)
                }
            }

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

                Text("Data pushed by Mac · Pull to check for updates")
                    .font(.caption2)
                    .foregroundStyle(.quaternary)
            }
        }
    }
}

// MARK: - About Tab

private struct AboutTab: View {
    let usageData: SyncedUsageData
    @State private var showingSetupGuide = false

    var body: some View {
        NavigationStack {
            List {
                Section("App") {
                    LabeledContent("Version", value: {
                        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
                        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
                        return "\(version) (\(build))"
                    }())
                    LabeledContent("Platform", value: "iOS")
                }

                Section("Sync") {
                    if let snapshot = self.usageData.snapshot {
                        LabeledContent("Last Sync", value: snapshot.syncTimestamp.formatted(date: .abbreviated, time: .shortened))
                        LabeledContent("Source Device", value: snapshot.deviceName)
                        LabeledContent("Providers", value: "\(snapshot.providers.count)")
                        if let appVersion = snapshot.appVersion {
                            LabeledContent("Mac Version", value: appVersion)
                        }
                        if let mobileVersion = snapshot.mobileVersion {
                            LabeledContent("Mobile Version", value: mobileVersion)
                        }
                    } else {
                        Text("Not yet synced")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("How It Works") {
                    Label("CodexBar on your Mac pushes usage data to iCloud", systemImage: "laptopcomputer")
                    Label("This app reads the latest snapshot via iCloud Key-Value Store", systemImage: "icloud")
                    Label("Data syncs automatically when both devices are online", systemImage: "arrow.triangle.2.circlepath")

                    Button {
                        self.showingSetupGuide = true
                    } label: {
                        Label("Show Setup Guide", systemImage: "questionmark.circle")
                    }
                }

                Section("Developer") {
                    Link(destination: URL(string: "https://x.com/o1xhack")!) {
                        Label {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Yuxiao")
                                    .fontWeight(.medium)
                                Text("@o1xhack on X")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "person.fill")
                        }
                    }
                }

                Section("Open Source") {
                    Link(destination: URL(string: "https://github.com/o1xhack/CodexBar")!) {
                        Label {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("o1xhack/CodexBar")
                                    .fontWeight(.medium)
                                Text("Install the Mac app from this repo")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "chevron.left.forwardslash.chevron.right")
                        }
                    }

                    Link(destination: URL(string: "https://github.com/steipete/CodexBar")!) {
                        Label {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("steipete/CodexBar")
                                    .fontWeight(.medium)
                                Text("Original Mac app — MIT License")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "arrow.triangle.branch")
                        }
                    }
                }
            }
            .navigationTitle("About")
            .sheet(isPresented: self.$showingSetupGuide) {
                NavigationStack {
                    OnboardingView()
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("Done") {
                                    self.showingSetupGuide = false
                                }
                                .fontWeight(.semibold)
                            }
                        }
                }
            }
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
