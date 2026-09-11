import CodexBarSync
import SwiftUI

/// A shared token-only surface. Cost and Usage use the same history worker and reducer.
struct TokenActivitySection: View {
    let providers: [ProviderUsageSnapshot]
    var sourceSnapshots: [SyncedUsageSnapshot] = []
    var isOverview = false
    var isDemoMode = false
    var referenceDate = Date()
    @AppStorage(MobileSettingsKeys.cwlEnabled) private var useLedger = MobileSettingsDefaults.cwlEnabled
    @AppStorage(MobileSettingsKeys.cwlBlobSeedClearedAt) private var clearedAt: Double = 0
    @State private var series: [TokenActivitySeries] = []
    @State private var failed = false
    @State private var loadedScope: String?
    @State private var showsAllProviders = false
    @State private var selectedDate = Calendar.current.startOfDay(for: Date())
    @State private var hasSelection = false
    @ScaledMetric(relativeTo: .caption2) private var calendarLabelHeight: CGFloat = 16

    private var gridHeight: CGFloat {
        166 + 2 * self.calendarLabelHeight
    }

    private var scope: String {
        self.providers
            .map { $0.cardIdentityKey + CostLedgerService.accountIdentityKeys(for: $0).sorted().joined(separator: ",") }
            .joined(separator: "|")
            + "|\(self.useLedger)|\(self.isDemoMode)|\(self.clearedAt)|\(TimeZone.current.identifier)"
            + self.sourceSnapshots.compactMap(\.deviceID).sorted().joined(separator: "|")
    }

    private var refreshKey: String {
        self.scope + self.providers.map { "\($0.lastUpdated.timeIntervalSince1970)" }.joined(separator: "|")
            + self.sourceSnapshots.map { "\($0.deviceID ?? ""):\($0.syncTimestamp.timeIntervalSince1970)" }.joined()
            + TokenActivity.sourceRevision(self.sourceSnapshots)
            + TokenActivity.dayKey(self.referenceDate, calendar: .current)
    }

    private var selectedDay: String? {
        self.hasSelection ? TokenActivity.dayKey(self.selectedDate, calendar: Calendar(identifier: .gregorian)) : nil
    }

    private var daySelection: Binding<String?> {
        Binding(get: { self.selectedDay }, set: { key in
            guard let key else { return }
            let formatter = DateFormatter()
            formatter.calendar = Calendar(identifier: .gregorian)
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = "yyyy-MM-dd"
            guard let date = formatter.date(from: key) else { return }
            self.selectedDate = date
            self.hasSelection = true
        })
    }

    private func title(for item: TokenActivitySeries) -> String {
        if self.series.count(where: { $0.provider.providerID == item.provider.providerID }) > 1,
           let email = item.provider.accountEmail
        {
            return item.provider.providerName + " · " + email
        }
        return item.provider.providerName
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if self.loadedScope == self.scope, !self.series.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text(self
                        .isOverview ? String(localized: "Daily Tokens Overview") : String(localized: "Token Activity"))
                        .font(.headline)
                    Text(String(localized: "Past year · Swipe to explore. Missing history is not zero."))
                        .font(.caption).foregroundStyle(.secondary)
                    let availableTotal = SyncCounterMath.saturatingSum(self.series.flatMap { item in
                        item.days.compactMap { TokenActivity.recordedTokens($0, series: item) }
                    })
                    Text(String(localized: "Recorded tokens") + ": " + availableTotal.formatted())
                        .font(.subheadline.monospacedDigit())
                    ScrollViewReader { proxy in
                        HStack(alignment: .top, spacing: 8) {
                            if self.isOverview {
                                VStack(alignment: .leading, spacing: 16) {
                                    ForEach(self.showsAllProviders ? self
                                        .series : Array(self.series.prefix(2)))
                                    { item in
                                        Text(self.title(for: item))
                                            .font(.caption.bold()).lineLimit(4)
                                            .foregroundStyle(ProviderColorPalette.color(for: item.provider))
                                            .frame(width: 60, height: self.gridHeight, alignment: .topLeading)
                                    }
                                }
                            }
                            ScrollView(.horizontal) {
                                VStack(alignment: .leading, spacing: 16) {
                                    ForEach(self.showsAllProviders ? self
                                        .series : Array(self.series.prefix(2)))
                                    { item in
                                        TokenActivityGrid(
                                            series: item,
                                            referenceDate: self.referenceDate,
                                            selectedDay: self.daySelection)
                                    }
                                }
                                .id("latest")
                            }
                            .defaultScrollAnchor(.trailing)
                        }
                        Button(String(localized: "Back to today")) { proxy.scrollTo("latest", anchor: .trailing) }
                            .font(.caption)
                    }
                    if self.series.count > 2 {
                        Button(self
                            .showsAllProviders ? String(localized: "Show fewer providers") :
                            String(localized: "Show all providers"))
                        {
                            self.showsAllProviders.toggle()
                        }.font(.caption)
                    }
                    Text(String(localized: "Color intensity: <100K · <1M · <10M · 10M+ tokens"))
                        .font(.caption2).foregroundStyle(.secondary)
                    DatePicker(
                        String(localized: "Date"),
                        selection: self.$selectedDate,
                        in: Calendar.current.date(byAdding: .day, value: -364, to: self.referenceDate)!...self
                            .referenceDate,
                        displayedComponents: .date)
                        .accessibilityIdentifier("token-date-picker")
                        .onChange(of: self.selectedDate) { self.hasSelection = true }
                    if let selectedDay {
                        Text(selectedDay).font(.subheadline.bold()).accessibilityIdentifier("selected-token-day")
                        if self.isOverview {
                            let values = self.series.compactMap { item in
                                TokenActivity.recordedTokens(item.days.first { $0.dayKey == selectedDay }, series: item)
                            }
                            Text(String(localized: "Recorded tokens") + ": " + SyncCounterMath.saturatingSum(values)
                                .formatted())
                                .font(.subheadline.monospacedDigit())
                        }
                        ForEach(self.series) { item in
                            HStack {
                                Text(self.title(for: item))
                                Spacer()
                                Text(TokenActivity.tokenText(
                                    item.days.first { $0.dayKey == selectedDay },
                                    series: item))
                                    .monospacedDigit()
                            }.font(.caption)
                        }
                    }
                    if self.failed {
                        Text(String(localized: "Could not refresh token history. Showing the last loaded data."))
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                .padding(16)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
            } else if self.failed {
                Text(String(localized: "Could not load token history. Please try again."))
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .task(id: self.refreshKey) {
            let requestedScope = self.scope
            do {
                let result: [TokenActivitySeries] = if self.useLedger, !self.isDemoMode {
                    try await CostHistoryWorker.shared.tokenActivity(
                        providers: self.providers,
                        sourceSnapshots: self.sourceSnapshots,
                        referenceDate: self.referenceDate)
                } else {
                    try await CostHistoryWorker.shared.snapshotTokenActivity(
                        providers: self.providers, referenceDate: self.referenceDate)
                }
                guard !Task.isCancelled else { return }
                self.series = result
                self.loadedScope = requestedScope
                self.failed = false
            } catch {
                guard !Task.isCancelled else { return }
                self.failed = true
            }
        }
    }
}

private struct TokenActivityGrid: View {
    let series: TokenActivitySeries
    let referenceDate: Date
    @Binding var selectedDay: String?
    @ScaledMetric(relativeTo: .caption2) private var calendarLabelHeight: CGFloat = 16
    private var gridHeight: CGFloat {
        166 + 2 * self.calendarLabelHeight
    }

    private var calendar: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = .current
        c.firstWeekday = 2
        return c
    }

    private var dates: [Date] {
        let today = self.calendar.startOfDay(for: self.referenceDate)
        let start = self.calendar.date(byAdding: .day, value: -364, to: today)!
        let weekStart = self.calendar.dateInterval(of: .weekOfYear, for: start)!.start
        return (0..<371).compactMap { self.calendar.date(byAdding: .day, value: $0, to: weekStart) }
    }

    var body: some View {
        let gridDates = self.dates
        let points = Dictionary(series.days.map { ($0.dayKey, $0) }, uniquingKeysWith: { first, _ in first })
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                ForEach(Array(stride(from: 0, to: gridDates.count, by: 7)), id: \.self) { index in
                    let date = gridDates[index]
                    Text(self.calendar.component(.day, from: date) <= 7 ? date
                        .formatted(.dateTime.month(.abbreviated)) : "")
                        .font(.caption2).fixedSize().frame(
                            width: 18, alignment: index >= gridDates.count - 21 ? .trailing : .leading)
                }
            }
            LazyHGrid(rows: Array(repeating: GridItem(.fixed(18), spacing: 4), count: 7), spacing: 4) {
                ForEach(gridDates, id: \.self) { date in
                    let key = TokenActivity.dayKey(date, calendar: self.calendar)
                    self.cell(key: key, date: date, point: points[key])
                }
            }
            HStack {
                Text(gridDates.first!, format: .dateTime.year().month().day())
                Spacer()
                Text(self.referenceDate, format: .dateTime.year().month().day())
            }.font(.caption2).foregroundStyle(.secondary)
        }
        .frame(height: self.gridHeight, alignment: .top)
    }

    private func cell(key: String, date: Date, point: SyncDailyPoint?) -> some View {
        let count = TokenActivity.recordedTokens(point, series: self.series)
        let future = date > self.calendar.startOfDay(for: self.referenceDate)
        let fill: Color = count.map {
            $0 == 0 ? Color.secondary.opacity(0.1) :
                ProviderColorPalette.color(for: self.series.provider).opacity(TokenActivity.intensity($0))
        } ?? .clear
        let unknown = point?.tokenCountIsKnown == false || count == nil
        let shape = RoundedRectangle(cornerRadius: 3).fill(fill)
            .overlay(RoundedRectangle(cornerRadius: 3).strokeBorder(
                Color.secondary.opacity(unknown ? 0.25 : 0),
                style: StrokeStyle(lineWidth: 1, dash: [2])))
            .overlay(RoundedRectangle(cornerRadius: 3).stroke(
                self.selectedDay == key ? Color.primary : .clear, lineWidth: 2))
            .frame(width: 18, height: 18)
        return shape.opacity(future ? 0 : 1)
            .contentShape(Rectangle())
            .onTapGesture { if !future { self.selectedDay = key } }
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { if !future { self.selectedDay = key } }
            .accessibilityHidden(future)
            .accessibilityIdentifier("token-day-" + key)
            .accessibilityLabel(key + ", " + self.series.provider.providerName + ", " + TokenActivity.tokenText(
                point,
                series: self.series))
    }
}
