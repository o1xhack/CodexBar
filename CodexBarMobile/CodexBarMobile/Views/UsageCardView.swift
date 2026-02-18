import CodexBarSync
import SwiftUI

struct UsageCardView: View {
    let label: String
    let window: SyncRateWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(window.usedPercent))% used")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(usageColor)
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.quaternary)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(usageColor.gradient)
                        .frame(width: geometry.size.width * min(window.usedPercent / 100, 1))
                }
            }
            .frame(height: 8)

            // Reset info
            if let resetsAt = window.resetsAt {
                HStack(spacing: 4) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.caption2)
                    Text("Resets \(resetsAt.formatted(.relative(presentation: .named)))")
                        .font(.caption2)
                }
                .foregroundStyle(.secondary)
            } else if let description = window.resetDescription {
                HStack(spacing: 4) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.caption2)
                    Text(description)
                        .font(.caption2)
                }
                .foregroundStyle(.secondary)
            }
        }
        .padding(10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    private var usageColor: Color {
        if window.usedPercent >= 90 {
            return .red
        } else if window.usedPercent >= 70 {
            return .orange
        } else {
            return .green
        }
    }
}
