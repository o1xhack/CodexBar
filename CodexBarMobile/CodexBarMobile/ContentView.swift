import Charts
import CodexBarSync
import SwiftUI

enum CostChartStyle: String, CaseIterable, Identifiable {
    case bars
    case line

    var id: String {
        self.rawValue
    }

    var title: String {
        switch self {
        case .bars:
            String(localized: "Bar Chart")
        case .line:
            String(localized: "Line Chart")
        }
    }
}

private enum MobileRootTab: Hashable {
    case usage
    case cost
    case settings
}

struct ContentView: View {
    let usageData: SyncedUsageData
    @State private var isDemoMode = false
    @State private var selectedTab: MobileRootTab
    @AppStorage("onboardingSeenVersion") private var onboardingSeenVersion = ""

    init(usageData: SyncedUsageData) {
        self.usageData = usageData
        _selectedTab = State(initialValue: UserDefaults.standard.bool(forKey: MobileSettingsKeys.openCostByDefault) ? .cost : .usage)
    }

    private var currentVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
    }

    private var shouldShowOnboarding: Bool {
        self.onboardingSeenVersion != self.currentVersion
    }

    var body: some View {
        TabView(selection: self.$selectedTab) {
            UsageTab(usageData: self.usageData, isDemoMode: self.$isDemoMode)
                .tag(MobileRootTab.usage)
                .tabItem {
                    Label("Usage", systemImage: "chart.bar.fill")
                }

            CostTab(usageData: self.usageData, isDemoMode: self.$isDemoMode)
                .tag(MobileRootTab.cost)
                .tabItem {
                    Label("Cost", systemImage: "dollarsign.circle.fill")
                }

            SettingsTab(usageData: self.usageData)
                .tag(MobileRootTab.settings)
                .tabItem {
                    Label("Setting", systemImage: "gearshape")
                }
        }
        .modifier(TabBarMinimizeModifier())
        .fullScreenCover(isPresented: .init(
            get: { self.shouldShowOnboarding },
            set: { if !$0 { self.onboardingSeenVersion = self.currentVersion } }))
        {
            OnboardingSheet(onDismiss: {
                self.onboardingSeenVersion = self.currentVersion
            }, onDemo: {
                self.onboardingSeenVersion = self.currentVersion
                self.isDemoMode = true
            })
        }
    }
}

private struct OnboardingSheet: View {
    let onDismiss: () -> Void
    let onDemo: () -> Void

    var body: some View {
        NavigationStack {
            OnboardingView(onDemo: self.onDemo)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") {
                            self.onDismiss()
                        }
                        .fontWeight(.semibold)
                    }
                }
        }
    }
}

/// Applies `.tabBarMinimizeBehavior(.onScrollDown)` on iOS 26+, no-op on older systems.
private struct TabBarMinimizeModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content.tabBarMinimizeBehavior(.onScrollDown)
        } else {
            content
        }
    }
}

// MARK: - Usage Tab

private struct UsageTab: View {
    let usageData: SyncedUsageData
    @Binding var isDemoMode: Bool

    private var displaySnapshot: SyncedUsageSnapshot? {
        if self.isDemoMode {
            return PreviewData.sampleSnapshot
        }
        return self.usageData.snapshot
    }

    var body: some View {
        NavigationStack {
            Group {
                if let snapshot = self.displaySnapshot {
                    if snapshot.providers.isEmpty {
                        EmptyStateView(
                            title: "No Providers Enabled",
                            message: "Enable providers in CodexBar on your Mac to see usage data here.",
                            systemImage: "slider.horizontal.3")
                    } else {
                        ProviderListView(
                            snapshot: snapshot,
                            usageData: self.usageData,
                            isDemoMode: self.isDemoMode)
                    }
                } else {
                    OnboardingView(onDemo: { self.isDemoMode = true })
                }
            }
            .navigationTitle(self.isDemoMode ? String(localized: "CodexBar (Demo)") : String(localized: "CodexBar"))
            .toolbar {
                if self.isDemoMode {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            self.isDemoMode = false
                        } label: {
                            Text("Exit Demo")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Provider List

private struct ProviderListView: View {
    let snapshot: SyncedUsageSnapshot
    let usageData: SyncedUsageData
    let isDemoMode: Bool

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(self.snapshot.providers, id: \.providerID) { provider in
                    NavigationLink {
                        ProviderDetailView(provider: provider)
                    } label: {
                        ProviderUsageView(provider: provider)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("provider-card-\(provider.providerID)")
                }

                // Sync status at scroll bottom
                if self.isDemoMode {
                    Label("Showing demo data", systemImage: "sparkles")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                } else {
                    SyncStatusBar(usageData: self.usageData)
                        .padding(.top, 4)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .refreshable {
            self.usageData.refresh()
        }
        .modifier(SoftScrollEdgeModifier())
    }
}

/// Applies `.scrollEdgeEffectStyle(.soft)` on iOS 26+, no-op on older systems.
private struct SoftScrollEdgeModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content.scrollEdgeEffectStyle(.soft, for: .top)
        } else {
            content
        }
    }
}

// MARK: - Sync Status Bar

private struct SyncStatusBar: View {
    let usageData: SyncedUsageData

    var body: some View {
        VStack(spacing: 4) {
            if let error = self.usageData.lastSyncError {
                HStack(spacing: 5) {
                    Image(systemName: "exclamationmark.icloud.fill")
                        .font(.caption2)
                        .foregroundStyle(.red)
                    Text(error)
                        .font(.caption2)
                        .foregroundStyle(.red)
                }
            }

            if let snapshot = self.usageData.snapshot {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(snapshot.syncTimestamp.formatted(.relative(presentation: .named)))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("·")
                        .foregroundStyle(.quaternary)
                    Image(systemName: "laptopcomputer")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    Text(snapshot.deviceName)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }

                Text("Data pushed by Mac · Pull to check for updates")
                    .font(.caption2)
                    .foregroundStyle(.quaternary)
            }
        }
    }
}

// MARK: - Cost Tab

private struct CostTab: View {
    let usageData: SyncedUsageData
    @Binding var isDemoMode: Bool

    private var displaySnapshot: SyncedUsageSnapshot? {
        if self.isDemoMode {
            return PreviewData.sampleSnapshot
        }
        return self.usageData.snapshot
    }

    var body: some View {
        NavigationStack {
            Group {
                if let snapshot = self.displaySnapshot {
                    let insights = CostDashboardInsights(snapshot: snapshot)
                    if insights.hasDisplayData {
                        CostDashboardView(
                            insights: insights,
                            usageData: self.usageData,
                            isDemoMode: self.isDemoMode)
                    } else {
                        EmptyStateView(
                            title: "No Cost Data Yet",
                            message: "Enable cost collection in CodexBar on your Mac to see provider spend, breakdowns, and budgets here.",
                            systemImage: "dollarsign.gauge.chart.lefthalf.righthalf")
                    }
                } else {
                    OnboardingView(onDemo: { self.isDemoMode = true })
                }
            }
            .navigationTitle(self.isDemoMode ? String(localized: "Cost (Demo)") : String(localized: "Cost"))
            .toolbar {
                if self.isDemoMode {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            self.isDemoMode = false
                        } label: {
                            Text("Exit Demo")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                    }
                }
            }
        }
    }
}

private struct CostDashboardView: View {
    let insights: CostDashboardInsights
    let usageData: SyncedUsageData
    let isDemoMode: Bool
    @AppStorage(MobileSettingsKeys.dashboardCostChartStyle) private var chartStyleRawValue = CostChartStyle.line
        .rawValue
    @State private var selectedDay: Date?

    private var chartStyle: CostChartStyle {
        CostChartStyle(rawValue: self.chartStyleRawValue) ?? .line
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                self.summarySection

                if !self.insights.providerRows.isEmpty {
                    self.contributionSection(
                        title: "Provider Share",
                        subtitle: "30-day spend contribution across synced providers.",
                        rows: self.insights.providerRows.map {
                            CostBreakdownRow(
                                label: $0.provider.providerName,
                                amountUSD: $0.thirtyDayCost,
                                subtitle: self.providerSubtitle(for: $0),
                                color: providerTint(for: $0.provider))
                        },
                        total: self.insights.total30DayCost)
                }

                if !self.insights.dailyPoints.isEmpty {
                    self.trendSection
                }

                if !self.insights.modelRows.isEmpty {
                    self.contributionSection(
                        title: "Model Mix",
                        subtitle: "Top cost drivers across providers that expose model-level billing.",
                        rows: self.insights.modelRows,
                        total: self.insights.modelRows.reduce(0) { $0 + $1.amountUSD })
                }

                if !self.insights.serviceRows.isEmpty {
                    self.contributionSection(
                        title: "Codex Service Mix",
                        subtitle: "Breakdown from Codex Cloud dashboard data, including Codex Run and other billable services.",
                        rows: self.insights.serviceRows,
                        total: self.insights.serviceRows.reduce(0) { $0 + $1.amountUSD })
                }

                if !self.insights.budgetRows.isEmpty {
                    self.budgetSection
                }

                if self.isDemoMode {
                    Label("Showing demo data", systemImage: "sparkles")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                        .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    SyncStatusBar(usageData: self.usageData)
                        .padding(.top, 4)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .refreshable {
            self.usageData.refresh()
        }
        .modifier(SoftScrollEdgeModifier())
    }

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Overview")
                .font(.headline)
                .padding(.top, 4)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                CostMetricCard(
                    title: "30 Days",
                    value: Self.formatUSD(self.insights.total30DayCost),
                    subtitle: self.insights.total30DayTokens > 0 ? Self
                        .formatTokens(self.insights.total30DayTokens) : nil,
                    tintColor: .orange)

                CostMetricCard(
                    title: "Today",
                    value: Self.formatUSD(self.insights.totalTodayCost),
                    subtitle: self.providersActiveSubtitle,
                    tintColor: .mint)

                CostMetricCard(
                    title: "Top Driver",
                    value: Self.formatUSD(self.insights.topProvider?.thirtyDayCost ?? 0),
                    subtitle: self.topDriverSubtitle,
                    tintColor: providerTint(for: self.insights.topProvider?.provider))

                CostMetricCard(
                    title: "Active Days",
                    value: "\(self.insights.activeDayCount)",
                    subtitle: self.activeDaySubtitle,
                    tintColor: .blue)
            }
        }
    }

    private var trendSection: some View {
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
            .accessibilityIdentifier("cost-dashboard-daily-spend-title")

            Chart(self.insights.dailyPoints) { point in
                switch self.chartStyle {
                case .bars:
                    BarMark(
                        x: .value(String(localized: "Date"), point.date),
                        y: .value(String(localized: "Cost"), point.costUSD))
                        .foregroundStyle(Color.orange.gradient)
                        .cornerRadius(4)
                case .line:
                    AreaMark(
                        x: .value(String(localized: "Date"), point.date),
                        y: .value(String(localized: "Cost"), point.costUSD))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.orange.opacity(0.35), Color.orange.opacity(0.04)],
                                startPoint: .top,
                                endPoint: .bottom))
                        .interpolationMethod(.catmullRom)

                    LineMark(
                        x: .value(String(localized: "Date"), point.date),
                        y: .value(String(localized: "Cost"), point.costUSD))
                        .foregroundStyle(Color.orange)
                        .lineStyle(.init(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                        .interpolationMethod(.catmullRom)
                }

                if let selectedPoint = self.selectedPoint, selectedPoint.id == point.id {
                    RuleMark(x: .value(String(localized: "Selected Date"), selectedPoint.date))
                        .foregroundStyle(Color.orange.opacity(0.35))
                        .lineStyle(.init(lineWidth: 1, dash: [4, 4]))

                    PointMark(
                        x: .value(String(localized: "Selected Date"), selectedPoint.date),
                        y: .value(String(localized: "Selected Cost"), selectedPoint.costUSD))
                        .foregroundStyle(Color.orange)
                        .symbolSize(80)
                }
            }
            .chartXSelection(value: self.$selectedDay)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                }
            }
            .chartYAxis {
                AxisMarks(values: MobileChartAxisFormatter.axisValues(for: self.insights.dailyPoints.map(\.costUSD))) {
                    value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            Text(MobileChartAxisFormatter.axisLabel(for: v))
                                .font(.caption2)
                        }
                    }
                }
            }
            .frame(height: 220)
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))

            if let selectedPoint = self.selectedPoint {
                HStack {
                    Text(Self.shortDate(selectedPoint.date))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(Self.formatUSD(selectedPoint.costUSD))
                        .font(.caption.monospacedDigit())
                        .fontWeight(.medium)
                    if selectedPoint.totalTokens > 0 {
                        Text("· \(Self.formatTokens(selectedPoint.totalTokens))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 4)
            } else {
                HStack(spacing: 12) {
                    Label(
                        "\(String(localized: "Peak")) \(Self.formatUSD(self.insights.highestDay?.costUSD ?? 0))",
                        systemImage: "arrow.up.right.circle.fill")
                    Label(
                        self.insights.highestDay.map { Self.shortDate($0.date) } ?? String(localized: "No data"),
                        systemImage: "calendar")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
    }

    private func contributionSection(
        title: LocalizedStringResource,
        subtitle: LocalizedStringResource,
        rows: [CostBreakdownRow],
        total: Double) -> some View
    {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .padding(.top, 4)

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)

            VStack(spacing: 12) {
                ForEach(Array(rows.prefix(6))) { row in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            Circle()
                                .fill(row.color)
                                .frame(width: 10, height: 10)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(row.label)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                if let subtitle = row.subtitle {
                                    Text(subtitle)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 2) {
                                Text(Self.formatUSD(row.amountUSD))
                                    .font(.subheadline.monospacedDigit())
                                    .fontWeight(.semibold)
                                Text(Self.formatShare(row.amountUSD, total: total))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        ProgressView(value: Self.safeRatio(row.amountUSD, total: total))
                            .tint(row.color)
                            .scaleEffect(y: 1.8, anchor: .center)
                    }
                    .padding(14)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
        }
    }

    private var budgetSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Budgets")
                .font(.headline)
                .padding(.top, 4)

            Text("Tracked provider budgets and how close they are to their current limit.")
                .font(.caption)
                .foregroundStyle(.secondary)

            VStack(spacing: 12) {
                ForEach(self.insights.budgetRows) { row in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(row.provider.providerName)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Spacer()
                            if let method = row.provider.loginMethod {
                                Text(method)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        BudgetProgressView(
                            budget: row.budget,
                            tintColor: providerTint(for: row.provider))
                    }
                }
            }
        }
    }

    private func providerSubtitle(for row: CostDashboardInsights.ProviderRow) -> String {
        let today = row.todayCost > 0
            ? "\(String(localized: "Today")) \(Self.formatUSD(row.todayCost))"
            : String(localized: "No spend today")
        let tokens = row.thirtyDayTokens > 0 ? Self.formatTokens(row.thirtyDayTokens) : String(localized: "No token data")
        return "\(today) · \(tokens)"
    }

    private var topDriverSubtitle: String? {
        guard let topProvider = self.insights.topProvider else { return nil }
        return "\(topProvider.provider.providerName) · \(Self.formatShare(topProvider.thirtyDayCost, total: self.insights.total30DayCost))"
    }

    private var activeDaySubtitle: String? {
        guard self.insights.activeDayCount > 0 else { return nil }
        let average = self.insights.total30DayCost / Double(self.insights.activeDayCount)
        return "\(String(localized: "Avg")) \(Self.formatUSD(average)) \(String(localized: "per active day"))"
    }

    private var providersActiveSubtitle: String {
        "\(self.insights.providerRows.count(where: { $0.todayCost > 0 }).formatted()) \(String(localized: "providers active"))"
    }

    private var selectedPoint: CostDashboardInsights.DailyPoint? {
        guard let selectedDay else { return nil }
        return self.insights.dailyPoints.first(where: {
            Calendar.current.isDate($0.date, inSameDayAs: selectedDay)
        })
    }

    private static func safeRatio(_ value: Double, total: Double) -> Double {
        guard total > 0 else { return 0 }
        return min(max(value / total, 0), 1)
    }

    private static func formatShare(_ value: Double, total: Double) -> String {
        guard total > 0 else { return "0%" }
        return String(format: "%.0f%%", (value / total) * 100)
    }

    private static func formatUSD(_ value: Double) -> String {
        value.formatted(.currency(code: "USD").precision(.fractionLength(2)))
    }

    private static func formatTokens(_ count: Int) -> String {
        if count >= 1_000_000 {
            return "\(Self.formatCompactNumber(Double(count) / 1_000_000)) \(String(localized: "M tokens"))"
        } else if count >= 1000 {
            return "\(Self.formatCompactNumber(Double(count) / 1000)) \(String(localized: "K tokens"))"
        }
        return "\(count.formatted()) \(String(localized: "tokens"))"
    }

    private static func shortDate(_ value: Date) -> String {
        value.formatted(.dateTime.month(.abbreviated).day())
    }

    private static func formatCompactNumber(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(1)))
    }
}

struct CostDashboardInsights {
    struct ProviderRow: Identifiable {
        let provider: ProviderUsageSnapshot
        let thirtyDayCost: Double
        let todayCost: Double
        let thirtyDayTokens: Int

        var id: String {
            self.provider.providerID
        }
    }

    struct DailyPoint: Identifiable {
        let dayKey: String
        let date: Date
        let costUSD: Double
        let totalTokens: Int

        var id: String {
            self.dayKey
        }
    }

    let providerRows: [ProviderRow]
    let dailyPoints: [DailyPoint]
    let modelRows: [CostBreakdownRow]
    let serviceRows: [CostBreakdownRow]
    let budgetRows: [CostBudgetRow]

    var total30DayCost: Double {
        self.providerRows.reduce(0) { $0 + $1.thirtyDayCost }
    }

    var totalTodayCost: Double {
        self.providerRows.reduce(0) { $0 + $1.todayCost }
    }

    var total30DayTokens: Int {
        self.providerRows.reduce(0) { $0 + $1.thirtyDayTokens }
    }

    var topProvider: ProviderRow? {
        self.providerRows.max { $0.thirtyDayCost < $1.thirtyDayCost }
    }

    var highestDay: DailyPoint? {
        self.dailyPoints.max { $0.costUSD < $1.costUSD }
    }

    var activeDayCount: Int {
        self.dailyPoints.count(where: { $0.costUSD > 0 })
    }

    var hasDisplayData: Bool {
        !self.providerRows.isEmpty || !self.dailyPoints.isEmpty || !self.budgetRows.isEmpty
    }

    init(snapshot: SyncedUsageSnapshot) {
        let todayKey = Self.dayKeyFormatter.string(from: Date())
        var providerRows: [ProviderRow] = []
        var dailyTotals: [String: (costUSD: Double, totalTokens: Int)] = [:]
        var modelTotals: [String: Double] = [:]
        var serviceTotals: [String: Double] = [:]
        var budgetRows: [CostBudgetRow] = []

        for provider in snapshot.providers {
            if let budget = provider.budget {
                budgetRows.append(CostBudgetRow(provider: provider, budget: budget))
            }

            guard let costSummary = provider.costSummary else { continue }

            let thirtyDayCost = costSummary.last30DaysCostUSD
                ?? costSummary.daily.reduce(0) { $0 + $1.costUSD }
            let thirtyDayTokens = costSummary.last30DaysTokens
                ?? costSummary.daily.reduce(0) { $0 + $1.totalTokens }

            let todayPoint = costSummary.daily.first(where: { $0.dayKey == todayKey })
            let todayCost = todayPoint?.costUSD ?? costSummary.sessionCostUSD ?? 0

            guard thirtyDayCost > 0 || todayCost > 0 || !costSummary.daily.isEmpty else { continue }

            providerRows.append(
                ProviderRow(
                    provider: provider,
                    thirtyDayCost: thirtyDayCost,
                    todayCost: todayCost,
                    thirtyDayTokens: thirtyDayTokens))

            for point in costSummary.daily {
                dailyTotals[point.dayKey, default: (0, 0)].costUSD += point.costUSD
                dailyTotals[point.dayKey, default: (0, 0)].totalTokens += point.totalTokens

                for breakdown in point.modelBreakdowns where breakdown.costUSD > 0 {
                    modelTotals[breakdown.label, default: 0] += breakdown.costUSD
                }

                for breakdown in point.serviceBreakdowns where breakdown.costUSD > 0 {
                    serviceTotals[breakdown.label, default: 0] += breakdown.costUSD
                }
            }
        }

        self.providerRows = providerRows.sorted { lhs, rhs in
            if lhs.thirtyDayCost == rhs.thirtyDayCost {
                return lhs.provider.providerName
                    .localizedCaseInsensitiveCompare(rhs.provider.providerName) == .orderedAscending
            }
            return lhs.thirtyDayCost > rhs.thirtyDayCost
        }

        self.dailyPoints = dailyTotals.keys.compactMap { dayKey in
            guard let date = Self.dayKeyFormatter.date(from: dayKey),
                  let totals = dailyTotals[dayKey] else { return nil }
            return DailyPoint(dayKey: dayKey, date: date, costUSD: totals.costUSD, totalTokens: totals.totalTokens)
        }
        .sorted { $0.date < $1.date }

        self.modelRows = Self.breakdownRows(from: modelTotals, palette: .model)
        self.serviceRows = Self.breakdownRows(from: serviceTotals, palette: .service)
        self.budgetRows = budgetRows.sorted { lhs, rhs in
            let lhsRatio = lhs.budget.limitAmount > 0 ? lhs.budget.usedAmount / lhs.budget.limitAmount : 0
            let rhsRatio = rhs.budget.limitAmount > 0 ? rhs.budget.usedAmount / rhs.budget.limitAmount : 0
            return lhsRatio > rhsRatio
        }
    }

    private static func breakdownRows(from totals: [String: Double], palette: BreakdownPalette) -> [CostBreakdownRow] {
        totals
            .filter { $0.value > 0 }
            .map { label, amount in
                CostBreakdownRow(
                    label: label,
                    amountUSD: amount,
                    subtitle: nil,
                    color: palette.color(for: label))
            }
            .sorted { lhs, rhs in
                if lhs.amountUSD == rhs.amountUSD {
                    return lhs.label.localizedCaseInsensitiveCompare(rhs.label) == .orderedAscending
                }
                return lhs.amountUSD > rhs.amountUSD
            }
    }

    private static let dayKeyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

struct CostBreakdownRow: Identifiable {
    let label: String
    let amountUSD: Double
    let subtitle: String?
    let color: Color

    var id: String {
        self.label
    }
}

struct CostBudgetRow: Identifiable {
    let provider: ProviderUsageSnapshot
    let budget: SyncBudgetSnapshot

    var id: String {
        self.provider.providerID
    }
}

private enum BreakdownPalette {
    case model
    case service

    func color(for label: String) -> Color {
        let seed = label.lowercased().unicodeScalars.reduce(0) { partialResult, scalar in
            partialResult + Int(scalar.value)
        }
        let hueBase = switch self {
        case .model: 0.08
        case .service: 0.52
        }
        let hue = (hueBase + (Double(seed % 21) / 100)).truncatingRemainder(dividingBy: 1)
        let saturation = 0.62 + Double(seed % 7) * 0.03
        let brightness = 0.78 + Double(seed % 5) * 0.03
        return Color(hue: hue, saturation: min(saturation, 0.95), brightness: min(brightness, 0.98))
    }
}

private func providerTint(for provider: ProviderUsageSnapshot?) -> Color {
    let id = provider?.providerID.lowercased() ?? ""
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

// MARK: - Setting Tab

private struct SettingsTab: View {
    let usageData: SyncedUsageData
    @State private var showingSetupGuide = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        AboutSyncDetailView(usageData: self.usageData)
                    } label: {
                        SettingSummaryRow(
                            title: "About & Sync",
                            symbolName: "iphone.and.arrow.forward",
                            summary: "\(String(localized: "iPhone")) \(self.mobileVersionSummary) · \(String(localized: "Mac")) \(self.macVersionSummary)")
                    }

                    NavigationLink {
                        ReleaseNotesView()
                    } label: {
                        SettingSummaryRow(
                            title: "Release Notes",
                            symbolName: "text.document",
                            summary: String(localized: "Latest updates and version history"))
                    }
                }

                Section {
                    NavigationLink {
                        UsageSettingsView()
                    } label: {
                        SettingSummaryRow(
                            title: "Usage Setting",
                            symbolName: "chart.bar.fill",
                            summary: String(localized: "Configure the Usage page"))
                    }

                    NavigationLink {
                        CostSettingsView()
                    } label: {
                        SettingSummaryRow(
                            title: "Cost Setting",
                            symbolName: "dollarsign.circle.fill",
                            summary: String(localized: "Configure the Cost page"))
                    }
                }

                Section("How It Works") {
                    Label("CodexBar on your Mac pushes usage data to iCloud", systemImage: "laptopcomputer")
                    Label("This app reads the latest snapshot via iCloud Key-Value Store", systemImage: "icloud")
                    Label(
                        "Data syncs automatically when both devices are online",
                        systemImage: "arrow.triangle.2.circlepath")

                    Button {
                        self.showingSetupGuide = true
                    } label: {
                        Label("Show Setup Guide", systemImage: "questionmark.circle")
                    }
                }

                Section("Developer") {
                    Link(destination: URL(string: "https://x.com/o1xhack")!) {
                        Label {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Yuxiao")
                                    .fontWeight(.medium)
                                Text("@o1xhack on X")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "person.fill")
                        }
                    }
                }

                Section("Open Source") {
                    Link(destination: URL(string: "https://github.com/o1xhack/CodexBar")!) {
                        Label {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("o1xhack/CodexBar")
                                    .fontWeight(.medium)
                                Text("Install the Mac app from this repo")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "chevron.left.forwardslash.chevron.right")
                        }
                    }

                    Link(destination: URL(string: "https://github.com/steipete/CodexBar")!) {
                        Label {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("steipete/CodexBar")
                                    .fontWeight(.medium)
                                Text("Original Mac app — MIT License")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "arrow.triangle.branch")
                        }
                    }
                }
            }
            .contentMargins(.top, 12, for: .scrollContent)
            .navigationTitle("Setting")
            .sheet(isPresented: self.$showingSetupGuide) {
                NavigationStack {
                    OnboardingView()
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("Done") {
                                    self.showingSetupGuide = false
                                }
                                .fontWeight(.semibold)
                            }
                        }
                }
            }
        }
    }

    private var mobileVersionSummary: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
        return version
    }

    private var macVersionSummary: String {
        guard let snapshot = self.usageData.snapshot else { return String(localized: "Not synced") }
        return snapshot.appVersion ?? String(localized: "Unknown")
    }
}

private struct SettingSummaryRow: View {
    let title: LocalizedStringResource
    let symbolName: String
    let summary: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: self.symbolName)
                .font(.title3)
                .foregroundStyle(.tint)
                .frame(width: 24, height: 24)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(self.title)
                    .font(.body)
                    .fontWeight(.semibold)

                Text(self.summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct AboutSyncDetailView: View {
    let usageData: SyncedUsageData

    private var appDisplayVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(version) (\(build))"
    }

    var body: some View {
        List {
            Section("Versions") {
                LabeledContent("iPhone App", value: self.appDisplayVersion)
                if let snapshot = self.usageData.snapshot {
                    LabeledContent("Mac App", value: snapshot.appVersion ?? String(localized: "Unknown"))
                    if let mobileVersion = snapshot.mobileVersion {
                        LabeledContent("Synced Mobile Version", value: mobileVersion)
                    }
                } else {
                    LabeledContent("Mac App", value: String(localized: "Not synced"))
                }
            }

            Section("Sync") {
                if let snapshot = self.usageData.snapshot {
                    LabeledContent(
                        "Last Sync",
                        value: snapshot.syncTimestamp.formatted(date: .abbreviated, time: .shortened))
                    LabeledContent("Source Device", value: snapshot.deviceName)
                    LabeledContent("Providers", value: "\(snapshot.providers.count)")
                } else {
                    Text("Not yet synced")
                        .foregroundStyle(.secondary)
                }
            }

            Section("How It Works") {
                Label("CodexBar on your Mac pushes usage data to iCloud", systemImage: "laptopcomputer")
                Label("This app reads the latest snapshot via iCloud Key-Value Store", systemImage: "icloud")
                Label(
                    "Data syncs automatically when both devices are online",
                    systemImage: "arrow.triangle.2.circlepath")
            }
        }
        .navigationTitle("About & Sync")
    }
}

private struct ReleaseNotesVersion: Identifiable {
    struct Section: Identifiable {
        let title: String
        let items: [String]

        var id: String {
            self.title
        }
    }

    let version: String
    let status: String
    let summary: String
    let sections: [Section]

    var id: String {
        self.version
    }
}

private enum MobileReleaseNotesCatalog {
    static let versions: [ReleaseNotesVersion] = [
        ReleaseNotesVersion(
            version: "1.0.0",
            status: String(localized: "Latest"),
            summary: String(localized: "Initial App Store release line, mapped from the earlier Mobile 0.1.0 build."),
            sections: [
                .init(
                    title: String(localized: "Added"),
                    items: [
                        String(localized: "The first iPhone companion app for CodexBar with iCloud Key-Value Store sync from Mac."),
                        String(localized: "A dedicated Cost tab with provider share, model mix, service mix, and 30-day spend analysis."),
                        String(localized: "An in-app Release Notes page that shows the latest update first and keeps older versions collapsed below."),
                        String(localized: "Native localization for English, Simplified Chinese, Traditional Chinese, and Japanese that follows both system language and the per-app language setting on iPhone."),
                        String(localized: "Setup guidance, pull-to-refresh support, and the App Store privacy additions needed for distribution."),
                        String(localized: "Provider cards with usage windows, budget progress, sync status, and detail screens."),
                        String(localized: "Liquid Glass styling, demo mode, About information, and Mac version display."),
                    ]),
                .init(
                    title: String(localized: "Improved"),
                    items: [
                        String(localized: "Usage and Cost charts now support both Bar Chart and Line Chart display styles."),
                        String(localized: "Press-and-hold chart inspection now surfaces exact daily values directly on the graph."),
                        String(localized: "Settings are reorganized into About & Sync, Release Notes, Usage Setting, and Cost Setting."),
                        String(localized: "Mobile version naming is now aligned directly with the iOS app version number."),
                    ]),
                .init(
                    title: String(localized: "Fixed"),
                    items: [
                        String(localized: "Mac sync status now reports missing iCloud entitlements or unavailable iCloud accounts instead of showing a false success state."),
                        String(localized: "Pull to refresh now asks iCloud Key-Value Store to synchronize before reading the latest snapshot."),
                    ]),
            ]),
    ]
}

private struct ReleaseNotesView: View {
    private let versions = MobileReleaseNotesCatalog.versions

    private var latestVersion: ReleaseNotesVersion? {
        self.versions.first
    }

    private var historicalVersions: ArraySlice<ReleaseNotesVersion> {
        self.versions.dropFirst()
    }

    var body: some View {
        List {
            if let latestVersion = self.latestVersion {
                Section("Latest") {
                    ReleaseNotesCard(version: latestVersion)
                }
            }

            Section("History") {
                if self.historicalVersions.isEmpty {
                    Text("Older iOS release notes will appear here as new versions ship.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(self.historicalVersions)) { version in
                        DisclosureGroup {
                            ReleaseNotesContent(version: version)
                                .padding(.top, 8)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 8) {
                    Text("\(String(localized: "Version")) \(version.version)")
                                        .fontWeight(.semibold)
                                    ReleaseNotesBadge(title: version.status)
                                }

                                Text(version.summary)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
        }
        .navigationTitle("Release Notes")
    }
}

private struct ReleaseNotesCard: View {
    let version: ReleaseNotesVersion

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(String(localized: "Version")) \(self.version.version)")
                        .font(.headline)
                    Text(self.version.summary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 12)

                ReleaseNotesBadge(title: self.version.status)
            }

            ReleaseNotesContent(version: self.version)
        }
        .padding(.vertical, 8)
    }
}

private struct ReleaseNotesContent: View {
    let version: ReleaseNotesVersion

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(self.version.sections) { section in
                VStack(alignment: .leading, spacing: 8) {
                    Text(section.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(section.items, id: \.self) { item in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 5))
                                    .foregroundStyle(.secondary)
                                    .padding(.top, 7)

                                Text(item)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
    }
}

private struct ReleaseNotesBadge: View {
    let title: String

    var body: some View {
        Text(self.title)
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundStyle(.tint)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.tint.opacity(0.12), in: Capsule())
    }
}

private struct UsageSettingsView: View {
    @AppStorage(MobileSettingsKeys.usageCostChartStyle) private var usageCostChartStyleRawValue = CostChartStyle.bars
        .rawValue
    @AppStorage(MobileSettingsKeys.showRemainingUsage) private var showRemainingUsage =
        UserDefaults.standard.string(forKey: MobileSettingsKeys.usagePercentDisplayMode) == UsagePercentDisplayMode.remaining.rawValue
    @AppStorage(MobileSettingsKeys.hidePersonalInfo) private var hidePersonalInfo = false

    var body: some View {
        List {
            Section {
                Toggle("Show remaining usage", isOn: self.$showRemainingUsage)
                    .toggleStyle(.switch)
                    .font(.body)
                    .fontWeight(.medium)
                    .accessibilityIdentifier("show-remaining-usage-toggle")
            } header: {
                Text("Usage")
            } footer: {
                Text("Display the quota you have left instead of the quota you have used on usage cards.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                Picker("Chart Style", selection: self.usageChartStyle) {
                    ForEach(CostChartStyle.allCases) { style in
                        Text(style.title).tag(style)
                    }
                }
                .pickerStyle(.menu)
            } header: {
                Text("Charts")
            } footer: {
                Text("Press and hold on the chart to inspect the exact value for a given day.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section {
                Toggle(isOn: self.$hidePersonalInfo) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Hide personal information")
                        Text("Obscure email addresses in the Usage page.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Privacy")
            }
        }
        .navigationTitle("Usage Setting")
        .listStyle(.insetGrouped)
    }

    private var usageChartStyle: Binding<CostChartStyle> {
        Binding(
            get: { CostChartStyle(rawValue: self.usageCostChartStyleRawValue) ?? .bars },
            set: { self.usageCostChartStyleRawValue = $0.rawValue })
    }
}

private struct CostSettingsView: View {
    @AppStorage(MobileSettingsKeys.dashboardCostChartStyle) private var dashboardCostChartStyleRawValue =
        CostChartStyle.line.rawValue
    @AppStorage(MobileSettingsKeys.openCostByDefault) private var openCostByDefault = false

    var body: some View {
        List {
            Section("Charts") {
                Picker("Chart Style", selection: self.dashboardChartStyle) {
                    ForEach(CostChartStyle.allCases) { style in
                        Text(style.title).tag(style)
                    }
                }
                .pickerStyle(.menu)
            }

            Section {
                Toggle(isOn: self.$openCostByDefault) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Open Cost by default")
                        Text("Launch the app on the Cost tab next time.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section {
                Text("Press and hold on the chart to inspect the exact value for a given day.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Cost Setting")
    }

    private var dashboardChartStyle: Binding<CostChartStyle> {
        Binding(
            get: { CostChartStyle(rawValue: self.dashboardCostChartStyleRawValue) ?? .line },
            set: { self.dashboardCostChartStyleRawValue = $0.rawValue })
    }
}

// MARK: - Previews

#Preview("With Data") {
    ContentView(usageData: PreviewData.makeSyncedUsageData())
}

#Preview("Empty State") {
    ContentView(usageData: PreviewData.makeEmptyUsageData())
}
