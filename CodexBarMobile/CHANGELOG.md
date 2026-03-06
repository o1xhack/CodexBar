# Changelog — CodexBar Mobile (iOS)

All notable changes to the CodexBar iOS companion app will be documented in this file.

## [1.0.0] — Unreleased

### Added
- iOS companion app for CodexBar with iCloud Key-Value Store sync
- Provider list with dynamic rate limit progress bars and labels (Session, Weekly, Sonnet, etc.)
- Tappable provider cards with cost teaser line ("Today: $X.XX · 30d: $Y.YY")
- Provider detail view with interactive daily spend bar chart (SwiftUI Charts)
- Cost summary grid (session cost, 30-day cost, token counts)
- Budget progress bar with color-coded thresholds (red >90%, orange >70%)
- iCloud sync error display (quota exceeded, account change notifications)
- iOS 26 Liquid Glass UI support (glass effect cards, soft scroll edges, tab bar minimize)
- Demo mode for previewing the app without Mac data
- About tab with sync status, developer info, and open source credits
- Display Mac app version and Sync version from iCloud payload in About tab
- Empty state views for waiting-for-sync and no-providers states
