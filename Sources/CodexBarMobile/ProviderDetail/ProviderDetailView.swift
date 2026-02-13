import CodexBarCore
import SwiftUI

/// Detail view for a single provider, showing full usage information.
/// Replaces the macOS provider submenu.
public struct ProviderDetailView: View {
    let provider: UsageProvider
    let snapshot: UsageSnapshot?
    let status: ProviderStatusSnapshot?

    public init(
        provider: UsageProvider,
        snapshot: UsageSnapshot?,
        status: ProviderStatusSnapshot?)
    {
        self.provider = provider
        self.snapshot = snapshot
        self.status = status
    }

    public var body: some View {
        List {
            // Usage section
            Section("Usage") {
                if let snapshot {
                    if let primary = snapshot.primary {
                        UsageDetailRow(label: "Session", window: primary)
                    }
                    if let secondary = snapshot.secondary {
                        UsageDetailRow(label: "Weekly", window: secondary)
                    }
                    if let tertiary = snapshot.tertiary {
                        UsageDetailRow(label: "Opus", window: tertiary)
                    }
                } else {
                    Text("No usage data available")
                        .foregroundStyle(.secondary)
                }
            }

            // Account section
            if let snapshot {
                Section("Account") {
                    if let email = snapshot.accountEmail(for: provider) {
                        LabeledContent("Email", value: email)
                    }
                    if let plan = snapshot.loginMethod(for: provider) {
                        LabeledContent("Plan", value: plan)
                    }
                }
            }

            // Status section
            if let status, status.indicator != .none {
                Section("Status") {
                    if let desc = status.description {
                        Text(desc)
                    }
                    if let updatedAt = status.updatedAt {
                        LabeledContent("Updated") {
                            Text(updatedAt, style: .relative)
                        }
                    }
                }
            }

            // Platform availability
            Section("Platform") {
                LabeledContent("Mobile Support") {
                    Text(provider.mobileAvailabilityLabel)
                        .foregroundStyle(availabilityColor)
                }
            }
        }
        .navigationTitle(provider.displayName)
    }

    private var availabilityColor: Color {
        switch provider.mobileAvailability {
        case .fullNative: .green
        case .limitedNative: .orange
        case .desktopOnly: .red
        case .syncedFromMac: .blue
        }
    }
}

private struct UsageDetailRow: View {
    let label: String
    let window: RateWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label)
                    .font(.headline)
                Spacer()
                Text(String(format: "%.0f%% used", window.usedPercent))
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: min(max(window.usedPercent / 100.0, 0), 1))
                .tint(progressColor)

            if let resetsAt = window.resetsAt {
                Text("Resets \(resetsAt, style: .relative)")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            if let desc = window.resetDescription {
                Text(desc)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }

    private var progressColor: Color {
        let used = window.usedPercent
        if used >= 90 { return .red }
        if used >= 70 { return .orange }
        return .accentColor
    }
}
