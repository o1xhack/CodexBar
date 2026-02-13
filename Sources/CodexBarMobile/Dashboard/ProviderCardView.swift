import CodexBarCore
import SwiftUI

/// A card showing a single provider's usage data.
/// Adapted from the macOS MenuDescriptor section rendering.
struct ProviderCardView: View {
    let provider: UsageProvider
    let snapshot: UsageSnapshot?
    let status: ProviderStatusSnapshot?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                ProviderIconView(provider: provider)
                    .frame(width: 28, height: 28)
                Text(provider.displayName)
                    .font(.headline)
                Spacer()
                if let status, status.indicator != .none {
                    StatusBadge(status: status)
                }
            }

            if let snapshot {
                // Primary usage (session)
                if let primary = snapshot.primary {
                    UsageBarRow(
                        label: "Session",
                        window: primary)
                }

                // Secondary usage (weekly)
                if let secondary = snapshot.secondary {
                    UsageBarRow(
                        label: "Weekly",
                        window: secondary)
                }

                // Tertiary usage (opus)
                if let tertiary = snapshot.tertiary {
                    UsageBarRow(
                        label: "Opus",
                        window: tertiary)
                }

                // Account info
                if let email = snapshot.accountEmail(for: provider) {
                    Text("Account: \(email)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("No usage data yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Mobile availability badge
            if provider.mobileAvailability != .fullNative {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption2)
                    Text(provider.mobileAvailabilityLabel)
                        .font(.caption2)
                }
                .foregroundStyle(.orange)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct StatusBadge: View {
    let status: ProviderStatusSnapshot

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            if let desc = status.description {
                Text(desc)
                    .font(.caption2)
            }
        }
    }

    private var statusColor: Color {
        switch status.indicator {
        case .none: .green
        case .minor: .yellow
        case .major: .orange
        case .critical: .red
        case .maintenance: .blue
        case .unknown: .gray
        }
    }
}
