import Foundation

extension UsageProvider {
    /// Convenience accessor for the provider's display name.
    public var displayName: String {
        ProviderDefaults.metadata[self]?.displayName ?? self.rawValue.capitalized
    }
}
