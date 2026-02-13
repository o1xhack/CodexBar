import CodexBarCore
import SwiftUI

/// A single usage bar row showing label, progress bar, and reset time.
/// Mirrors the macOS menu bar usage display.
struct UsageBarRow: View {
    let label: String
    let window: RateWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(usageText)
                    .font(.subheadline.monospacedDigit())
            }

            ProgressView(value: clampedUsage)
                .tint(usageColor)

            if let resetText {
                Text(resetText)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private var clampedUsage: Double {
        min(max(window.usedPercent / 100.0, 0), 1)
    }

    private var usageText: String {
        let remaining = max(0, 100 - window.usedPercent)
        return String(format: "%.0f%% remaining", remaining)
    }

    private var usageColor: Color {
        let used = window.usedPercent
        if used >= 90 { return .red }
        if used >= 70 { return .orange }
        return .accentColor
    }

    private var resetText: String? {
        guard let resetsAt = window.resetsAt else { return nil }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return "Resets \(formatter.localizedString(for: resetsAt, relativeTo: Date()))"
    }
}
