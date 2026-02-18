import CodexBarSync
import SwiftUI

struct ProviderUsageView: View {
    let provider: ProviderUsageSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text(provider.providerName)
                    .font(.headline)
                Spacer()
                if provider.isError {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                        .font(.caption)
                }
                Text(provider.lastUpdated.formatted(.relative(presentation: .named)))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            // Account info
            if let email = provider.accountEmail {
                HStack(spacing: 4) {
                    Image(systemName: "person.circle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(email)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let plan = provider.loginMethod {
                        Text("(\(plan))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Usage cards
            if let primary = provider.primary {
                UsageCardView(
                    label: windowLabel(for: primary, fallback: "Session"),
                    window: primary)
            }

            if let secondary = provider.secondary {
                UsageCardView(
                    label: windowLabel(for: secondary, fallback: "Weekly"),
                    window: secondary)
            }

            // Error message
            if let message = provider.statusMessage {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }

    private func windowLabel(for window: SyncRateWindow, fallback: String) -> String {
        guard let minutes = window.windowMinutes else { return fallback }
        if minutes <= 360 {
            return "Session (\(minutes / 60)h)"
        } else if minutes <= 10_080 {
            return "Weekly"
        } else {
            return "Period (\(minutes / 60 / 24)d)"
        }
    }
}
