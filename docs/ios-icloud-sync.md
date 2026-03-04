# iOS + iCloud Sync

## Overview

CodexBarMobile is a companion iOS app that displays LLM usage data synced from the macOS CodexBar app via iCloud Key-Value Storage (`NSUbiquitousKeyValueStore`).

## Architecture

```
Mac: UsageStore → SyncCoordinator → CloudSyncManager.pushSnapshot()
                                          ↓
                              NSUbiquitousKeyValueStore (iCloud)
                                          ↓
iOS: CloudSyncReader → SyncedUsageData → SwiftUI Views
```

### Data Flow

1. **Mac side**: `SyncCoordinator` observes `UsageStore.snapshots` via Swift Observation. On each change, it builds a `SyncedUsageSnapshot` containing all enabled providers' usage data and pushes it to iCloud KVS.

2. **iCloud**: `NSUbiquitousKeyValueStore` automatically syncs the JSON payload between devices signed into the same iCloud account.

3. **iOS side**: `CloudSyncReader` listens for `didChangeExternallyNotification` and updates `SyncedUsageData` (an `@Observable` ViewModel), which drives the SwiftUI views.

## Directory Structure

```
Shared/                         ← Shared between Mac and iOS
├── Models/
│   └── UsageSnapshot.swift     ← SyncRateWindow, ProviderUsageSnapshot, SyncedUsageSnapshot
└── iCloud/
    ├── CloudConstants.swift    ← KVS key, size limits
    └── CloudSyncManager.swift  ← Read/write to NSUbiquitousKeyValueStore

Sources/CodexBar/Sync/          ← Mac-side sync code (part of CodexBar target)
├── SyncCoordinator.swift       ← Observes UsageStore, pushes snapshots
└── SyncModifier.swift          ← SwiftUI modifier for app integration

CodexBarMobile/                 ← iOS app
├── Package.swift               ← SPM package (depends on CodexBarSync)
├── CodexBarMobile/
│   ├── CodexBarMobileApp.swift ← App entry point
│   ├── ContentView.swift       ← Main provider list
│   ├── Views/
│   │   ├── ProviderUsageView.swift  ← Provider usage card
│   │   ├── UsageCardView.swift      ← Progress bar component
│   │   └── EmptyStateView.swift     ← Empty/waiting state
│   ├── iCloud/
│   │   └── CloudSyncReader.swift    ← iCloud observation wrapper
│   ├── Models/
│   │   └── SyncedUsageData.swift    ← @Observable ViewModel
│   └── CodexBarMobile.entitlements  ← iCloud KVS entitlement
└── CodexBarMobileTests/
    └── SyncModelTests.swift    ← Codable round-trip tests
```

## Sync Mechanism

### Why NSUbiquitousKeyValueStore?

- **Data size**: Usage data is a few KB (20 providers x ~200 bytes each). Well under the 1 MB limit.
- **Simplicity**: No CloudKit container setup, no schema, no conflict resolution needed.
- **Automatic**: System handles push/pull transparently.
- **No server**: Zero backend infrastructure required.

### KVS Key

`com.codexbar.usage.snapshot` — single key containing the full JSON payload.

### Payload Format

```json
{
  "providers": [
    {
      "providerID": "claude",
      "providerName": "Claude",
      "primary": {
        "usedPercent": 42.5,
        "windowMinutes": 300,
        "resetsAt": "2024-01-15T10:30:00Z",
        "resetDescription": "Resets in 2h 30m"
      },
      "secondary": { ... },
      "accountEmail": "user@example.com",
      "loginMethod": "Pro",
      "statusMessage": null,
      "isError": false,
      "lastUpdated": "2024-01-15T08:00:00Z"
    }
  ],
  "syncTimestamp": "2024-01-15T08:00:00Z",
  "deviceName": "My MacBook Pro"
}
```

## Mac Integration

### Changes to Existing Files

Two existing files were modified:

1. **`Package.swift`** — Added `CodexBarSync` target (pointing to `Shared/`) and added it as a dependency of `CodexBar`.
2. **`CodexBarApp.swift`** — Added `.modifier(CloudSyncModifier(store: self.store))` to the hidden keepalive window.

The sync files (`SyncCoordinator.swift`, `SyncModifier.swift`) live in `Sources/CodexBar/Sync/` as part of the existing `CodexBar` target.

### Entitlements

Both Mac and iOS apps must use the same KVS identifier:

```xml
<key>com.apple.developer.ubiquity-kvstore-identifier</key>
<string>$(TeamIdentifierPrefix)com.codexbar.shared</string>
```

## iOS App

- **Minimum deployment**: iOS 17.0
- **Features**: Read-only display of synced usage data
- **No configuration**: All provider setup happens on the Mac side

### What iOS does NOT do

- No provider configuration/settings
- No cookie import or OAuth flows
- No CLI integration
- No WidgetKit (future enhancement)
- No data fetching — purely a sync consumer

## Testing

### Unit Tests

```bash
cd CodexBarMobile && swift test
```

Tests cover:
- `ProviderUsageSnapshot` JSON round-trip
- `SyncedUsageSnapshot` JSON round-trip
- `SyncRateWindow.remainingPercent` clamping
- Empty provider list encoding

### Manual Testing

1. Build and run CodexBar on Mac with iCloud entitlements
2. Build and run CodexBarMobile on iPhone/Simulator
3. Verify usage data appears on iOS after Mac refreshes
4. Verify data updates when Mac usage changes

## Future Enhancements

- **WidgetKit**: Home screen widget showing top provider usage
- **CloudKit upgrade**: If data grows beyond KVS limits, migrate to `CKRecord`
- **Push notifications**: `CKSubscription` for real-time alerts when nearing rate limits
