import CodexBarSync
import SwiftUI

struct UsageCardView: View {
    let label: String
    let window: SyncRateWindow
    var tintColor: Color = .blue
    var percentageAccessibilityIdentifier: String?
    @AppStorage(MobileSettingsKeys.showRemainingUsage) private var showRemainingUsage =
        UserDefaults.standard.string(forKey: MobileSettingsKeys.usagePercentDisplayMode) == UsagePercentDisplayMode.remaining.rawValue

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header row
            HStack(alignment: .firstTextBaseline) {
                Text(self.label)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                Text(self.percentageText)
                    .font(.title2.monospacedDigit())
                    .fontWeight(.bold)
                    .foregroundStyle(self.usageColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .modifier(PercentageAccessibilityIdentifierModifier(
                        identifier: self.percentageAccessibilityIdentifier))
            }

            // Progress bar
            ProgressView(value: self.displayMode.progressFraction(for: self.window))
                .tint(self.usageColor)
                .scaleEffect(y: 2, anchor: .center)

            // Reset info
            if let resetsAt = self.window.resetsAt {
                HStack(spacing: 6) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.caption)
                    Text("\(String(localized: "Resets")) \(resetsAt.formatted(.relative(presentation: .named)))")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            } else if let description = self.window.resetDescription {
                HStack(spacing: 6) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.caption)
                    Text(description)
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var percentageText: String {
        self.displayMode.percentageText(for: self.window)
    }

    private var displayMode: UsagePercentDisplayMode {
        self.showRemainingUsage ? .remaining : .used
    }

    private var usageColor: Color {
        if self.window.usedPercent >= 90 {
            return .red
        } else if self.window.usedPercent >= 70 {
            return .orange
        } else {
            return self.tintColor
        }
    }
}

private struct PercentageAccessibilityIdentifierModifier: ViewModifier {
    let identifier: String?

    @ViewBuilder
    func body(content: Content) -> some View {
        if let identifier {
            content.accessibilityIdentifier(identifier)
        } else {
            content
        }
    }
}

// MARK: - Previews

#Preview("Low Usage") {
    UsageCardView(
        label: "Session (5h)",
        window: SyncRateWindow(
            usedPercent: 25,
            windowMinutes: 300,
            resetsAt: Date().addingTimeInterval(3600 * 3),
            resetDescription: nil),
        tintColor: Color(red: 0.82, green: 0.55, blue: 0.28))
    .padding()
}

#Preview("High Usage") {
    UsageCardView(
        label: "Weekly",
        window: SyncRateWindow(
            usedPercent: 92,
            windowMinutes: 10_080,
            resetsAt: Date().addingTimeInterval(3600 * 24),
            resetDescription: nil),
        tintColor: .purple)
    .padding()
}
