# 上游 Release 原文证据


## v0.56.1

https://github.com/steipete/CodexBar/releases/tag/v0.56.1

Published: 2026-08-30T10:39:20Z

### Performance
- Codex: load saved cost totals in one pass per file instead of rescanning history for every day and model, preserving costs and token totals (follow-up to #3247). Thanks @⁠robertoecf!
### Fixed
- Menu bar: preserve measured card heights across cached provider tabs, preventing plugin cards from clipping on the first tab switch after launch.
- Privacy: honor “Hide personal information” for project/source names and paths in cost history and project names in Usage & Spend, preserving costs, tokens, and stored data (#3262). Thanks @⁠vinschger!
- Codex: show completed cost catch-up without starting another scan, preserve scan timestamps, and retain prior totals when native or Pi/OMP history is unavailable (partial follow-up to #3243). Thanks @⁠zhulijin1991!
- Codex: preserve calendar spacing in inline cost charts, keep unscanned and unpriced days unknown, honor the selected time zone, and fit year-long histories within the menu (#3232). Thanks @⁠findwangdi!
- Keychain: honor saved disabled-access preferences before startup credential migration, including shared settings, and keep deferred migrations retryable (investigated alongside #3249). Thanks @⁠jaychou0642-create!
- Antigravity: recognize an already-running `agy` even when its command line uses a bare name, and preserve CLI sign-in guidance when the IDE fallback is unavailable (follow-up to #3146). Thanks @⁠haixing23!
- Antigravity: make existing local token history available in CLI cost, serve, and dashboard selection, keeping unknown dollar costs and unavailable history distinct from zero usage (investigated alongside #3266). Thanks @⁠chid!
- Cursor: correctly decode BOM-less ASCII UTF-16LE app-token database values without changing other decoding or cached-account fallback rules (extracted from #2398). Thanks @⁠markmay!
- Claude: price the documented Kimi `k3[1m]` context alias in local usage reports and refresh affected Pi costs, without changing model names or native Codex caches (investigated alongside #2374). Thanks @⁠joeVenner!
- Localization: translate missing Catalan iCloud, spend, and Plugins sidebar labels, restore the Projects translation, and align command labels and instructions with their UI roles (#3245). Thanks @⁠pmontp19!
### Diagnostics
- Codex: add redacted weekly-reset diagnostics for candidate admission, expiry, and account-scoped storage requests; reset publication rules are unchanged (investigated alongside #3248). Thanks @⁠kcharlan!
### Documentation
- Clarify the Codex cost-history refresh floor and explain that Manual stops recurring refreshes, not startup or pending catch-up scans.
- Distinguish OpenCode-backed Codex OAuth quota from unsupported OpenCode session cost imports, preserving provider and account boundaries (investigated alongside #3273). Thanks @⁠pedrommone!
- Document existing z.ai credit quotas and explain how to configure independent provider widgets.


## v0.56.2

https://github.com/steipete/CodexBar/releases/tag/v0.56.2

Published: 2026-08-31T11:53:08Z

### Performance
- Local costs: reduce background CPU spent parsing native session timestamps and validating appended Codex history, preserving timestamp precision, daily totals, and fork accounting.
- Codex: reduce repeated decoding of cached cost history during scans, while preserving stored totals and checking for database and filesystem changes.
- Claude and Vertex AI: reduce CPU spent reading local transcript metadata, preserving provider detection, Unicode handling, and token/cost totals.
### Fixed
- Local costs: preserve token breakdowns, reasoning, request counts, and pricing coverage when combining reports or reopening cached history. Thanks @⁠Pjhhhhh!
- Codex: recover cost-history catch-up when removed fork files leave abandoned parent discovery in an existing cache, preserving stored totals and unresolved-fork accounting (partial fix for #2815). Thanks @⁠xiehaibin18!
- Codex: preserve pending weekly-reset evidence through credits-only refreshes so eligible low-usage confirmations survive relaunch (partial fix for #3248). Thanks @⁠kcharlan!
- Charts: keep endpoint dates readable in token/cost, credit-usage, credits-history, and plan-history submenus (partial fix for #3209). Thanks @⁠vinschger!
- Agent sessions: stop Codex metadata enrichment and Pi/OMP path resolution when the scan budget expires, and honor the same deadline during Claude Desktop root discovery.
- OpenCode Go: omit misleading pace and run-out advice for locally estimated quotas while preserving percentages, resets, and cost history (partial fix for #3286). Thanks @⁠Akagilnc!
- OpenRouter: open Activity from Usage Dashboard instead of credit settings (#3290). Thanks @⁠akshayprabhu200!


## v0.56.3

https://github.com/steipete/CodexBar/releases/tag/v0.56.3

Published: 2026-09-01T22:05:45Z

### Performance
- Claude and Vertex AI: reduce background CPU spent reading transcript metadata and looking up model prices during local cost scans, preserving provider detection and token/cost totals (#3319, #3328).
- Local costs: skip unnecessary parsing work for discarded oversized log records, preserving complete-record validation and cost totals (#3342).
- Codex: avoid repeated full scans after trace-log pruning, while retaining the latest validated cost history through temporary trace-database failures (#3318). Thanks @⁠brzvsk!
### Fixed
- Poe: use one refresh timestamp for point-history retention and daily totals, keeping results consistent throughout a refresh.
- Keychain: limit repeated cache ACL validation and memory growth while preserving recovery after temporary failures or external repairs (#3300, #3301). Thanks @⁠IgorKhramtsov!
- Grok: restore 0% usage for a validated active billing period with an omitted usage scalar, while keeping incomplete or malformed billing responses unknown (#3261, #3325, #3357). Thanks @⁠sf-jin-ku and @⁠olddonkey!
- Ollama: restore usage bars for monthly included credits and show matching history tabs while preserving legacy quota parsing and saved history (#3346). Thanks @⁠haixing23!
- Menu bar: keep status components and website links scoped to their provider when switching cached tabs, preventing Claude status from appearing under Grok or Codex (#3320). Thanks @⁠gianpaj!
- Menu bar: attach minor and maintenance status badges to single-quota meters instead of leaving them floating below the meter (#3354). Thanks @⁠dechaosong!
- Usage & Spend: keep stalled or failed Codex catch-up paused until explicit Refresh, preventing background synchronization from restarting CPU-heavy scans (partial fix for #3316). Thanks @⁠heyajulia!
- Claude: resume scheduled browser-cookie refreshes when no-UI Keychain access recovers, while preserving non-interactive reads and user-initiated denial cooldowns (#3287). Thanks @⁠ehmo!
- Xiaomi MiMo: prevent overlapping local usage tracker updates from colliding on a shared temporary cache file, preserving atomic publication (#3321). Thanks @⁠Lucenx9!
- Claude: avoid duplicated “Resets Reset” labels when CLI usage supplies a singular reset description (#3317). Thanks @⁠Aternus!
- Codex: distinguish same-email workspaces with stable, privacy-safe labels across account settings, system selection, and menu switchers (#3282). Thanks @⁠Dknightsure!


## v0.56.4

https://github.com/steipete/CodexBar/releases/tag/v0.56.4

Published: 2026-09-03T13:12:00Z

### Fixed
- Codex: let cost-history catch-up finish while active rollout files keep growing, preserving complete session and subagent accounting without publishing partial tails (#3243, #3314). Thanks @⁠LeoLin990405!
- Antigravity: restore token history from newer local sessions whose timestamps moved to the steps table, while rejecting missing, duplicate, or conflicting timestamp evidence instead of inventing dates (#3266, #3396). Thanks @⁠chid!
- Codex: keep each managed account's selected workspace authoritative across stacked refreshes, credits, history, menu rows, reconciliation, and System Account promotion instead of reverting to or rewriting the auth file's default workspace (#3347, #3348, #3386). Thanks @⁠krevoit!
- Settings: prevent scrolled detail content from bleeding through the native title bar while retaining the edge-to-edge sidebar and native window title (#3235, #3315). Thanks @⁠LeoLin990405!
- Claude: recognize Cloudflare web challenges without discarding valid cached cookies or prior usage, and offer explicit OAuth or network recovery guidance (#3367, #3375). Thanks @⁠TPuHo4u!
- Antigravity: recover Linux port discovery when `lsof` fails with mount-namespace warnings, while preserving authentication errors and the existing startup deadline (#3362, #3364). Thanks @⁠srijits!
- Menu bar: let live forecast and detail labels use the full row width, preventing text from clipping to its previous width until the menu reopens (#3370).
- Settings: open the About pane from the application menu as well as the status menu, reusing the existing Settings window (#3391). Thanks @⁠elijahfriedman!
- Menu bar: discard non-finite saved status-item positions before AppKit restores them, preserving valid placements (#3361; investigated alongside #3355). Thanks @⁠foobra!
- Claude: remove misleading defaults-suite warnings at launch while preserving shared OAuth preferences for the CLI and widget (#3381, #3384). Thanks @⁠andresg747!
### Documentation
- AWS Bedrock: explain that monitoring API calls may incur charges, how shared refresh controls affect them, and why Manual mode and the displayed budget do not impose a billing cap (#3387, #3393). Thanks @⁠kyen99!


## v0.56.5

https://github.com/steipete/CodexBar/releases/tag/v0.56.5

Published: 2026-09-04T17:24:22Z

### Highlights
- **More reliable Codex cost-history catch-up**: avoid repeatedly rediscovering completed work and clear abandoned Refreshing activity after account or settings changes (#3402, #3417, #3418).
- **Clearer Codex extra-credit accounting**: keep spend, monthly limits, and purchased balances consistent, including confirmed zero balances (#3296).
- **Stable cost-chart navigation**: switching between Token and Cost preserves menu position and scrolling, even with tall charts (#3380).
- **Remote session discovery restored**: prevent repeated app-binary crashes on newer Tailscale installations by explicitly using CLI mode (#3401).
### Fixed
- Codex: preserve pending cost-scan discovery when same-day history requests alternate between narrower and wider windows, avoiding repeated requeueing of completed files and retaining compatible history caches on upgrade (partial fix for #3411). Thanks @⁠kesslerio!
- Codex: retain completed empty session fragments during cost-history scans instead of repeatedly dropping and rediscovering them, without suppressing usage-bearing duplicates or later appended usage (partial fix for #3316; #3402). Thanks @⁠mauriciopolvora!
- Usage & Spend: clear abandoned Refreshing activity when an in-flight cost scan loses its account or settings scope, preserving paused work and replacement workers (follow-up for #3411). Thanks @⁠kesslerio!
- Codex: show extra-credit spend and limits with a distinct purchased balance; reconcile cap and balance freshness independently so confirmed zero balances stay cleared and monthly bars agree with their totals (#3296). Thanks @⁠sf-jin-ku!
- Cost history: keep tall charts in a bounded scroll view so switching Token/Cost no longer jumps the native menu or undoes an immediate wheel scroll (#3380). Thanks @⁠Yuxin-Qiao!
- Agent sessions: explicitly force Tailscale CLI mode during remote-host discovery, preventing repeated app-binary crashes on newer Tailscale installations while preserving existing terminal settings (#3397). Thanks @⁠tzioup!
- Antigravity: match local token-history timestamps by per-turn IDs when auxiliary or reordered steps would otherwise assign usage to the wrong day, while withholding conflicting evidence and preserving legacy timestamp recovery (#3403). Thanks @⁠WeGoToMars!
- Claude: offer Switch Account after a successful CLI quota read without identity fields, while preserving recovery actions for failed refreshes and restored history (partial fix for #3395). Thanks @⁠PoroGramr!
- Claude: stop labeling restored quota history as CLI usage, while retaining the limited-detail warning, original percentages, and stale-data guidance (#3405).
- z.ai: omit impossible five-hour Coding Plan reset timestamps and prevent cached resets from restoring them, retaining quota percentages and valid weekly/MCP dates (partial mitigation for #2871). Thanks @⁠carolitascl!
- Kilo: point authentication recovery messages and provider documentation to the supported `kilo auth login` command (#3408). Thanks @⁠Chevalicious!
- Usage & Spend: prefer heatmap tooltips above hovered cells and keep them within narrow grids; retain daily keyboard selection without the extra system focus rectangle (#3407). Thanks @⁠elijahfriedman!
- z.ai: abbreviate large model token totals with M/B while preserving exact hourly and daily chart values (#3308, #3310). Thanks @⁠medpath1024 and @⁠fantasy!
- Settings: disable iCloud sync sub-options when the main sync switch is off, preserving their saved choices for the next time sync is enabled (#3406). Thanks @⁠elijahfriedman!
- Codex: report thermal pressure as the catch-up pause reason when serious heat and Low Power Mode coincide, preserving the existing pause and scan budget (#3242). Thanks @⁠Yuxin-Qiao!


## v0.56.6

https://github.com/steipete/CodexBar/releases/tag/v0.56.6

Published: 2026-09-05T13:53:16Z

### Highlights
- **Faster Codex cost-history refreshes**: skip raw token-history reads for unchanged sessions while preserving exact pricing, reasoning totals, and fork accounting (#3297).
- **Cached custom menu-bar text**: reuse plain text layouts while preserving native highlighting, spacing, display scaling, and colored emoji (#3110).
- **More reliable usage displays**: show exhausted automatic quotas correctly, accept Kiro plan summaries, and recover rejected Kimi web sessions (#3349, #3359, #3414).
### Fixed
- Codex cost: skip loading raw token histories for unchanged sessions while preserving exact request pricing, reasoning totals, and fork accounting; concurrent cache changes safely request a retry (#3297). Thanks @⁠estevecastells!
- Codex cost: fill missing model-pricing coverage, including cached tokens and long-context Fast usage, and reprice saved rows without rebuilding token history (#3423, #3425).
- Menu bar: reuse cached template images for single-line text-only custom layouts, preserving native highlighting, display scaling, spacing, and vertical adjustments; colored emoji, rich, stale, and high-contrast content retain their existing rendering (#3110). Thanks @⁠thatlev!
- Menu bar: show an exhausted supported quota in automatic switcher progress instead of healthy weekly capacity, while preserving normal weekly progress and provider-specific quota pools (partial fix for #3349). Thanks @⁠rwese!
- Codex: recover subscription renewal and expiration dates through optional OpenAI web billing capture, without delaying app usage or allowing late results to replace newer dashboards or cross accounts (#3373). Thanks @⁠emanuelst!
- Kimi: show API membership and standalone CLI versions, retry rejected automatic web sessions, and preserve completed quotas when optional plan metadata stalls; cancelled refreshes stop before further browser reads (#3414). Thanks @⁠xirong!
- Kiro: accept CLI plan summaries without treating them as format errors, preserve unavailable credit metrics instead of showing false zero usage, and allow existing optional API enrichment to supply valid plan numbers (partial fix for #3359). Thanks @⁠zucram!
- Hooks: show only the configured threshold, executable, and arguments in Settings; keep examples inside empty fields instead of displaying them as duplicate labels (#3424). Thanks @⁠kedryte!


## v0.56.7

https://github.com/steipete/CodexBar/releases/tag/v0.56.7

Published: 2026-09-06T15:03:50Z

### Highlights
- **Live widget freshness labels**: snapshot and stale token-history ages keep advancing between timeline reloads (#3445; partial fix for #3339).
- **Reliable Linux caches**: preserve model pricing and Pi/OMP cost history across repeated refreshes (#3444, #3446).
- **Clearer provider usage**: retain Command Code monthly usage during subscription timeouts, show Moonshot balances in the correct currency, and explain ElevenLabs API key failures (#3441, #3438, #3437).
### Fixed
- Widgets: keep snapshot and stale token-history age labels advancing between timeline reloads, so paused widgets no longer retain fresh-looking timestamps (#3445; partial fix for #3339). Thanks @⁠zhulijin1991!
- Usage & Spend: keep stacked daily and hourly chart segments flush at provider boundaries, rounding only the top of each bar (#3439). Thanks @⁠elijahfriedman!
- Command Code: retain the last confirmed plan for its billing period so subscription timeouts do not erase monthly usage; show the monthly row as unavailable when no plan is known, while preserving rolling five-hour and weekly usage (#3441). Thanks @⁠enieuwy!
- Moonshot: show China-region balances and deficits in CNY while retaining USD for international accounts (#3434, #3438). Thanks @⁠SomSamantray and @⁠doraemonke!
- ElevenLabs: distinguish a missing API key from a rejected key, missing subscription-read permission, or access restrictions, including current and legacy API error formats (#3437). Thanks @⁠benmillerat!
- Pi and OMP cost history: preserve the session cache across repeated Linux refreshes, including saved scan state, provider totals, pricing metadata, and timezone information (#3446).
- Model pricing: preserve cached catalogs across repeated Linux refreshes (#3444; extracted from #3412). Thanks @⁠WeGoToMars!


## v0.56.8

https://github.com/steipete/CodexBar/releases/tag/v0.56.8

Published: 2026-09-07T16:23:14Z

### Highlights
- **More reliable account handling**: preserve Codex permission errors, retain Claude quota-warning history across credential refreshes, and keep Copilot accounts distinct (#3466, #3453, #3460).
- **Accurate provider history**: count Poe weekly usage over the last seven days and keep valid Poe, MiMo, and OpenRouter usage available when optional history contains malformed data (#3449, #3455, #3448, #3458).
- **Better display support**: preserve menu-bar positions on monitors left of the primary display and translate Claude's model-specific weekly quota labels (#3463, #3459).
### Fixed
- Copilot: keep verified GitHub user IDs authoritative when matching legacy token accounts, preventing a matching login or display label from replacing a different resolved account.
- OpenRouter: reject combined Activity token overflow before publishing history so malformed optional data cannot hide valid credits or key quota; share input/output total validation (extracted from #3272). Thanks @⁠akshayprabhu200!
- Poe: skip out-of-range history timestamps instead of letting date formatting hide a valid point balance; preserve supported timestamp formats and valid activity.
- Menu bar: preserve valid saved positions on wide monitors placed left of the primary display while retaining the legacy accepted range for menu-manager compatibility (related to #3355).
- Claude: retain quota-warning history for known accounts across credential refreshes, preventing repeat threshold alerts while preserving recovery crossings and separate account state (partial fix for #3450). Thanks @⁠JonLaliberte!
- Poe: calculate weekly points, requests, and spend from the last seven elapsed days, so older activity no longer inflates sparse or inactive weeks; share totals aggregation with Today and the 30-day window (#3449). Thanks @⁠Lucenx9!
- MiMo: skip malformed local session rows before deduplication so valid usage still refreshes the cache, preserving all token buckets and UTC daily/weekly totals with shared aggregation (#3448). Thanks @⁠Lucenx9!
- Codex: retain HTTP 403 permission failures instead of treating them as expired credentials and launching Auto recovery; share status/cancellation handling across OAuth and PAT requests (extracted from #3379). Thanks @⁠Yuxin-Qiao!
- Claude: label model-specific weekly quotas with a translated weekly duration while preserving model names and CLI titles; correct swapped Vietnamese Weekly and missing-version labels (#3447). Thanks @⁠gianpaj!
- Packaging: select the bundled iCloud provisioning profile only for its upstream signing team, preserving alternate-team app/widget groups without incompatible CloudKit entitlements (extracted from #3372). Thanks @⁠krazybean!


## v0.57.0

https://github.com/steipete/CodexBar/releases/tag/v0.57.0

Published: 2026-09-08T14:42:23Z

### Highlights
- **Claude cost breakdowns:** inspect daily usage and top models with the new opt-in CLI `cost --breakdown` output (#3244).
- **Faster, more accurate cost history:** reuse Claude reports across launches, resume interrupted Codex scans, and recover usage missed by older parsers (#3284, #3411, #3504).
- **Clearer menus and fresher dashboards:** refresh spend charts when returning to the app, show money or points for balance-only providers, and honor segmented claude-swap account menus (#3107, #3494, #3498).
- **Hardened updates:** adopt Sparkle 2.9.6's archive-handling and package-signature protections.
### Added
- CLI: add opt-in Claude `cost --breakdown` daily and top-model details, with consistent calendar or recorded periods and explicit partial-attribution labels (#3244). Thanks @⁠Yuxin-Qiao!
### Performance
- Claude local costs: reuse compatible cost reports across launches instead of decoding unchanged transcript caches; refresh them when history, pricing, or report semantics change (#3284). Thanks @⁠eggyrooch-blip!
- Codex local costs: reduce repeated pricing work across daily, project, and session reports without changing token accounting or tariffs (#3476). Thanks @⁠brzvsk!
### Security
- Updates: adopt Sparkle 2.9.6 installer hardening, including archive-moving and package-signature validation fixes.
### Fixed
- Usage & Spend: refresh expired charts on pane return or app activation, keep cached data visible during loading, and refresh across midnight (#3107). Thanks @⁠Yuxin-Qiao!
- Codex local costs: resume unfinished scans after a refresh reaches its time limit, without restarting completed file work or discarding compatible history (related to #3411). Thanks @⁠kesslerio!
- Codex local costs: accept valid JSON whitespace in usage events, retain next-day appended usage, and reparse older files once without deleting compatible stores (#3504).
- Codex local costs: include previously unpriced usage in GPT-5.6 Luna estimates, including cached reports, without discarding compatible history or scan progress (#3503, #3502). Thanks @⁠BUKOWSKIREAL!
- Claude local usage: discard stale rows when a transcript is replaced, including across restarts, while retaining incremental parsing for genuine appends.
- Usage parsing: reject out-of-range counts in MiMo, Pi/OMP, OpenCodex, and Bedrock without crashing; preserve valid fields and refresh affected OpenCodex caches (#3486).
- Local costs: avoid overflow crashes in OpenCodex and combined reports, leaving unrepresentable totals unavailable while retaining valid neighboring token classes (#3501).
- Accounts: retain matching cached usage and widget data through transient multi-account refresh failures without refreshing measurement timestamps or reusing changed credentials.
- Claude: honor segmented account menus for claude-swap, retain unavailable-account diagnostics, and show stable slot numbers when personal information is hidden (#3498, #3382). Thanks @⁠thatlev!
- Claude: preserve claude-swap's measurement timestamps so cached usage does not appear newly refreshed; retain the fallback for missing or malformed optional timestamps (#3485, extracted from #3452). Thanks @⁠QuantIntellect!
- Claude: recover expired default-profile usage from fresh CLI credentials when existing consent permits, while preserving explicit-file precedence and custom-profile isolation (related to #3390).
- Menu bar: show money or points for balance-only providers in the default layout and editor preview, preserve real quota percentages, and avoid duplicate reset text (#3492, #3494). Thanks @⁠zkforge!
- Widgets: remove redundant padding from Usage, Switcher, History, and Metric widgets so WidgetKit controls their content margins (extracted from #3137). Thanks @⁠iamenahs!
- Overview: keep highlighted provider cards readable on macOS 15 while retaining fast GPU selection and native submenu interactions (#3173).
- Copilot: resolve Enterprise identities on the configured host, keep accounts on different hosts distinct, and avoid public GitHub budget requests for Enterprise accounts (#3341). Thanks @⁠Fletcher-Alderton!
- Antigravity: show each CLI quota bucket once, preserve unavailable usage and reset context, and keep display filtering out of raw JSON (#3489). Thanks @⁠urda!
- Antigravity local usage: retain valid history around bookkeeping steps without UUIDs, while continuing to reject ambiguous IDs and uncertain dates (#3462). Thanks @⁠urda!
- Kiro: use the CLI profile's supported region for overage enrichment, reject invalid profile ARNs before sending credentials, and retain CLI fallback (#3359). Thanks @⁠zucram!
- MiniMax: preserve cached usage and normal retries after DNS, connection, and translated offline failures.
- z.ai: preserve valid quota when optional model analytics overflow or exceed display bounds, while retaining supported Unicode labels.
- AWS Bedrock: disclose monitoring charges in both authentication modes, link Cost Explorer pricing, and clarify refresh controls and the informational budget (#3496, related to #3387). Thanks @⁠kyen99!
- Settings: detect rapid external config replacements and edits that restore earlier app-written contents, without treating successful app writes as external changes.
- Local usage: honor the app's Low Power Mode interval during automatic Codex catch-up, while retaining manual acceleration and system thermal pauses.
- CLI login: stop cancelled Codex and Kiro logins and lingering child processes while preserving timeout output and device-flow progress.
- Subprocesses: handle very large finite timeouts without overflowing or crashing.


## v0.58.0

https://github.com/steipete/CodexBar/releases/tag/v0.58.0

Published: 2026-09-10T04:06:38Z

### Highlights
- **Daily spend ledger:** inspect tokens, requests, and spending day by day in Usage & Spend, with your selected time zone and clear labels for unavailable amounts (#2635).
- **More useful cost charts:** hover over a daily bar in the menu to see its date, cost, and token count (#3413).
- **Menus that fit your workflow:** choose visible usage rows, select session or weekly percentages, and add explicit reset countdowns or clocks to menu-bar layouts (#3196, #3124, #3481).
- **Clearer account quotas:** compact account rows now show reset times beside the quotas they belong to (#3477).

### Added
- Usage & Spend: add a daily provider ledger for tokens, requests, and spend, honoring selected time zones and distinguishing unknown amounts from zero usage (#2635). Thanks @⁠sahilaidev!
- Inline cost charts: show each day's localized date, cost, and token count on hover without shifting the chart layout (#3413). Thanks @⁠666ghj!
- Provider menus: choose visible usage rows across full and compact menus, Settings previews, and Overview; sync selections and restore hidden rows without changing fetching or alerts (#3196, #3182). Thanks @⁠psufka and @⁠J2TeamNNL!
- Menu bar: choose Auto, Session, or Weekly percent windows in provider settings while preserving custom layout tokens and the global icon style (#3124). Thanks @⁠J2TeamNNL!
- Menu bar layouts: choose session or weekly reset countdowns and clocks, including conditional branches, with support for existing saved layouts (#3481, #3356). Thanks @⁠vincent-peng!
- Account menus: show reset times beside compact account quotas, keeping each time tied to its account and quota window and honoring privacy settings (#3477). Thanks @⁠TobitRE!

### Fixed
- OpenCodex local usage: aggregate costs and requests over the full requested history so All-history spend and daily ledger counts remain available (#2635).
- Codex local costs: exclude inherited records before an explicit subagent history boundary, including files with no child-owned usage yet, and refresh older cached counts without discarding stored history (#3527, related to #3524). Thanks @⁠vnnkl!
- Token counts: promote rounded `1000K` and `1000M` values to `1M` and `1B`, preserve ordinary precision, and handle the full signed integer range without crashing (#3519, fixes #3518). Thanks @⁠harjothkhara!

### Development
- Test runner: fail early when Python lacks required process-containment APIs and explain how to select a compatible interpreter (#3517, fixes #3515). Thanks @⁠devYRPauli!

