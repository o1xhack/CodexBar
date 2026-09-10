# 上游范围 commits

`git log --oneline v0.56.0..v0.58.0`

```text
88fa2f45f docs: update appcast for 0.58.0
518743e2d chore: prepare 0.58.0 release
d8fa1d545 feat: show reset times in compact account rows (#3477)
207eef7f1 feat: configure provider usage row visibility (#3196)
5e5a9003e feat: add daily spend ledger (#2635)
36cf4e3ae feat: show inline cost chart hover details (#3413)
8f0ee6be7 feat: choose provider percent windows (#3124)
07c879473 feat: add explicit menu bar reset windows (#3481)
c856e4b12 fix: respect explicit subagent history boundaries (#3527)
4fe002072 ci: explain unsupported Python test runners (#3517)
348d84a74 fix: normalize rounded token counts safely (#3519)
928166f89 ci: isolate Homebrew handoffs across retries
05bb0e694 chore: start 0.57.1 development
45cda6084 docs: update appcast for 0.57.0
c2d90887d build: synchronize widget dependency pins
b371f5db4 docs: prepare 0.57.0 release notes
08ef7710f docs(changelog): collect local cost accuracy fixes
2188c90a6 fix(cost): accept JSON whitespace in Codex event records
b76508292 fix(accounts): preserve validated usage during network outages
71e2b7a0c fix(minimax): preserve transport identity for cache and retry
6f0c9266e fix(layout): show provider balances without duplicated reset text
57ddfdbf7 Resolve Codex reserve telemetry through the existing GPT-5.6 Luna pricing path so fresh and cached local reports include its API-equivalent estimate. Retain token accounting, provider-qualified lookup, the subscription estimate disclaimer, and compatible cache rows and scan checkpoints.
2033edb37 docs(changelog): collect Claude menu and Bedrock disclosure fixes
e967a92b8 fix(claude): honor segmented account menu layout
ebda2acbe fix(bedrock): disclose monitoring charges in settings
c8077097b fix(costs): keep unrepresentable token totals unavailable (#3501)
b1e27d266 fix: reject unrepresentable numeric usage safely (#3486)
c3f3ea1fa docs(changelog): collect spend refresh and Claude cost improvements
b7f2a7cc5 fix(antigravity): preserve CLI quota buckets and unavailable usage (#3489)
0cb8c425e fix(codex): resume interrupted warm cost scans
4bfbbe209 feat(claude): add opt-in cost breakdown with accurate periods
d9f019d8f perf(claude): persist compatible cost reports across launches
80afaac2f fix(spend): refresh expired dashboard snapshots on return
2a71b479a fix: keep GPU-tinted Overview cards visible on macOS 15 (#3482)
1b7678fd2 docs: collect unreleased maintenance notes
4646e8fea chore(deps): refresh compatible Swift packages and checkout action
6818f8238 fix(claude): preserve claude-swap measurement timestamps
9810f24b0 fix: share CLI login lifecycle and honor cancellation (#3484)
b18431b51 test: anchor OpenCode Go history fixtures to local days (#3483)
912eac223 fix: let WidgetKit own usage content margins (#3480)
707fdda42 fix: keep Copilot Enterprise login identities scoped to their host (#3341)
d85ef4935 perf: reuse Codex pricing resolution across reports (#3476)
c526fe717 refactor(cost): share report accumulation and pricing
ca3ad7851 chore: release 0.56.8 and start 0.56.9 development
6ef82690b docs: update appcast for 0.56.8
170a4d41c test: honor current locale in billing and spend fixtures
4f760cfc9 fix(kiro): route enrichment to the supported profile region
260fb2551 fix(zai): contain invalid optional analytics before snapshot validation
79d146d8c fix(claude): refresh expired default-profile cache from changed CLI credentials
cd8464f58 refactor(kiro): share probe defaults and overage fallback
6b545c652 fix(settings): reconcile config changes across watcher rearming (#3469)
0863fe838 fix(claude): discard cached rows from replaced transcripts (#3464)
a1391fc30 fix(antigravity): preserve history around UUID-less bookkeeping steps (#3462)
a4760f2d5 fix(cost): honor app low power mode during automatic catch-up (#3468)
3d012282c docs: finalize 0.56.8 release notes
46b8840b2 fix(codex): preserve permission errors across authenticated requests (#3466)
5d585d1d7 fix(menu): preserve valid placements on left-hand displays (#3463)
debe5cdfb refactor(localization): share the session label in quota settings (#3465)
02c073a22 fix(packaging): scope iCloud provisioning to its signing team (#3461)
3c5bc8199 fix(copilot): prioritize verified legacy account identities (#3460)
49f2dc916 fix(claude): clarify and localize scoped weekly quota labels (#3459)
9d01d5cf0 fix(openrouter): contain combined activity token overflow (#3458)
7ddcb813f refactor(menu): share quota pace and reset presentation (#3456)
0e8ccd2bc fix(poe): reject invalid dates before history aggregation (#3455)
31131374b fix(claude): preserve account warnings across credential refreshes (#3453)
8baa6cb48 fix(mimo): keep valid usage after malformed session rows (#3448)
7353c7175 fix(poe): count elapsed days in weekly history (#3449)
0be771490 chore: start 0.56.8 development
d8f4cec19 docs: update appcast for 0.56.7
53224abea docs: prepare 0.56.7 release notes
c15f736ef fix(cost): preserve Pi session caches on Linux (#3446)
5e69a9223 fix(widgets): keep freshness labels live between timeline reloads (#3445)
559bfc818 fix(pricing): atomically replace cached catalogs on Linux (#3444)
211781be7 fix(charts): keep stacked spend segments flush (#3439)
34ac0879c fix(elevenlabs): clarify API key errors (#3437)
b921ed2ec fix(commandcode): preserve monthly usage during subscription timeouts
3a676e143 fix(moonshot): preserve regional balance currencies (#3438)
ee71f9692 test: prevent Git fixture output deadlocks (#3440)
eecb7e3a3 chore: start 0.56.7 development
1696c7a71 docs: update appcast for 0.56.6
4e15b148d test: drain RPC logging subprocess output
26b2a1e5f test: drain config dump subprocess output
276c76f94 docs: finalize 0.56.6 release notes
4d27bb113 perf(menu bar): cache plain text layouts with native template drawing (#3110)
28b8dcbe8 fix(kiro): preserve unavailable usage in CLI plan summaries (#3431)
cd5f2be23 fix(menu): honor exhausted quotas in automatic switcher progress (#3430)
ddf504ba1 perf(cost): load raw Codex token histories on demand (#3297)
96b83b7b9 fix(cost): calculate GPT-6 Astra usage costs (#3427)
e236e1ecd fix(hooks): remove duplicate input labels from Settings (#3426)
babfb51da fix(kimi): show membership and recover rejected sessions (#3414)
410a55471 fix(codex): recover subscription dates safely (#3373)
01cdb355c chore: prepare 0.56.6 development
1039ea68e chore: publish 0.56.5 appcast
07f2a6702 chore: prepare 0.56.5 release
b9b6dfe56 docs: highlight and prioritize unreleased fixes (#3421)
30f881aee fix(codex): retain pending scan range across history requests (#3417)
88f0e58bf fix(cost): clear abandoned dashboard catch-up activity (#3418)
470359357 fix(zai): suppress impossible five-hour reset timestamps (#3416)
e0a31b904 fix(cost): keep thermal precedence in automatic catch-up pause (#3242)
55b20c034 fix: keep cost history metric switches from scrolling menus (#3380)
b07fd2ea4 fix(codex): reconcile extra credit usage and balances (#3296)
392310c66 fix(claude): recognize successful CLI usage in account actions (#3410)
b67402221 Compact z.ai token totals (#3310)
2e42c70b8 fix(kilo): use the supported authentication recovery command (#3408)
476573ddd fix(settings): disable iCloud sub-options when sync is off (#3406)
63dfb145f fix(spend): keep heatmap tooltips within the grid (#3407)
5996f7fc3 fix(claude): correct restored-history detail note (#3405)
0b181ccba fix(antigravity): match local history timestamps by turn ID (#3403)
7e9c1e8a5 fix(codex): preserve completed empty session fragments (#3402)
98bea29e9 fix(sessions): force Tailscale discovery into CLI mode (#3401)
fb9d29530 docs: update appcast for 0.56.4
72081cd6b fix(test): recover missing Sparkle runtime
538866089 chore(release): prepare 0.56.4
8d874e4f7 fix(antigravity): validate aligned step timestamps (#3396)
6790f76d7 fix(settings): prevent titlebar content bleed (#3315)
01da8fc6e fix(codex): stop live rollouts from starving cost updates (#3314)
c406dd045 fix(antigravity): recover newer session history safely (#3266)
98f8f36ac Route About menu to Settings About pane (#3391)
084ee156d docs(bedrock): disclose monitoring API charges (#3393)
9039ddbab docs: backfill unreleased fixes after 0.56.3 (#3392)
6ae54e88a fix(codex): preserve selected workspace ownership (#3386)
acdf20823 fix(claude): avoid own-domain defaults suites (#3384)
620f3b8e4 test: preseed Claude identity fixture configuration (#3311)
9fbe605ee Speed up PTY fast-exit stress test (#3333)
4cc3373f3 fix(test): prevent widget timeline reloads during tests (#3378)
33fd05ba7 perf(test): prefilter provider architecture scan (#3330)
98b86f39d fix(test): isolate app-group migration from user state (#3365)
a8b9c55cd fix(codex): preserve selected workspaces in stacked refresh (#3348)
ec8534de0 test: fix MiMo cache publication hooks across Python versions (#3366)
90c631440 fix(claude): identify Cloudflare web challenges (#3375)
2cac84440 fix: keep live forecast text within menu rows (#3370)
9e7af5187 fix(antigravity): recover Linux port discovery after lsof failures (#3364)
d79bca82f chore(release): publish 0.56.3 appcast
542ca301f chore(release): prepare 0.56.3 appcast
96804f915 test: isolate cached menu render measurement (#3360)
8ee922034 fix(menu): reject non-finite saved status item positions (#3361)
a0d5d2f66 fix(poe): use the refresh clock for point history
7654edfdf docs: finalize 0.56.3 release notes
eb290548a Fix single-quota status badge placement (#3354)
c3a25fd85 fix(grok): preserve unknown usage for malformed billing tags (#3357)
d637a5a56 fix(ollama): restore monthly usage compatibility (#3346)
2ff41951c fix(codex): distinguish colliding workspace labels (#3351)
5360b0e03 fix(keychain): bound confirmed ACL rejection retries (#3301)
eb8aecdd1 fix: resume background cookie refresh after access recovers (#3352)
8eef2b914 perf: skip discarded JSONL tail-state tracking (#3342)
30a946c4c test(cost): shorten lock-contention fixture waits (#3335)
e7d0011a8 Show a 0% Grok usage bar when the period has no usage yet (#3325)
dacbd5222 fix: preserve nested process containment during observation (#3343)
a140553c9 test(sakana): await cancellation with a bounded deadline (#3344)
8a732e743 perf: preserve Codex priority cursor across trace pruning (#3318)
e236a21bc perf: avoid repeated Claude JSON container bridging (#3328)
7012d9dff fix: scope warmed status submenus to their provider (#3329)
7da7cdd11 fix: normalize singular reset labels (#3326)
95d522dae Fix concurrent MiMo cache writes (#3321)
170ebd36d fix: keep stalled Codex spend catch-up paused (#3324)
5d7c1f29f perf: reuse Claude pricing resolution within scans (#3319)
8ff81d718 chore: start 0.56.3 development
5351013a2 docs: update appcast for 0.56.2
29536872a fix: sign nested Sparkle code before enclosing bundles
5fbe3b3ec chore: prepare 0.56.2 release
2570a034f perf: streamline Claude cost metadata detection (#3313)
10c0eb73d perf: reuse decoded native Codex scan baseline (#3312)
7661b700d fix: preserve merged cost report details (#3307)
354191af9 fix: preserve full history chart date labels (#3305)
8afdbcb1e perf: reduce native cost scan CPU (#3304)
5a18e8ee9 fix: preserve weekly reset candidates during credit refresh (#3302)
83977905e fix: honor agent metadata scan deadlines (#3299)
68ad25434 fix(openrouter): open Activity from Usage Dashboard (#3293)
56bbc037f fix: drain abandoned Codex parent discovery (#3292)
89765dc2b fix(opencodego): omit pace advice for local quota estimates (#3288)
efb952e0b chore: start 0.56.2 development
aa041691b chore: publish CodexBar 0.56.1 appcast
e8e275511 fix: preserve cached menu card heights
39c15c6ad docs: prepare 0.56.1 release notes
c89257133 fix: decode Cursor ASCII UTF-16LE auth blobs (#3281)
8ee6704ef fix: isolate provider session files during tests (#3280)
b4e670c10 fix: publish completed Codex cost history without rescanning (#3279)
37162d50b test(cost): seed fresh migration corpora exclusively (#3278)
7861c0b09 fix(antigravity): preserve warm CLI identity and auth errors (#3277)
e0d2fd90b fix(codex): explain delayed reset admission decisions (#3276)
c5ab14517 test: isolate Cursor cache mutation callbacks (#3275)
5ac1a66b5 feat: add gated Codex Workspaces navigation
debed01a9 docs: clarify OpenCode quota and cost boundaries (#3274)
8514b24cf fix: mask cost-history project identity in privacy mode (#3271)
ae0ec9e24 test: stabilize local database and menu refresh fixtures (#3269)
7d502b9eb docs: clarify z.ai quotas and widget provider selection (#3268)
e304774cb fix: enable Antigravity local cost routing (#3267)
ce4471357 docs: clarify automatic Codex cost refresh cadence (#3265)
7802d0c04 perf: group Codex cost aggregates in one pass (#3264)
b366a2d5a test: isolate RPC fixtures and prove hung requests (#3263)
41c53c34d fix: preserve Codex cost chart calendar positions (#3232)
69df3415a fix: price Claude Kimi context aliases without crossing providers (#3259)
8a20919a3 fix(i18n): complete Catalan settings translations (#3245)
9769d7394 fix: honor disabled Keychain access during startup (#3258)
1680b4ed5 test: separate fixture startup from cleanup deadlines
da2e76fff chore: begin CodexBar 0.56.1 development
```
