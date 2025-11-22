# Changelog

## 0.5.0 — Unreleased
- Codex usage/credits now use the codex app-server RPC by default (with PTY `/status` fallback when RPC is unavailable), reducing flakiness and speeding refreshes.
- Claude CLI probe now runs `/usage` and `/status` in parallel (no simulated typing), captures reset strings, and uses a resilient parser (label-first with ordered fallback) while keeping org/email separate by provider.
- TTY runner now always tears down the spawned process group (even on early Claude login prompts) to avoid leaking CLI processes.
- Default refresh cadence is now 5 minutes, and a 15-minute option was added to the settings picker.
- Claude probes/version detection now start with `--allowed-tools ""` (tool access disabled) while keeping interactive PTY mode working.
- Codex probes and version detection now launch the CLI with `-s read-only -a untrusted` to keep PTY runs sandboxed.
- Codex warm-up screens (“data not available yet”) are handled gracefully: cached credits stay visible and the menu skips the scary parse error.
- Codex reset times are shown for both RPC and TTY fallback, and plan labels are capitalized while emails stay verbatim.

## 0.4.3 — 2025-11-21
- Fix status item creation timing on macOS 15 by deferring NSStatusItem setup to after launch; adds a regression test for the path.
- Menu bar icon with unknown usage now draws empty tracks (instead of a full bar when decorations are shown) by treating nil values as 0%.

## 0.4.2 — 2025-11-21
- Sparkle updates re-enabled in release builds (disabled only for the debug bundle ID).

## 0.4.1 — 2025-11-21
- Both Codex and Claude probes now run off the main thread (background PTY), avoiding menu/UI stalls during `/status` or `/usage` fetches.
- Codex credits stay available even when `/status` times out: cached values are kept and errors are surfaced separately.
- Claude/Codex provider autodetect runs on first launch (defaults to Codex if neither is installed) with a debug reset button.
- Sparkle updates re-enabled in release builds (disabled only for debug bundle ID).
- Claude probe now issues the `/usage` slash command directly to land on the Usage tab reliably and avoid palette misfires.

## 0.4.0 — 2025-11-21
- Claude Code support: dedicated Claude menu/icon plus dual-wired menus when both providers are enabled; shows email/org/plan and Opus usage with clickable errors.
- New Preferences window: General/About tabs with provider toggles, refresh cadence, start-at-login, and always-on Quit.
- Codex credits without web login: we now read `codex /status` in a PTY, auto-skip the update prompt, and parse session/weekly/credits; cached credits stay visible on transient timeouts.
- Resilience: longer PTY timeouts, cached-credit fallback, one-line menu errors, and clearer parse/update messages.

## 0.3.0 — 2025-11-18
- Credits support: reads Codex CLI `/status` via PTY (no browser login), shows remaining credits inline, and moves history to a submenu.
- Sign-in window with cookie reuse and a logout/clear-cookies action; waits out workspace picker and auto-navigates to usage page.
- Menu: credits line bolded; login prompt hides once credits load; debug toggle always visible (HTML dump).
- Icon: when weekly is empty, top bar becomes a thick credits bar (capped at 1k); otherwise bars stay 5h/weekly.

## 0.2.2 — 2025-11-17
- Menu bar icon stays static when no account/usage is present; loading animation only runs while fetching (12 fps) to keep idle CPU low.
- Usage refresh first tails the newest session log (512 KB window) before scanning everything, reducing IO on large Codex logs.
- Packaging/signing hardened: strip extended attributes, delete AppleDouble (`._*`) files, and re-sign Sparkle + app bundle to satisfy Gatekeeper.

## 0.2.1 — 2025-11-17
- Patch bump for refactor/relative-time changes; packaging scripts set to 0.2.1 (5).
- Streamlined Codex usage parsing: modern rate-limit handling, flexible reset time parsing, and account rate-limit updates (thanks @jazzyalex and https://jazzyalex.github.io/agent-sessions/).

## 0.2.0 — 2025-11-16
- CADisplayLink-based loading animations (macOS 15 displayLink API) with randomized patterns (Knight Rider, Cylon, outside-in, race, pulse) and debug replay cycling through all.
- Debug replay toggle (`defaults write com.steipete.codexbar debugMenuEnabled -bool YES`) to view every pattern.
- Usage Dashboard link in menu; menu layout tweaked.
- Updated time now shows relative formatting when fresher than 24h; refactored sources into smaller files for maintainability.
- Version bumped to 0.2.0 (4).

## 0.1.2 — 2025-11-16
- Animated loading icon (dual bars sweep until usage arrives); always uses rendered template icon.
- Sparkle embedding/signing fixed with deep+timestamp; notarization pipeline solid.
- Icon conversion scripted via ictool with docs.
- Menu: settings submenu, no GitHub item; About link clickable.

## 0.1.1 — 2025-11-16
- Launch-at-login toggle (SMAppService) and saved preference applied at startup.
- Sparkle auto-update wiring (SUFeedURL to GitHub, SUPublicEDKey set); Settings submenu with auto-update toggle + Check for Updates.
- Menu cleanup: settings grouped, GitHub menu removed, About link clickable.
- Usage parser scans newest session logs until it finds `token_count` events.
- Icon pipeline fixed: regenerated `.icns` via ictool with proper transparency (docs in docs/icon.md).
- Added lint/format configs, Swift Testing, strict concurrency, and usage parser tests.
- Notarized release build "CodexBar-0.1.0.zip" remains current artifact; app version 0.1.1.

## 0.1.0 — 2025-11-16
- Initial CodexBar release: macOS 15+ menu bar app, no Dock icon.
- Reads latest Codex CLI `token_count` events from session logs (5h + weekly usage, reset times); no extra login or browser scraping.
- Shows account email/plan decoded locally from `auth.json`.
- Horizontal dual-bar icon (top = 5h, bottom = weekly); dims on errors.
- Configurable refresh cadence, manual refresh, and About links.
- Async off-main log parsing for responsiveness; strict-concurrency build flags enabled.
- Packaging + signing/notarization scripts (arm64); build scripts convert `.icon` bundle to `.icns`.
