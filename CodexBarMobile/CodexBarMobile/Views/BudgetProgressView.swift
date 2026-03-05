import CodexBarSync
import SwiftUI

struct BudgetProgressView: View {
    let budget: SyncBudgetSnapshot
    var tintColor: Color = .blue

    private var progress: Double {
        guard budget.limitAmount > 0 else { return 0 }
        return min(budget.usedAmount / budget.limitAmount, 1.0)
    }

    private var progressColor: Color {
        if progress >= 0.9 { return .red }
        if progress >= 0.7 { return .orange }
        return tintColor
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Budget")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                Text(self.formattedUsed)
                    .font(.subheadline.monospacedDigit())
                    .fontWeight(.medium)
                Text("/ \(self.formattedLimit)")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: self.progress)
                .tint(self.progressColor)
                .scaleEffect(y: 2, anchor: .center)

            HStack(spacing: 8) {
                if let period = self.budget.period {
                    Text(period)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let resetsAt = self.budget.resetsAt {
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.caption)
                        Text("Resets \(resetsAt.formatted(.relative(presentation: .named)))")
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var formattedUsed: String {
        Self.formatCurrency(self.budget.usedAmount, code: self.budget.currencyCode)
    }

    private var formattedLimit: String {
        Self.formatCurrency(self.budget.limitAmount, code: self.budget.currencyCode)
    }

    static func formatCurrency(_ value: Double, code: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
    }
}

#Preview {
    BudgetProgressView(
        budget: SyncBudgetSnapshot(
            usedAmount: 42.50,
            limitAmount: 100.0,
            currencyCode: "USD",
            period: "Monthly",
            resetsAt: Date().addingTimeInterval(3600 * 24 * 12)),
        tintColor: .orange)
        .padding()
}
