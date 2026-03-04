import Foundation

/// Constants for iCloud Key-Value Store sync between Mac and iOS.
public enum CloudSyncConstants {
    /// The key used in NSUbiquitousKeyValueStore for the usage snapshot.
    public static let snapshotKey = "com.codexbar.usage.snapshot"

    /// Maximum allowed payload size for NSUbiquitousKeyValueStore (1 MB).
    public static let maxPayloadBytes = 1_048_576
}
