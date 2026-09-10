# 上游十版本 Mac→iOS 影响独立审计

Status: `reviewed`（两项生产缺陷已修复并代码复核；测试执行、签名与矩阵状态以 03 为准）

## 范围与证据

逐段读取 `04-upstream-release-notes.md` 的 v0.56.1–v0.58.0 十个正式 release；对照当前 `SyncCoordinator.swift`、Shared payload、`ProviderSnapshotMerger.swift`、iOS 展示与存储代码。此次只做代码审计，未编译、未访问真实账户、未运行 CloudKit 或设备矩阵。上游原文和 PR 号由 04 文档保留。

## 逐版本通道分类

| 版本 | 影响 iOS 的数据变化 | 当前通道与限制 |
|---|---|---|
| 0.56.1 | Codex/Antigravity 历史完整性、unknown 成本、时间区间；Cursor auth 解析；Kimi alias 定价 | Mac parser/cost scanner 产出经 `mapLocalCostSummary`、共享 cost/coverage/dayKey 进入 iOS；iOS 不执行本地日志或认证扫描。Mac 菜单尺寸、Keychain 与 diagnostics 为 Mac 行为。 |
| 0.56.2 | token 类别、reasoning、requests、pricing coverage 合并/缓存；Codex reset；OpenCode Go estimated quota | 已有 tokenMix/coverage，加本轮 daily requestCount/tokenCountIsKnown；OpenCode Go iOS 未生成该 provider 的 pace/runout，保留窗口和置信度。图表 endpoint/native scan deadline 为 Mac 行为。 |
| 0.56.3 | Grok 已知0与缺失、Ollama monthly credits、同邮箱 Codex workspace、Poe daily | primary/extra windows 保留 upstream 值；本轮 Ollama primaryLabel 使用 upstream descriptor；Codex 走 account identity/workspace 专用通道。原生菜单缓存与 Keychain 重试在 Mac 生效。 |
| 0.56.4 | Codex selected workspace、Antigravity timestamp 恢复、Claude 缓存与错误 | 同步已解析 usage/cost，保留 upstream updatedAt；不在 iOS 重新解析 auth/default workspace。About、titlebar、status position、Linux discovery 为 Mac 行为。 |
| 0.56.5 | Codex cap/balance 独立时间与确认0、Antigravity per-turn dates、Claude stale source、z.ai reset | 本轮 credits observation、providerAmount.observedAt 与零余额映射；cap 的独立 freshness 已补 optional observedAt 与独立排序，见下。窗口 reset/sourceLabel/details 走已有字段；catch-up thermal/menu scrolling/Tailscale 为 Mac 行为。 |
| 0.56.6 | Codex subscription dates、Kimi membership、Kiro unknown metrics、cost pricing | subscriptionRenewsAt/ExpiresAt 已直接映射，SwiftData 保留，ProviderUsageView 展示；Kimi planName 与 named windows、Kiro generic details/usageKnown 走通用 lane。无需新增 provider 专用 CloudKit 字段。 |
| 0.56.7 | Command Code monthly unavailable、Moonshot CNY/deficit、ElevenLabs error；widget age | Command Code named window 的 usageKnown 已映射；本轮 Moonshot 解析 CN¥、0、负值；错误走 isError/statusMessage。上游 macOS Widget 时间刷新不等于 iOS Widget 实测。 |
| 0.56.8 | Copilot identity、OpenRouter overflow、Poe周窗口、MiMo malformed rows、Codex403、Claude quota labels | upstream provider/account refresh 先处理，再经现有 usage/details/accountRecordKey 通道；未额外把 Enterprise host/login 作为跨 Mac 合并凭据。不会在 iOS 重做认证恢复。上游 provisioning team 分流不替代 fork Production profile。 |
| 0.57.0 | Claude daily/models、unknown overflow、multi-account cached timestamps、Copilot Enterprise、Antigravity dedup、Kiro region | 已有 daily/modelBreakdowns/tokenMix/details/usageKnown/lastUpdated；本轮不把 iOS 当前同步窗口冒充 CLI All-history 或完整历史账本。Sparkle、macOS chart hover/menu layout、process cancellation、Linux cache 在 Mac 本体生效。 |
| 0.58.0 | daily tokens/requests/spend、Codex inherited row exclusion、整数格式化 | 本轮 SyncedDailyActivityView 展示当前 Mac sync window；三条 daily mapper 透传 requests/token known 标记，iOS 多 Mac 聚合处理 unknown/overflow。session-only fallback 已显式保留 unknown token 与 session requests，见下。menu row visibility、percent selector、countdown layout 是 Mac UI 偏好，不删除 iOS 原始数据。 |

## 已修复发现与复核

1. **Codex monthly cap 的独立 freshness 在 wire 丢失。** `SyncCoordinator` 构造 `SyncBudgetSnapshot` 没有传入 `providerCost.updatedAt`；Shared budget 无时间字段；iOS merger 用 `ProviderUsageSnapshot.lastUpdated` 选 budget。Mac A quota 12:00 / cap 09:00、Mac B quota 11:00 / cap 10:00 时会选 A 的旧 cap。#3296 修复要求 cap 与余额各自依据观测时间，不能只修余额。建议新增 optional budget observedAt，按 cap 时间合并，旧字段缺失回退 quota 时间并明确旧 writer 局限。

2. **session-only fallback 会把未知 token 变成已知0。** `ProviderSnapshotMerger` 在 sibling daily row 存在、另一 source 只有 `sessionCostIsKnown == true` 时构造 daily point，`totalTokens: summary.sessionTokens ?? 0` 没有设置 `tokenCountIsKnown`。新 daily view 将 nil 标记当旧格式已知值，显示0。建议显式传入 `summary.sessionTokens != nil`，覆盖已知费用、未知tokens、跨Mac汇总场景。

## Schema、旧版本及矩阵残余

- 本轮新增 optional Codable 内嵌字段；`SwiftDataBridge` 的完整 providerPayloadData 保留 nested 数据。结构上可让旧 reader 忽略新增字段、新 reader 接受缺失字段，但不能替代旧 binary 的实际解码测试。
- CloudKit deploy 结论需以最终 CKRecord 顶层字段写入差异审计为准；新增 JSON nested 字段本身不要求新增 CloudKit column。
- `03-testing.md` 当前16行仍是 pending，不能在此次代码审计中改成通过。每行须有旧/新二 writer、独立二 reader 的执行或替代证据。
- 必须显式保留的剩余风险：旧 reader 不理解 observedAt；旧 writer 不提供真实 cap/balance/daily token-known 时间或标记；真实 push、独立缓存、并发写与离线后收敛未被纯模型 fixture 验证。未知不能用0占位掩盖。
- 新 daily UI 只呈现同步的当前窗口；长期 CostLedger 请求历史回填、完整历史导入和 iPhone 重分桶不在此次实现承诺内，界面已有窗口说明。


## 修复后完整路径复核

- `SyncBudgetSnapshot.observedAt` 为 optional，旧 JSON 缺失字段可解码；`SyncCoordinator` active 与 token-account 两处 budget 都使用 cost 本身的 `updatedAt`。`latestBudget` 与 `latestProviderAmount` 分别排序，可独立选 cap 与余额，不再依赖 quota 时间。相同观测时间用 device ID 稳定打破平局。
- session-only fallback 已传入 `sessionRequests` 和 `tokenCountIsKnown: sessionTokens != nil`；daily 聚合任一 unknown 或溢出使对应计数不可用。三条 Mac daily mapper 已覆盖，Shared 自定义 decoder 使用 decodeIfPresent，编码保留新字段。
- 全部生产 `SyncDailyPoint` 构造器已检索。剩余 `CostLedgerService.toDailyPoint` 不携带新字段，是既有长期账本 rollup；`ProviderDetailView` 的新日表直接使用 `provider.costSummary`，不经过账本回放。不得把本轮能力宣传为长期请求历史已回填。
- `SyncedDailyActivityView` 对 nil/负 requests、显式未知 token、未知/非有限 cost 显示 unavailable，确认0保留0；默认7日、展开全部当前窗口，无数据时不渲染日表。使用 API 与项目 iOS 17 deployment target 相容。布局可水平/垂直切换；此次未做视口验证。
- 新 budget/amount fixture 使用 quota 时间比观测时间更新的竞争 writer，并反转输入顺序；旧 budget 缺字段解码已有覆盖。建议在执行最终测试前补 session-only unknown-token 的确切回归用例，避免只靠代码审计。
- 新 reader 遇到旧 writer 无 observedAt，仍必须回退旧 quota 时间；旧 reader 忽略 observedAt，也不会获得新排序。不能将这类混合组合描述为具备与全新端完全相同的 freshness 保证。16组合替代 fixture 的 narrow old-reader decoder 不是完整旧 binary，也不验证 CloudKit 推送和持久缓存迁移。
- 本轮复核后未发现新的生产代码阻塞。未编译、未执行测试；“代码复核通过”不等于测试与发布 gate 通过。
