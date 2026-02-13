import Foundation

/// Describes a provider's availability level on mobile platforms.
///
/// Used by the mobile UI to show appropriate badges and status indicators
/// for providers that have limited or no native mobile support.
public enum MobileProviderAvailability: Sendable {
    /// Full native support on mobile (OAuth/API-based providers).
    case fullNative

    /// Partial support — some fetch strategies are desktop-only.
    case limitedNative

    /// Requires desktop — all fetch strategies need CLI/cookies/WebKit.
    case desktopOnly

    /// Data available via Mac sync (future feature).
    case syncedFromMac
}

extension UsageProvider {
    /// Returns the mobile availability level for this provider.
    public var mobileAvailability: MobileProviderAvailability {
        switch self {
        // Providers with full OAuth/API support
        case .claude, .codex, .copilot, .gemini, .minimax,
             .kimi, .kimik2, .zai, .warp, .vertexai, .synthetic:
            return .fullNative

        // Providers with partial support (some strategies desktop-only)
        case .cursor, .amp:
            return .limitedNative

        // Providers that primarily rely on CLI/cookies/local storage
        case .factory, .jetbrains, .augment, .opencode, .kiro, .antigravity:
            return .desktopOnly
        }
    }

    /// Human-readable label for the mobile availability status.
    public var mobileAvailabilityLabel: String {
        switch self.mobileAvailability {
        case .fullNative:
            return "Full Support"
        case .limitedNative:
            return "Partial Support"
        case .desktopOnly:
            return "Desktop Only"
        case .syncedFromMac:
            return "Synced from Mac"
        }
    }
}
