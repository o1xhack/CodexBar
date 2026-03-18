import CodexBarSync
import SwiftUI

struct ProviderUsageView: View {
    let provider: ProviderUsageSnapshot
    @AppStorage(MobileSettingsKeys.hidePersonalInfo) private var hidePersonalInfo = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Provider header
            providerHeader
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 16)

            // Usage metrics — dynamic count per provider
            VStack(spacing: 10) {
                ForEach(Array(self.provider.allRateWindows.enumerated()), id: \.offset) { index, window in
                    UsageCardView(
                        label: window.label ?? self.defaultLabel(at: index),
                        window: window,
                        tintColor: self.providerColor,
                        percentageAccessibilityIdentifier: "usage-card-percent-\(self.provider.providerID)-\(index)")
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

            // Cost teaser + tap chevron
            HStack {
                if let cost = self.provider.costSummary {
                    self.costTeaserText(cost)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)

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
                        Text(MobilePersonalInfoRedactor.redactEmail(email, isEnabled: self.hidePersonalInfo))
                            .font(.subheadline)
                    }
                    .foregroundStyle(.secondary)
                }

                if let plan = self.provider.loginMethod {
                    Text(MobilePersonalInfoRedactor.redactEmails(in: plan, isEnabled: self.hidePersonalInfo) ?? plan)
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

    @ViewBuilder
    private func costTeaserText(_ cost: SyncCostSummary) -> some View {
        let parts: [String] = [
            cost.sessionCostUSD.map { "\(String(localized: "Today")): \(Self.formatUSD($0))" },
            cost.last30DaysCostUSD.map { "\(String(localized: "30d")): \(Self.formatUSD($0))" },
        ].compactMap { $0 }

        if !parts.isEmpty {
            Text(parts.joined(separator: " · "))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func defaultLabel(at index: Int) -> String {
        switch index {
        case 0: return String(localized: "Session")
        case 1: return String(localized: "Weekly")
        default: return "\(String(localized: "Limit")) \(index + 1)"
        }
    }

    private static func formatUSD(_ value: Double) -> String {
        value.formatted(.currency(code: "USD").precision(.fractionLength(2)))
    }
}

private enum MobilePersonalInfoRedactor {
    private static var emailPlaceholder: String {
        String(localized: "Hidden")
    }

    private static let emailRegex: NSRegularExpression? = {
        let pattern = #"[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}"#
        return try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
    }()

    static func redactEmail(_ email: String?, isEnabled: Bool) -> String {
        guard let email, !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return "" }
        guard isEnabled else { return email }
        return Self.emailPlaceholder
    }

    static func redactEmails(in text: String?, isEnabled: Bool) -> String? {
        guard let text else { return nil }
        guard isEnabled else { return text }
        guard let regex = Self.emailRegex else { return text }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex.stringByReplacingMatches(
            in: text,
            options: [],
            range: range,
            withTemplate: Self.emailPlaceholder)
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
