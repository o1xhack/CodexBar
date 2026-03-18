# CodexBar — AI Agent Workflow

This file is the single source of truth for any AI agent (Claude Code, GPT, Codex, MiniMax, etc.) working on this project.

## Project Overview

CodexBar is a macOS menu bar app that tracks AI coding tool usage (Claude, Codex, Cursor, etc.). It has an iOS companion app that syncs data from Mac via iCloud.

- **We only work on the iOS app.** All Mac-side code is maintained upstream — do not modify Mac-only files unless explicitly asked.
- iOS project lives in `CodexBarMobile/`.
- Shared sync layer lives in `CodexBarMobile/Shared/` (used by both Mac and iOS).

## Version Control — jj (Jujutsu)

We use **jj** colocated with git. Do NOT use raw git commands for commits.

- Main working branch: `mobile-dev`
- `upstream` remote → original open-source repo (steipete/CodexBar), read only.
- `origin` remote → our fork (o1xhack/CodexBar).

### Common commands

```bash
jj status                          # working copy changes
jj log --limit 10                  # recent history
jj describe -m "message"           # set change description
jj new                             # start a new change
jj bookmark set mobile-dev -r @    # point bookmark to current change
jj git push --bookmark mobile-dev  # push to origin
```

## Commit Workflow

When the user says **"提交"** (commit) or **"提交推送"** (commit and push), follow this sequence:

### 1. Bump Build Number

- Open `CodexBarMobile/project.yml`
- Find all `CURRENT_PROJECT_VERSION` values and increment by 1 (e.g. `"9"` → `"10"`)
- Do NOT change `MARKETING_VERSION` unless explicitly asked (that's the user-facing version like `1.0.0`)

### 2. Update CHANGELOG.md

- Open `CodexBarMobile/CHANGELOG.md`
- Under the current version heading, add entries for what changed in this commit
- Follow Keep a Changelog format (Added / Changed / Fixed)

### 3. Commit with jj

```bash
jj describe -m "commit message here"
```

### 4. Push (only if user said "提交推送")

```bash
jj bookmark set mobile-dev -r @
jj git push --bookmark mobile-dev
```

### Version number format

- `MARKETING_VERSION` = user-facing version, e.g. `1.0.0` (only changes on feature releases)
- `CURRENT_PROJECT_VERSION` = build number, e.g. `9` (increments on every commit)
- Displayed as: **1.0.0 (9)**

## Localization — Mandatory 4-Language Rule

**Every user-facing text change MUST include all 4 languages. No exceptions.**

Languages: English (`en`), Simplified Chinese (`zh-Hans`), Traditional Chinese (`zh-Hant`), Japanese (`ja`).

### How localization works

- Source language is English.
- All strings use `String(localized:)` in Swift code — the key is the English text itself.
- Translations live in `CodexBarMobile/CodexBarMobile/Localizable.xcstrings` (JSON format).
- Every entry must have all 4 translations with `"state": "translated"`.

### What counts as user-facing text

- UI labels, buttons, titles, descriptions, footers, placeholders
- Error messages and alerts shown to the user
- Release notes in `MobileReleaseNotesCatalog` (in `ContentView.swift`)
- Onboarding text, empty state messages, accessibility labels with visible text

### What does NOT need translation

- Code comments, log messages, debug strings
- Accessibility identifiers (e.g. `accessibilityIdentifier("some-id")`)
- Keys, enum raw values, format specifiers

### Workflow when adding/changing text

1. Write the English string in code using `String(localized: "Your English text")`
2. Open `Localizable.xcstrings` and add an entry with all 4 translations:
   ```json
   "Your English text" : {
     "localizations" : {
       "en" : { "stringUnit" : { "state" : "translated", "value" : "Your English text" } },
       "ja" : { "stringUnit" : { "state" : "translated", "value" : "日本語テキスト" } },
       "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "简体中文文本" } },
       "zh-Hant" : { "stringUnit" : { "state" : "translated", "value" : "繁體中文文本" } }
     }
   }
   ```
3. If you are unsure about a translation, provide your best attempt and flag it in the commit message.

### Self-check before finishing

- [ ] Every new `String(localized:)` has a matching entry in `Localizable.xcstrings`
- [ ] Every entry has all 4 languages with `"state": "translated"`
- [ ] No `"state": "new"` or missing language keys left behind

## Release Notes

There are two places for release notes, serving different audiences:

| File | Audience | Style |
|------|----------|-------|
| `CodexBarMobile/CHANGELOG.md` | Developers, App Review | Technical, concise, can mention implementation details |
| `MobileReleaseNotesCatalog` in `ContentView.swift` | End users (in-app) | Plain language, no technical jargon, focus on what changed for the user |

When adding features or fixes:
- Update **both** places.
- CHANGELOG.md entries follow Keep a Changelog format (Added / Changed / Fixed).
- In-app release notes use `String(localized:)` — so the 4-language rule applies.

## Key File Locations

| Path | Purpose |
|------|---------|
| `CodexBarMobile/project.yml` | Build number (`CURRENT_PROJECT_VERSION`) and version (`MARKETING_VERSION`) |
| `CodexBarMobile/CodexBarMobile/ContentView.swift` | Main app views, settings, release notes catalog |
| `CodexBarMobile/CodexBarMobile/Localizable.xcstrings` | All translations (JSON) |
| `CodexBarMobile/CodexBarMobile/Views/` | Feature views (provider detail, usage cards, onboarding) |
| `CodexBarMobile/CodexBarMobile/Models/` | Data models and formatters |
| `CodexBarMobile/CodexBarMobile/Preview Content/PreviewData.swift` | Demo / preview data |
| `CodexBarMobile/Shared/` | Shared iCloud sync layer |
| `CodexBarMobile/CHANGELOG.md` | iOS changelog (technical) |
