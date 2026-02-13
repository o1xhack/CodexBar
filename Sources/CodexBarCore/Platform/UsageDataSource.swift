import Foundation

/// Abstraction for how usage data is fetched on mobile platforms.
///
/// This protocol enables future Mac-to-mobile sync by allowing the
/// mobile app to swap between direct API fetching and receiving
/// synced data from a paired Mac.
public protocol UsageDataSource: Sendable {
    /// Fetch the latest usage snapshots for all enabled providers.
    func fetchSnapshots(
        for providers: [UsageProvider]) async -> [UsageProvider: UsageSnapshot]

    /// Fetch provider status (incidents, etc.).
    func fetchStatuses(
        for providers: [UsageProvider]) async -> [UsageProvider: ProviderStatusSnapshot]
}

/// Direct fetching via HTTP APIs and OAuth — the default mobile data source.
public struct DirectFetchDataSource: UsageDataSource {
    public init() {}

    public func fetchSnapshots(
        for providers: [UsageProvider]) async -> [UsageProvider: UsageSnapshot]
    {
        // Implementation will delegate to individual provider fetch strategies
        // filtered by PlatformCapabilities.current
        [:]
    }

    public func fetchStatuses(
        for providers: [UsageProvider]) async -> [UsageProvider: ProviderStatusSnapshot]
    {
        [:]
    }
}
