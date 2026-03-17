import SwiftUI

struct CostMetricCard: View {
    let title: LocalizedStringResource
    let value: String
    let subtitle: String?
    var tintColor: Color = .secondary

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(self.title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(self.value)
                .font(.title2.monospacedDigit())
                .fontWeight(.bold)
                .foregroundStyle(self.tintColor)

            if let subtitle {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

#Preview {
    HStack {
        CostMetricCard(title: "Today", value: "$1.42", subtitle: "12,340 tokens", tintColor: .orange)
        CostMetricCard(title: "30 Days", value: "$28.90", subtitle: "1.2M tokens", tintColor: .blue)
    }
    .padding()
}
