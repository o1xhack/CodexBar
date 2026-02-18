import Foundation

/// A single rate-limit window snapshot for iCloud sync.
public struct SyncRateWindow: Codable, Sendable, Equatable {
    public let usedPercent: Double
    public let windowMinutes: Int?
    public let resetsAt: Date?
    public let resetDescription: String?

    public var remainingPercent: Double {
        max(0, 100 - usedPercent)
    }

    public init(
        usedPercent: Double,
        windowMinutes: Int?,
        resetsAt: Date?,
        resetDescription: String?)
    {
        self.usedPercent = usedPercent
        self.windowMinutes = windowMinutes
        self.resetsAt = resetsAt
        self.resetDescription = resetDescription
    }
}

/// A single provider's usage snapshot for iCloud sync.
public struct ProviderUsageSnapshot: Codable, Sendable, Equatable {
    public let providerID: String
    public let providerName: String
    public let primary: SyncRateWindow?
    public let secondary: SyncRateWindow?
    public let accountEmail: String?
    public let loginMethod: String?
    public let statusMessage: String?
    public let isError: Bool
    public let lastUpdated: Date

    public init(
        providerID: String,
        providerName: String,
        primary: SyncRateWindow?,
        secondary: SyncRateWindow?,
        accountEmail: String?,
        loginMethod: String?,
        statusMessage: String?,
        isError: Bool,
        lastUpdated: Date)
    {
        self.providerID = providerID
        self.providerName = providerName
        self.primary = primary
        self.secondary = secondary
        self.accountEmail = accountEmail
        self.loginMethod = loginMethod
        self.statusMessage = statusMessage
        self.isError = isError
        self.lastUpdated = lastUpdated
    }
}

/// Full sync payload pushed from Mac to iOS via iCloud.
public struct SyncedUsageSnapshot: Codable, Sendable, Equatable {
    public let providers: [ProviderUsageSnapshot]
    public let syncTimestamp: Date
    public let deviceName: String

    public init(
        providers: [ProviderUsageSnapshot],
        syncTimestamp: Date,
        deviceName: String)
    {
        self.providers = providers
        self.syncTimestamp = syncTimestamp
        self.deviceName = deviceName
    }
}
