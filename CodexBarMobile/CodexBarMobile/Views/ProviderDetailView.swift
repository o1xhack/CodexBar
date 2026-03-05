import Charts
import CodexBarSync
import SwiftUI

struct ProviderDetailView: View {
    let provider: ProviderUsageSnapshot

    @State private var selectedDate: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Rate limit cards
                rateLimitSection

                // Cost summary grid
                if let cost = self.provider.costSummary,
                   cost.sessionCostUSD != nil || cost.last30DaysCostUSD != nil
                {
                    costSummarySection(cost)
                }

                // Budget progress
                if let budget = self.provider.budget {
                    BudgetProgressView(budget: budget, tintColor: self.providerColor)
                }

                // Daily chart
                if let cost = self.provider.costSummary, !cost.daily.isEmpty {
                    dailyChartSection(cost.daily)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .navigationTitle(self.provider.providerName)
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Rate Limits

    @ViewBuilder
    private var rateLimitSection: some View {
        let windows = self.provider.allRateWindows
        if !windows.isEmpty {
            VStack(spacing: 12) {
                ForEach(Array(windows.enumerated()), id: \.offset) { index, window in
                    UsageCardView(
                        label: window.label ?? self.defaultLabel(at: index),
                        window: window,
                        tintColor: self.providerColor)
                }
            }
        }
    }

    // MARK: - Cost Summary

    @ViewBuilder
    private func costSummarySection(_ cost: SyncCostSummary) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Cost & Usage")
                .font(.headline)
                .padding(.top, 4)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                if let todayCost = cost.sessionCostUSD {
                    CostMetricCard(
                        title: "Today",
                        value: Self.formatUSD(todayCost),
                        subtitle: cost.sessionTokens.map { Self.formatTokens($0) },
                        tintColor: self.providerColor)
                }
                if let monthCost = cost.last30DaysCostUSD {
                    CostMetricCard(
                        title: "30 Days",
                        value: Self.formatUSD(monthCost),
                        subtitle: cost.last30DaysTokens.map { Self.formatTokens($0) },
                        tintColor: self.providerColor)
                }
            }
        }
    }

    // MARK: - Daily Chart

    @ViewBuilder
    private func dailyChartSection(_ daily: [SyncDailyPoint]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Daily Spend")
                .font(.headline)
                .padding(.top, 4)

            Chart(daily, id: \.dayKey) { point in
                BarMark(
                    x: .value("Date", point.dayKey),
                    y: .value("Cost", point.costUSD))
                    .foregroundStyle(self.providerColor.gradient)
                    .cornerRadius(3)
            }
            .chartXSelection(value: self.$selectedDate)
            .chartXAxis {
                AxisMarks(values: .stride(by: 7)) { _ in
                    AxisGridLine()
                    AxisValueLabel()
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            Text(Self.formatUSD(v))
                                .font(.caption2)
                        }
                    }
                }
            }
            .frame(height: 200)
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            if let selectedDate, let point = daily.first(where: { $0.dayKey == selectedDate }) {
                HStack {
                    Text(point.dayKey)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(Self.formatUSD(point.costUSD))
                        .font(.caption.monospacedDigit())
                        .fontWeight(.medium)
                    Text("· \(Self.formatTokens(point.totalTokens))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 4)
            }
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

    private func defaultLabel(at index: Int) -> String {
        switch index {
        case 0: return "Session"
        case 1: return "Weekly"
        default: return "Limit \(index + 1)"
        }
    }

    static func formatUSD(_ value: Double) -> String {
        String(format: "$%.2f", value)
    }

    static func formatTokens(_ count: Int) -> String {
        if count >= 1_000_000 {
            return String(format: "%.1fM tokens", Double(count) / 1_000_000)
        } else if count >= 1_000 {
            return String(format: "%.1fK tokens", Double(count) / 1_000)
        }
        return "\(count) tokens"
    }
}

// MARK: - Previews

#Preview("With Cost Data") {
    NavigationStack {
        ProviderDetailView(provider: PreviewData.claudeProvider)
    }
}

#Preview("No Cost Data") {
    NavigationStack {
        ProviderDetailView(provider: PreviewData.cursorProvider)
    }
}
