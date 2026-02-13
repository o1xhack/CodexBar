import Foundation

/// Cross-platform status indicator for provider health.
///
/// Mirrors the macOS `ProviderStatusIndicator` but available across all platforms.
public enum ProviderStatusLevel: String, Codable, Sendable {
    case none
    case minor
    case major
    case critical
    case maintenance
    case unknown

    public var hasIssue: Bool {
        switch self {
        case .none: false
        default: true
        }
    }

    public var label: String {
        switch self {
        case .none: "Operational"
        case .minor: "Partial outage"
        case .major: "Major outage"
        case .critical: "Critical issue"
        case .maintenance: "Maintenance"
        case .unknown: "Status unknown"
        }
    }
}

/// Cross-platform provider status snapshot.
///
/// Used by the mobile UI to display provider health indicators.
/// On macOS, this is populated from `ProviderStatus`; on mobile,
/// it can come from the status page API or Mac sync.
public struct ProviderStatusSnapshot: Codable, Sendable {
    public let indicator: ProviderStatusLevel
    public let description: String?
    public let updatedAt: Date?

    public init(
        indicator: ProviderStatusLevel,
        description: String?,
        updatedAt: Date?)
    {
        self.indicator = indicator
        self.description = description
        self.updatedAt = updatedAt
    }
}
