# CodexBar Mobile — Agent Workflow

This is the complete development workflow for any AI agent working on CodexBar Mobile (iOS).

> **Scope:** We only work on the iOS app (`CodexBarMobile/`). Mac-side code is maintained upstream.

---

## Development Lifecycle

Every feature or fix follows these 7 steps in order:

```
┌───────────────────┬─────────────────────────────────────────────────┬─────────────────────┐
│       Step        │                   Description                   │       Output        │
├───────────────────┼─────────────────────────────────────────────────┼─────────────────────┤
│ 1. Research       │ Understand the problem, read code/SDK/data      │ Root cause or       │
│                   │ Check upstream repo + PRs for prior art         │ requirements doc    │
├───────────────────┼─────────────────────────────────────────────────┼─────────────────────┤
│ 2. Design         │ Write research doc in Research/, mark draft     │ Research/NNN-*.md   │
│                   │ Get user confirmation on approach               │                     │
├───────────────────┼─────────────────────────────────────────────────┼─────────────────────┤
│ 3. Implementation │ Write code in phases, protocol-first            │ Code changes        │
├───────────────────┼─────────────────────────────────────────────────┼─────────────────────┤
│ 4. Testing        │ Build, simulator, real device if needed         │ Tests pass          │
├───────────────────┼─────────────────────────────────────────────────┼─────────────────────┤
│ 5. Documentation  │ Update CHANGELOG, in-app release notes,         │ Traceable record    │
│                   │ research doc status → done                      │                     │
├───────────────────┼─────────────────────────────────────────────────┼─────────────────────┤
│ 6. Commit         │ Bump build number, verify docs, jj commit       │ jj change           │
├───────────────────┼─────────────────────────────────────────────────┼─────────────────────┤
│ 7. Push & Release │ Push to remote, archive, upload to TestFlight   │ User-installable    │
└───────────────────┴─────────────────────────────────────────────────┴─────────────────────┘
```

---

## Step 1 — Research

Before writing any code, understand the problem space.

- Read relevant source code, SDK docs, and real synced data
- Check upstream (steipete/CodexBar) for existing implementations or open PRs
- Save findings to `CodexBarMobile/Research/NNN-feature-name.md`

## Step 2 — Design

- Write or update the research doc with chosen approach, data models, key files
- Set status appropriately (see research status flow below)
- Get user confirmation before proceeding to implementation

### Research document status flow

```
draft → ready → in-progress → done
  │
  ├→ blocked-upstream   (waiting for upstream PR to merge)
  └→ dropped            (decided not to pursue)
```

Full status definitions and index are in `CodexBarMobile/Research/README.md`.

## Step 3 — Implementation

- Follow protocol-first design: define interfaces before writing logic
- Phase large features into incremental, buildable steps
- Follow all coding rules below (localization, file conventions, etc.)

## Step 4 — Testing

- Build with `xcodebuild` to verify compilation
- Run unit tests if applicable
- Verify on simulator or real device as needed

## Step 5 — Documentation

After code is complete:

1. Update `CodexBarMobile/CHANGELOG.md` — Keep a Changelog format (Added / Changed / Fixed)
2. Update in-app release notes in `MobileReleaseNotesCatalog` (in `ContentView.swift`) — plain language, 4-language localized
3. Update research doc status to `done`

### Release notes — two audiences

| File | Audience | Style |
|------|----------|-------|
| `CodexBarMobile/CHANGELOG.md` | Developers, App Review | Technical, concise |
| `MobileReleaseNotesCatalog` in `ContentView.swift` | End users (in-app) | Plain language, no jargon, localized |

## Step 6 — Commit

When the user says **"提交"** (commit) or **"提交推送"** (commit and push):

### 6a. Bump build number

- Open `CodexBarMobile/project.yml`
- Increment all `CURRENT_PROJECT_VERSION` values by 1 (e.g. `"12"` → `"13"`)
- Do NOT change `MARKETING_VERSION` unless explicitly asked

### 6b. Verify documentation

- Ensure `CHANGELOG.md` has entries for the current build number
- Ensure in-app release notes version string matches build number

### 6c. Commit with jj

```bash
jj describe -m "commit message here"
```

### 6d. Push (only if user said "提交推送")

```bash
jj bookmark set mobile-dev -r @
jj git push --bookmark mobile-dev
```

### Version number format

- `MARKETING_VERSION` = user-facing version, e.g. `1.0.0` (feature releases only)
- `CURRENT_PROJECT_VERSION` = build number, e.g. `13` (increments on every commit)
- Displayed as: **1.0.0 (13)**

## Step 7 — Push & Release

When the user asks to upload / archive / release:

```bash
# 1. Generate Xcode project
cd CodexBarMobile && xcodegen generate

# 2. Archive
xcodebuild -project CodexBarMobile.xcodeproj -scheme CodexBarMobile \
  -sdk iphoneos -configuration Release \
  -archivePath build/CodexBarMobile.xcarchive archive

# 3. Export & upload to App Store Connect
xcodebuild -exportArchive \
  -archivePath build/CodexBarMobile.xcarchive \
  -exportOptionsPlist /tmp/ExportOptions.plist \
  -exportPath build/export

# 4. Clean up build artifacts
rm -rf CodexBarMobile/build
```

---

## Coding Rules

### Version Control — jj (Jujutsu)

We use **jj** colocated with git. Do NOT use raw git commands for commits.

```bash
jj status                          # working copy changes
jj log --limit 10                  # recent history
jj describe -m "message"           # set change description
jj new                             # start a new change
jj bookmark set mobile-dev -r @    # point bookmark to current change
jj git push --bookmark mobile-dev  # push to origin
```

### Localization — Mandatory 4-Language Rule

**Every user-facing text change MUST include all 4 languages. No exceptions.**

Languages: English (`en`), Simplified Chinese (`zh-Hans`), Traditional Chinese (`zh-Hant`), Japanese (`ja`).

- Source language is English
- All strings use `String(localized:)` — the key is the English text itself
- Translations live in `Localizable.xcstrings` (JSON format)
- Every entry must have all 4 translations with `"state": "translated"`

**Needs translation:** UI labels, buttons, titles, descriptions, footers, placeholders, error messages, in-app release notes, onboarding text, empty states.

**Does NOT need translation:** Code comments, log messages, debug strings, accessibility identifiers, keys, enum raw values, format specifiers.

#### Self-check before finishing

- [ ] Every new `String(localized:)` has a matching entry in `Localizable.xcstrings`
- [ ] Every entry has all 4 languages with `"state": "translated"`
- [ ] No `"state": "new"` or missing language keys left behind

---

## Quick Reference

### Trigger phrases

| User says | Action |
|-----------|--------|
| 调研 | Steps 1–2 (research, save to Research/) |
| 提交 | Step 6a–6c (bump build, changelog, jj commit) |
| 提交推送 | Step 6a–6d (bump build, changelog, jj commit, push) |
| 上传 / Archive | Step 7 (xcodegen, archive, upload to TestFlight) |

### Key paths

| Path | Purpose |
|------|---------|
| `CLAUDE.md` | Project overview + pointers |
| `AGENTS.md` | This file — full workflow |
| `CodexBarMobile/Research/` | Feature research docs |
| `CodexBarMobile/project.yml` | Build number + version |
| `CodexBarMobile/CHANGELOG.md` | Technical changelog |
| `CodexBarMobile/CodexBarMobile/ContentView.swift` | Main views + in-app release notes |
| `CodexBarMobile/CodexBarMobile/Localizable.xcstrings` | 4-language translations |
| `CodexBarMobile/Shared/` | Shared iCloud sync layer |
