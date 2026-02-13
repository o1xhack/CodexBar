import CodexBarCore
import SwiftUI

/// List of all providers with enable/disable toggles and navigation to detail.
public struct ProviderListView: View {
    @Bindable var store: MobileUsageStore

    public init(store: MobileUsageStore) {
        self.store = store
    }

    public var body: some View {
        List {
            Section("Available on Mobile") {
                ForEach(nativeProviders, id: \.self) { provider in
                    ProviderRow(
                        provider: provider,
                        isEnabled: store.enabledProviders.contains(provider),
                        snapshot: store.snapshots[provider],
                        status: store.statuses[provider],
                        onToggle: { toggleProvider(provider) })
                }
            }

            Section("Limited on Mobile") {
                ForEach(limitedProviders, id: \.self) { provider in
                    ProviderRow(
                        provider: provider,
                        isEnabled: store.enabledProviders.contains(provider),
                        snapshot: store.snapshots[provider],
                        status: store.statuses[provider],
                        onToggle: { toggleProvider(provider) })
                }
            }

            Section {
                ForEach(desktopOnlyProviders, id: \.self) { provider in
                    HStack {
                        ProviderIconView(provider: provider)
                            .frame(width: 24, height: 24)
                        Text(provider.displayName)
                        Spacer()
                        Text("Desktop Only")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .opacity(0.6)
                }
            } header: {
                Text("Desktop Only")
            } footer: {
                Text("These providers require CLI or browser access. Connect a Mac running CodexBar to sync their data.")
            }
        }
    }

    private var nativeProviders: [UsageProvider] {
        UsageProvider.allCases.filter { $0.mobileAvailability == .fullNative }
    }

    private var limitedProviders: [UsageProvider] {
        UsageProvider.allCases.filter { $0.mobileAvailability == .limitedNative }
    }

    private var desktopOnlyProviders: [UsageProvider] {
        UsageProvider.allCases.filter { $0.mobileAvailability == .desktopOnly }
    }

    private func toggleProvider(_ provider: UsageProvider) {
        if let index = store.enabledProviders.firstIndex(of: provider) {
            store.enabledProviders.remove(at: index)
        } else {
            store.enabledProviders.append(provider)
        }
    }
}

private struct ProviderRow: View {
    let provider: UsageProvider
    let isEnabled: Bool
    let snapshot: UsageSnapshot?
    let status: ProviderStatusSnapshot?
    let onToggle: () -> Void

    var body: some View {
        NavigationLink {
            ProviderDetailView(
                provider: provider,
                snapshot: snapshot,
                status: status)
        } label: {
            HStack {
                ProviderIconView(provider: provider)
                    .frame(width: 24, height: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(provider.displayName)
                        .font(.body)
                    if let snapshot, let primary = snapshot.primary {
                        Text(String(format: "%.0f%% remaining", max(0, 100 - primary.usedPercent)))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Toggle("", isOn: Binding(
                    get: { isEnabled },
                    set: { _ in onToggle() }))
                    .labelsHidden()
            }
        }
    }
}
