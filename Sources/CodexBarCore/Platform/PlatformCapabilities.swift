import Foundation

/// Describes the capabilities available on the current platform.
///
/// Mobile devices lack CLI access, browser cookies, and WebKit scraping.
/// This struct is injected into the fetch pipeline so providers can skip
/// unavailable strategies automatically.
public struct PlatformCapabilities: Sendable {
    /// Whether local CLI tools can be executed (PTY/subprocess).
    public let hasCLIAccess: Bool

    /// Whether browser cookies can be imported (SweetCookieKit).
    public let hasBrowserCookies: Bool

    /// Whether offscreen WebKit scraping is available.
    public let hasWebKitScraping: Bool

    /// Whether secure keychain/keystore storage is available.
    public let hasSecureStorage: Bool

    public init(
        hasCLIAccess: Bool,
        hasBrowserCookies: Bool,
        hasWebKitScraping: Bool,
        hasSecureStorage: Bool)
    {
        self.hasCLIAccess = hasCLIAccess
        self.hasBrowserCookies = hasBrowserCookies
        self.hasWebKitScraping = hasWebKitScraping
        self.hasSecureStorage = hasSecureStorage
    }

    /// Capabilities for macOS — full access to all features.
    public static let macOS = PlatformCapabilities(
        hasCLIAccess: true,
        hasBrowserCookies: true,
        hasWebKitScraping: true,
        hasSecureStorage: true)

    /// Capabilities for iOS — no CLI, no browser cookies, no WebKit scraping.
    public static let iOS = PlatformCapabilities(
        hasCLIAccess: false,
        hasBrowserCookies: false,
        hasWebKitScraping: false,
        hasSecureStorage: true)

    /// Capabilities for Android — same restrictions as iOS.
    public static let android = PlatformCapabilities(
        hasCLIAccess: false,
        hasBrowserCookies: false,
        hasWebKitScraping: false,
        hasSecureStorage: true)

    /// Auto-detect capabilities for the current platform.
    public static var current: PlatformCapabilities {
        #if os(macOS)
        return .macOS
        #elseif os(iOS)
        return .iOS
        #else
        return .android
        #endif
    }
}
