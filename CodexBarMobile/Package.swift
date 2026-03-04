// swift-tools-version: 6.0
import PackageDescription

/// Standalone SPM package for the CodexBarMobile iOS app.
///
/// The shared iCloud sync code lives in a local `CodexBarSync` library target
/// referenced from `../Shared/`. Both the iOS app and Mac extensions use this library.
///
/// Note: For a proper iOS .app bundle (signing, entitlements, launch screen),
/// create an Xcode project that depends on this package, or use `xcodegen`.
let package = Package(
    name: "CodexBarMobile",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(name: "CodexBarSync", targets: ["CodexBarSync"]),
    ],
    targets: [
        // Shared sync library (used by both Mac and iOS)
        // Uses symlink: CodexBarMobile/Shared -> ../Shared
        .target(
            name: "CodexBarSync",
            path: "Shared",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
            ]),
        // iOS app target
        .executableTarget(
            name: "CodexBarMobile",
            dependencies: ["CodexBarSync"],
            path: "CodexBarMobile",
            exclude: [
                "Assets.xcassets",
                "CodexBarMobile.entitlements",
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
            ]),
        .testTarget(
            name: "CodexBarMobileTests",
            dependencies: ["CodexBarSync"],
            path: "CodexBarMobileTests"),
    ])
