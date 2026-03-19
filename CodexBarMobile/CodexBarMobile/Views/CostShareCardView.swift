import SwiftUI

private let qrURL = "https://github.com/steipete/CodexBar"
private let cardWidth: CGFloat = 390
private let cardHeight: CGFloat = 520

// MARK: - Main Entry Point

struct CostShareCardView: View {
    let period: SharePeriod
    let data: ShareCardData

    var body: some View {
        switch period {
        case .today: TodayCard(data: data)
        case .week: ChartCard(data: data, periodLabel: String(localized: "7 Days"))
        case .month: ChartCard(data: data, periodLabel: String(localized: "30 Days"))
        }
    }
}

// MARK: - Shared Components

private func formatUSD(_ value: Double) -> String {
    value.formatted(.currency(code: "USD").precision(.fractionLength(2)))
}

private func formatTokens(_ count: Int) -> String {
    if count >= 1_000_000 {
        return String(format: "%.1fM", Double(count) / 1_000_000)
    } else if count >= 1_000 {
        return String(format: "%.0fK", Double(count) / 1_000)
    }
    return "\(count)"
}

private func formatPercent(_ value: Double) -> String {
    String(format: "%.0f%%", value * 100)
}

private struct QRFooter: View {
    var body: some View {
        HStack(spacing: 14) {
            Image(uiImage: QRCodeGenerator.generate(from: qrURL, size: 64))
                .interpolation(.none)
                .resizable()
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            VStack(alignment: .leading, spacing: 3) {
                Text("CodexBar")
                    .font(.subheadline.bold())
                Text(String(localized: "Track your AI coding costs"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("github.com/steipete/CodexBar")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            Spacer()
        }
    }
}

private struct MetricPill: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.bold().monospacedDigit())
        }
    }
}

// MARK: - Stacked Bar (provider-colored segments)

private struct StackedBar: View {
    let providers: [ShareCardData.ProviderRow]
    let totalHeight: CGFloat
    let cornerRadius: CGFloat

    var body: some View {
        // Largest at bottom (stable baseline), smallest at top
        VStack(spacing: 0) {
            ForEach(Array(providers.reversed().enumerated()), id: \.offset) { _, p in
                Rectangle()
                    .fill(p.color)
                    .frame(height: max(0, totalHeight * p.share))
            }
        }
        .frame(height: totalHeight)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

// ────────────────────────────────────────────────────────────────
// MARK: - Today Card (Provider-focused, Style 7 based)
// ────────────────────────────────────────────────────────────────

private struct TodayCard: View {
    let data: ShareCardData

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(String(localized: "AI Coding Spend"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .tracking(1.2)
                    Text(String(localized: "Today"))
                        .font(.title3.bold())
                }
                Spacer()
                Image(systemName: "chart.bar.fill")
                    .font(.title2)
                    .foregroundStyle(.orange)
            }
            .padding(.bottom, 16)

            // Hero number
            Text(formatUSD(data.todayCost))
                .font(.system(size: 42, weight: .bold, design: .rounded).monospacedDigit())
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 2)

            if data.totalTokens > 0 {
                Text("\(formatTokens(data.totalTokens)) tokens")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            Spacer().frame(height: 18)

            // Provider breakdown (top 3 + Others)
            VStack(spacing: 8) {
                ForEach(Array(data.displayProviders.enumerated()), id: \.offset) { _, provider in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(provider.color)
                            .frame(width: 8, height: 8)
                        Text(provider.name)
                            .font(.subheadline)
                        Spacer()
                        Text(formatUSD(provider.cost))
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(.secondary)
                        Text(formatPercent(provider.share))
                            .font(.caption.bold().monospacedDigit())
                            .frame(width: 36, alignment: .trailing)
                    }
                }
            }
            .padding(.bottom, 14)

            // Share bar
            GeometryReader { geo in
                HStack(spacing: 2) {
                    ForEach(Array(data.displayProviders.enumerated()), id: \.offset) { _, p in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(p.color)
                            .frame(width: max(4, geo.size.width * p.share))
                    }
                }
            }
            .frame(height: 8)
            .padding(.bottom, 14)

            // Top models (compact)
            if !data.topModels.isEmpty {
                VStack(alignment: .leading, spacing: 5) {
                    Text(String(localized: "Top Models"))
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    ForEach(Array(data.topModels.prefix(3).enumerated()), id: \.offset) { _, model in
                        HStack {
                            Text(model.label)
                                .font(.caption)
                                .lineLimit(1)
                            Spacer()
                            Text(formatPercent(model.share))
                                .font(.caption.bold().monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(10)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            Spacer()

            Divider().padding(.vertical, 10)
            QRFooter()
        }
        .padding(24)
        .frame(width: cardWidth, height: cardHeight)
        .background(.white)
    }
}

// ────────────────────────────────────────────────────────────────
// MARK: - Chart Card (7-day / 30-day, Style 6 based)
// ────────────────────────────────────────────────────────────────

private struct ChartCard: View {
    let data: ShareCardData
    let periodLabel: String

    private var maxCost: Double {
        data.dailyBars.map(\.cost).max() ?? 1
    }

    private var is30Day: Bool { data.dailyBars.count > 10 }
    private var barHeight: CGFloat { is30Day ? 140 : 150 }

    var body: some View {
        VStack(spacing: 0) {
            // Header — matches Today card style
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(String(localized: "AI Coding Spend"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .tracking(1.2)
                    Text(periodLabel)
                        .font(.title3.bold())
                }
                Spacer()
                Image(systemName: "chart.bar.fill")
                    .font(.title2)
                    .foregroundStyle(.orange)
            }
            .padding(.bottom, 14)

            // Hero number
            Text(formatUSD(data.totalCost))
                .font(.system(size: 42, weight: .bold, design: .rounded).monospacedDigit())
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 12)

            // Chart area — stacked bars by provider color
            VStack(spacing: 0) {
                HStack(alignment: .bottom, spacing: is30Day ? 2 : 6) {
                    ForEach(Array(data.dailyBars.enumerated()), id: \.offset) { _, day in
                        let totalH = max(2, CGFloat(day.cost / maxCost) * barHeight)
                        StackedBar(
                            providers: data.displayProviders,
                            totalHeight: totalH,
                            cornerRadius: is30Day ? 2 : 4
                        )
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: barHeight)
                .padding(.horizontal, is30Day ? 6 : 10)
                .padding(.top, 10)

                // X-axis labels — separate row below bars
                if is30Day {
                    HStack {
                        Text("1")
                        Spacer()
                        Text("10")
                        Spacer()
                        Text("20")
                        Spacer()
                        Text("30")
                    }
                    .font(.system(size: 8))
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 6)
                    .padding(.top, 4)
                    .padding(.bottom, 6)
                } else {
                    HStack(spacing: 6) {
                        ForEach(Array(data.dailyBars.enumerated()), id: \.offset) { _, day in
                            Text(day.label)
                                .font(.system(size: 9))
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.top, 4)
                    .padding(.bottom, 8)
                }
            }
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.bottom, 12)

            // Bottom metrics
            HStack(spacing: 0) {
                MetricPill(
                    title: String(localized: "Tokens"),
                    value: formatTokens(data.totalTokens)
                )
                .frame(maxWidth: .infinity)
                Divider().frame(height: 28)
                if is30Day {
                    MetricPill(
                        title: String(localized: "Active Days"),
                        value: "\(data.activeDays)"
                    )
                    .frame(maxWidth: .infinity)
                    Divider().frame(height: 28)
                }
                MetricPill(
                    title: String(localized: "Avg/Day"),
                    value: formatUSD(data.avgDailyCost)
                )
                .frame(maxWidth: .infinity)
            }
            .padding(.bottom, 8)

            // Provider dots (top 3 + Others)
            HStack(spacing: 8) {
                ForEach(Array(data.displayProviders.enumerated()), id: \.offset) { _, p in
                    HStack(spacing: 3) {
                        Circle().fill(p.color).frame(width: 6, height: 6)
                        Text(p.name)
                            .font(.system(size: 10))
                            .lineLimit(1)
                        Text(formatPercent(p.share))
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }

            Spacer()

            Divider().padding(.vertical, 8)
            QRFooter()
        }
        .padding(24)
        .frame(width: cardWidth, height: cardHeight)
        .background(.white)
    }
}

// MARK: - Previews

#Preview("Today") {
    CostShareCardView(period: .today, data: .previewToday)
}

#Preview("7 Days") {
    CostShareCardView(period: .week, data: .preview7d)
}

#Preview("30 Days") {
    CostShareCardView(period: .month, data: .preview)
}

#Preview("All Periods") {
    ScrollView(.horizontal) {
        HStack(spacing: 16) {
            ForEach(SharePeriod.allCases) { period in
                let data: ShareCardData = switch period {
                case .today: .previewToday
                case .week: .preview7d
                case .month: .preview
                }
                VStack(spacing: 8) {
                    CostShareCardView(period: period, data: data)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
                    Text(period.displayName)
                        .font(.caption.bold())
                }
            }
        }
        .padding()
    }
}
