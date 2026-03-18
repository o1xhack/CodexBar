import Charts
import CodexBarSync
import SwiftUI

struct ProviderDetailView: View {
    let provider: ProviderUsageSnapshot

    @AppStorage(MobileSettingsKeys.usageCostChartStyle) private var chartStyleRawValue = CostChartStyle.bars.rawValue
    @State private var selectedDate: String?

    private var chartStyle: CostChartStyle {
        CostChartStyle(rawValue: self.chartStyleRawValue) ?? .bars
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Rate limit cards
                self.rateLimitSection

                // Cost summary grid
                if let cost = self.provider.costSummary,
                   cost.sessionCostUSD != nil || cost.last30DaysCostUSD != nil
                {
                    self.costSummarySection(cost)
                }

                // Budget progress
                if let budget = self.provider.budget {
                    BudgetProgressView(budget: budget, tintColor: self.providerColor)
                }

                // Daily chart
                if let cost = self.provider.costSummary, !cost.daily.isEmpty {
                    self.dailyChartSection(cost.daily)
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
                        tintColor: self.providerColor,
                        percentageAccessibilityIdentifier: "provider-detail-percent-\(self.provider.providerID)-\(index)")
                }
            }
        }
    }

    // MARK: - Cost Summary

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

    private func dailyChartSection(_ daily: [SyncDailyPoint]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Text("Daily Spend")
                    .font(.headline)
                Text("(USD)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 4)
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("provider-daily-spend-title")

            Chart(daily, id: \.dayKey) { point in
                switch self.chartStyle {
                case .bars:
                    BarMark(
                        x: .value(String(localized: "Date"), point.dayKey),
                        y: .value(String(localized: "Cost"), point.costUSD))
                        .foregroundStyle(self.providerColor.gradient)
                        .cornerRadius(3)
                case .line:
                    AreaMark(
                        x: .value(String(localized: "Date"), point.dayKey),
                        y: .value(String(localized: "Cost"), point.costUSD))
                        .foregroundStyle(self.providerColor.opacity(0.16))
                        .interpolationMethod(.catmullRom)

                    LineMark(
                        x: .value(String(localized: "Date"), point.dayKey),
                        y: .value(String(localized: "Cost"), point.costUSD))
                        .foregroundStyle(self.providerColor)
                        .lineStyle(.init(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                        .interpolationMethod(.catmullRom)
                }

                if self.selectedDate == point.dayKey {
                    RuleMark(x: .value(String(localized: "Selected Date"), point.dayKey))
                        .foregroundStyle(self.providerColor.opacity(0.3))
                        .lineStyle(.init(lineWidth: 1, dash: [4, 4]))

                    PointMark(
                        x: .value(String(localized: "Selected Date"), point.dayKey),
                        y: .value(String(localized: "Selected Cost"), point.costUSD))
                        .foregroundStyle(self.providerColor)
                        .symbolSize(80)
                }
            }
            .chartXSelection(value: self.$selectedDate)
            .chartXAxis {
                AxisMarks(values: .stride(by: 7)) { _ in
                    AxisGridLine()
                    AxisValueLabel()
                }
            }
            .chartYAxis {
                AxisMarks(values: MobileChartAxisFormatter.axisValues(for: daily.map(\.costUSD))) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            Text(MobileChartAxisFormatter.axisLabel(for: v))
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
        case 0: String(localized: "Session")
        case 1: String(localized: "Weekly")
        default: "\(String(localized: "Limit")) \(index + 1)"
        }
    }

    static func formatUSD(_ value: Double) -> String {
        value.formatted(.currency(code: "USD").precision(.fractionLength(2)))
    }

    static func formatTokens(_ count: Int) -> String {
        if count >= 1_000_000 {
            return "\(Self.formatCompactNumber(Double(count) / 1_000_000)) \(String(localized: "M tokens"))"
        } else if count >= 1000 {
            return "\(Self.formatCompactNumber(Double(count) / 1000)) \(String(localized: "K tokens"))"
        }
        return "\(count.formatted()) \(String(localized: "tokens"))"
    }

    private static func formatCompactNumber(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(1)))
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
