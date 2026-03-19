# CodexBar — Project Overview

CodexBar is a macOS menu bar app that tracks AI coding tool usage (Claude, Codex, Cursor, etc.). It has an iOS companion app that syncs data from Mac via iCloud.

- **We only work on the iOS app.** Mac-side code is maintained upstream — do not modify Mac-only files unless explicitly asked.
- iOS project lives in `CodexBarMobile/`.
- Shared sync layer lives in `CodexBarMobile/Shared/` (used by both Mac and iOS).

## Repositories

| Remote | Repo | Role |
|--------|------|------|
| `upstream` | steipete/CodexBar | Original open-source repo, read only |
| `origin` | o1xhack/CodexBar | Our fork |
| Branch | `mobile-dev` | Main working branch |

## Workflow

**All development follows the 7-step workflow defined in [`AGENTS.md`](AGENTS.md).**

Quick summary:

> Research → Design → Implementation → Testing → Documentation → Commit → Push & Release

See `AGENTS.md` for the full process, rules, and checklists.

## Key File Locations

| Path | Purpose |
|------|---------|
| `AGENTS.md` | Complete development workflow and agent rules |
| `CodexBarMobile/Research/` | Feature research documents ([index](CodexBarMobile/Research/README.md)) |
| `CodexBarMobile/project.yml` | Build number (`CURRENT_PROJECT_VERSION`) and version (`MARKETING_VERSION`) |
| `CodexBarMobile/CHANGELOG.md` | iOS changelog (technical, Keep a Changelog format) |
| `CodexBarMobile/CodexBarMobile/ContentView.swift` | Main views, settings, in-app release notes (`MobileReleaseNotesCatalog`) |
| `CodexBarMobile/CodexBarMobile/Localizable.xcstrings` | All translations (JSON, 4 languages) |
| `CodexBarMobile/CodexBarMobile/Views/` | Feature views (provider detail, usage cards, onboarding) |
| `CodexBarMobile/CodexBarMobile/Models/` | Data models and formatters |
| `CodexBarMobile/CodexBarMobile/Preview Content/PreviewData.swift` | Demo / preview data |
| `CodexBarMobile/Shared/` | Shared iCloud sync layer |
