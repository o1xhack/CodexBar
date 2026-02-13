import CodexBarCore
import Foundation
import Observation

/// Central observable state for the mobile app.
///
/// Mirrors the macOS `UsageStore` but adapted for mobile:
/// - No menu bar rendering
/// - Uses `UsageDataSource` protocol for future Mac sync support
/// - Filters providers by `PlatformCapabilities`
@Observable
public final class MobileUsageStore: @unchecked Sendable {
    public var selectedTab: MobileTab = .dashboard
    public var enabledProviders: [UsageProvider] = []
    public var snapshots: [UsageProvider: UsageSnapshot] = [:]
    public var statuses: [UsageProvider: ProviderStatusSnapshot] = [:]
    public var isRefreshing: Bool = false
    public var lastRefresh: Date?

    // Settings
    public var refreshIntervalSeconds: TimeInterval = 60
    public var showDesktopOnlyProviders: Bool = false

    private let dataSource: any UsageDataSource
    private let capabilities: PlatformCapabilities

    public init(
        dataSource: any UsageDataSource = DirectFetchDataSource(),
        capabilities: PlatformCapabilities = .current)
    {
        self.dataSource = dataSource
        self.capabilities = capabilities
        self.enabledProviders = Self.defaultEnabledProviders(capabilities: capabilities)
    }

    /// Returns providers that are available on the current platform.
    public var availableProviders: [UsageProvider] {
        if showDesktopOnlyProviders {
            return UsageProvider.allCases.map { $0 }
        }
        return UsageProvider.allCases.filter { provider in
            provider.mobileAvailability != .desktopOnly
        }
    }

    /// Refresh usage data for all enabled providers.
    public func refresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer {
            isRefreshing = false
            lastRefresh = Date()
        }

        let newSnapshots = await dataSource.fetchSnapshots(for: enabledProviders)
        let newStatuses = await dataSource.fetchStatuses(for: enabledProviders)

        for (provider, snapshot) in newSnapshots {
            snapshots[provider] = snapshot
        }
        for (provider, status) in newStatuses {
            statuses[provider] = status
        }
    }

    private static func defaultEnabledProviders(
        capabilities: PlatformCapabilities) -> [UsageProvider]
    {
        // On mobile, only enable providers with native support by default
        if !capabilities.hasCLIAccess {
            return UsageProvider.allCases.filter { provider in
                provider.mobileAvailability == .fullNative
            }
        }
        // On macOS, enable the primary providers
        return [.claude, .codex]
    }
}
