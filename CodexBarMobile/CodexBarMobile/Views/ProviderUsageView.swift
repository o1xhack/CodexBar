import CodexBarSync
import SwiftUI

struct ProviderUsageView: View {
    let provider: ProviderUsageSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Provider header
            providerHeader
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 16)

            // Usage metrics
            VStack(spacing: 12) {
                if let primary = self.provider.primary {
                    UsageCardView(
                        label: self.windowLabel(for: primary, fallback: "Session"),
                        window: primary,
                        tintColor: self.providerColor)
                }

                if let secondary = self.provider.secondary {
                    UsageCardView(
                        label: self.windowLabel(for: secondary, fallback: "Weekly"),
                        window: secondary,
                        tintColor: self.providerColor)
                }
            }
            .padding(.horizontal, 16)

            // Error / status message
            if let message = self.provider.statusMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.bubble.fill")
                        .font(.subheadline)
                        .foregroundStyle(.red)
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
            }

            Spacer().frame(height: 20)
        }
        .modifier(ProviderCardBackgroundModifier())
    }

    // MARK: - Provider Header

    @ViewBuilder
    private var providerHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(self.provider.providerName)
                    .font(.title3)
                    .fontWeight(.bold)

                Spacer()

                if self.provider.isError {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                        .font(.subheadline)
                }
            }

            HStack(spacing: 8) {
                if let email = self.provider.accountEmail {
                    HStack(spacing: 4) {
                        Image(systemName: "person.circle.fill")
                            .font(.caption)
                        Text(email)
                            .font(.subheadline)
                    }
                    .foregroundStyle(.secondary)
                }

                if let plan = self.provider.loginMethod {
                    Text(plan)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(.quaternary, in: Capsule())
                }
            }

            Text(self.provider.lastUpdated.formatted(.relative(presentation: .named)))
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }

    // MARK: - Helpers

    private var providerColor: Color {
        let id = self.provider.providerID.lowercased()
        if id.contains("claude") || id.contains("anthropic") {
            return Color(red: 0.82, green: 0.55, blue: 0.28)
        } else if id.contains("codex") || id.contains("cursor") {
            return .purple
        } else if id.contains("openai") || id.contains("chatgpt") {
            return .green
        } else if id.contains("openrouter") {
            return Color(red: 0.42, green: 0.35, blue: 0.83)
        } else {
            return .blue
        }
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

/// iOS 26: Liquid Glass card. Older: regular material rounded rect.
private struct ProviderCardBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        } else {
            content
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }
}

// MARK: - Previews

#Preview("Claude") {
    ScrollView {
        ProviderUsageView(provider: PreviewData.claudeProvider)
            .padding()
    }
}

#Preview("OpenRouter (Error)") {
    ScrollView {
        ProviderUsageView(provider: PreviewData.openRouterProvider)
            .padding()
    }
}
