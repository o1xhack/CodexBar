# Changelog — CodexBar Mobile (iOS)

All notable changes to the CodexBar iOS companion app will be documented in this file.

## [1.0.0 (21)] — 2026-03-20

### Added
- Vibe (cyberpunk) share card style with arc gauges, neon glow, and "Did you vibe today?" headlines
- Style picker in share sheet: Classic / Vibe
- Dark and light theme support for both Classic and Vibe styles
- Save to Photos option in share sheet (NSPhotoLibraryAddUsageDescription)
- QR code and link updated to codexbarios.o1xhack.com

### Changed
- Share card headlines forced to single line across all 4 languages (minimumScaleFactor)
- In-app release notes now merge updates within the same marketing version
- AGENTS.md Step 5 updated with release notes merge rule

### Fixed
- Share sheet not showing "Save Image" option due to ShareLink Transferable limitation

## [1.0.0 (15)] — 2026-03-20

### Added
- One-tap share button on Cost tab to generate shareable cost report images
- Share sheet with period picker (Today / 7 Days / 30 Days) and live card preview
- Three share card styles: today (provider breakdown), 7-day and 30-day (stacked bar chart)
- Stacked bar chart colored by provider (top 3 + "Others" for 4+ providers)
- QR code footer linking to CodexBar project
- Feature research framework under Research/ with status tracking (draft → done → dropped)
- Research doc 001: Daily Utilization Chart (blocked-upstream, PR #565)
- Research doc 002: Cost Share Card (done)

### Changed
- CLAUDE.md simplified to project overview; AGENTS.md now holds complete 7-step workflow
- Share card charts follow dataviz conventions (largest segment at bottom for stable baseline)

## [1.0.0 (13)] — 2026-03-19

### Changed
- Refined in-app release note: replaced screenshot coverage note with clearer label readability improvement

## [1.0.0 (12)] — 2026-03-19

### Fixed
- In-app release notes now preserve the original 1.0.0 launch notes while prepending the latest build updates

## [1.0.0 (11)] — 2026-03-19

### Changed
- Usage percentage labels now keep a larger, fixed layout instead of scaling down under pressure
- Cost overview cards and trailing metrics in Cost lists now use adaptive fixed-width layouts for crisper numbers

### Fixed
- Blurry `% used` and `% left` labels on provider usage cards
- Soft or blurry trailing amount/share text in Provider Share and Model Mix rows

## [1.0.0 (10)] — 2026-03-18

### Changed
- Daily spend chart now scrolls horizontally, showing 30 days at a time with swipe for history
- Consolidated release notes into "What's New" and "Improvements & Fixes" sections
- Updated CLAUDE.md with jj workflow and commit automation rules
- Enriched demo data to 50 days with realistic spend curves

## [1.0.0 (9)] — 2026-03-17

Initial App Store release line, corresponding to the earlier Mobile `0.1.0` build.

### Added
- iOS companion app for CodexBar with iCloud Key-Value Store sync
- Provider list with dynamic rate limit progress bars and labels (Session, Weekly, Sonnet, etc.)
- Tappable provider cards with cost teaser line ("Today: $X.XX · 30d: $Y.YY")
- Provider detail view with interactive daily spend bar chart (SwiftUI Charts)
- Cost summary grid (session cost, 30-day cost, token counts)
- Budget progress bar with color-coded thresholds (red >90%, orange >70%)
- "Show remaining usage" toggle in Settings to display quota left instead of quota used
- iCloud sync error display (quota exceeded, account change notifications)
- iOS 26 Liquid Glass UI support (glass effect cards, soft scroll edges, tab bar minimize)
- Demo mode for previewing the app without Mac data
- About tab with sync status, developer info, and open source credits
- Display Mac app version and Sync version from iCloud payload in About tab
- Empty state views for waiting-for-sync and no-providers states
- Cost tab with provider share, model/service mix, and 30-day spend analysis
- In-app release notes page with the latest update summary and collapsible version history
- Privacy manifest, privacy policy, and dark mode app icon
- Onboarding flow, setup guide, and pull-to-refresh support
- Native localization for English, Simplified Chinese, Traditional Chinese, and Japanese

### Changed
- Usage and Cost charts support both Bar Chart and Line Chart styles
- 30-day charts support press-and-hold inspection for exact daily values
- Daily spend chart now scrolls horizontally, showing 30 days at a time with swipe to view history
- Chart Y-axis uses smart integer tick marks for cleaner readability
- Setting tab reorganized into Usage, Charts, and Privacy sections
- Mobile versioning is now aligned directly with the iOS app version number
- Dynamic version display now surfaces synced iPhone and Mac versions more clearly

### Fixed
- Pull to refresh now asks iCloud Key-Value Store to synchronize before reading the latest snapshot
- Mac sync status now reports missing iCloud entitlements or unavailable iCloud accounts instead of showing a false success state
- Fix iCloud sync entitlement check on iOS
