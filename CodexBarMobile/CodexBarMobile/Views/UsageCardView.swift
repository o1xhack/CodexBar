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
                self.percentageLabel
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
        .padding(.horizontal, 4)
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var percentageLabel: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(self.displayMode.percentageValueText(for: self.window))
                    .font(.title2.monospacedDigit())
                    .fontWeight(.bold)

                Text(self.displayMode.percentSuffix)
                    .font(.title3)
                    .fontWeight(.bold)
            }
            .foregroundColor(self.usageColor)
            .fixedSize(horizontal: true, vertical: false)

            Text(self.displayMode.percentageText(for: self.window))
                .font(.title3.monospacedDigit())
                .fontWeight(.bold)
                .foregroundColor(self.usageColor)
                .fixedSize(horizontal: true, vertical: false)
        }
        .layoutPriority(1)
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
