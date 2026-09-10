# 实现与合并记录

Status: `in-progress`（实现、最终测试与review完成，签名 draft 等待发布凭证授权）

## Git 与范围

基线 `431a8531a`，第一项写操作创建 `upstream-sync/v0.58.0-mobile.1.23.0`。
研究设计先提交 `1647279a2`，之后 `git merge --no-commit --no-ff v0.58.0`，按 hunk 解决30个冲突。
完整上游第二 parent 为 `88fa2f45fa1e7e04c3c96234ddf973ca947208db`。
无 upstream push、origin push、PR/远程 merge、tag publish 或 live feed 更改。

## Mac 冲突裁决

- README 与 appcast 保留 fork 字节；上游 v0.56.0→v0.58.0 README diff 为空。
- CI 保留 PR Fast / merge-only heavy 策略与 fork monitor；吸收新版 checkout pin。
- 发布、package_app、Production entitlements、版本方案保留 fork；签名 mock 测试改为验证 fork team/profile 路径，而不是恢复 upstream profile。
- 删除上游已移除的 About.swift；新 Form 迁入 fork 下载、版本和构建信息，移除冲突造成的重复更新入口。
- CLI login 吸收 CLILoginRunner，保留 ProcessTermination 和有界 WallClockTimeout，避免重复 timer 与取消后遗留子进程。
- token account publication 保留 Bool 返回及 fork sync 清理边界；不把上游 void 签名直接套到 fork。
- parser 保留 fork route-safe estimated pricing、priority cache metadata、coverage/overflow 语义；吸收上游增量扫描、append/replace、跨重启报告、fork boundary、未知计数及安全修复。
- 删除合并产生的重复 CodexRowCostBreakdown；让 amount 与 estimated provenance 共用同一不可变 catalog/resolver，修复每行重新加载 catalog 的性能回归。
- Codable ModelBreakdown 显式保留 isEstimated；兼容 hash allowlist 合并去重。parserLogicVersion 14→15，并重新生成源文件 hash（最终值见03）。
- 架构 gate 迁移唯一/上下文锚点，原83残余用原HEAD scanner+源码独立复现；新增分支逐条审查，不用扩大整体容忍数绕过检查。详见07。

## Mac→iOS 通道

所有新字段仍在 `DeviceProviderSnapshot.payload` 压缩 JSON 内，providerPayloadVersion=1。

| 数据 | Producer | Shared | Reader |
|---|---|---|---|
| Codex购买余额 | attach活动credits；observeLoop跟踪credits；inactive账号读各自snapshot | SyncProviderAmount.observedAt? | 按余额时间合并，保留确认零，Credits按点数显示 |
| 月度cap | 两budget mapper传providerCost.updatedAt | SyncBudgetSnapshot.observedAt? | 按cap自身时间选择，旧payload回退quota时间 |
| 日请求/未知token | 普通token、Codex dashboard fallback、Mistral三mapper | SyncDailyPoint.requestCount?/tokenCountIsKnown? | checked聚合；缺失/溢出不伪装成已知值；session fallback同样保留unknown |
| Ollama月度额度 | 使用descriptor语义label | 既有rateWindows | 显示月度label而非误标Session |
| Moonshot余额 | 解析CN¥/CNY/¥/USD/$/€、分组逗号、符号前负号 | 既有Moonshot余额结构 | 零/负余额可见 |

新日表直接读 provider.costSummary，默认7天、可展开同步窗口全部日期，按producer dayKey排序，
不使用iPhone时区重分桶。长期CWL旧条目没有日请求字段；本轮不回填/伪造历史请求计数。

## iOS

候选1.24.0 (198)，project.yml四targets一致，经xcodegen生成；未手改xcodeproj。
新增日表、余额/额度语义、混合Mac freshness、四语言文案、CHANGELOG与同一1.24 release notes块。
已存在的动态details/rateWindows、provenance、coverage、timezone、account records承接其他上游数据。
Mac菜单布局/可见行/CLI认证/本地扫描不是iPhone操作，边界与十版本分类见06。

## Review修复

1. 初轮发现重复类型、About重复入口、返回签名与pricing resolver不兼容：已修复并构建。
2. 性能测试发现catalog查找按行增长：复用resolver后focused性能断言通过（最终测试见03）。
3. bridge review发现credits-only刷新未触发sync、余额独立时间丢失：已修并加观察者与混合writer测试。
4. iOS review发现cap时间同样丢失、session fallback把未知tokens显示0：已修并补精确回归。
5. 全量第52组发现Kiro API enabled但无cap时，合并条件错误隐藏已知usage/cost；恢复enabled独立于cap，保留cap门控窗口/余额，20项定向测试通过，最终全量重跑。
6. 全量本地化严格key-set测试发现土耳其语遗留quota_warning_session_capitalized，英文/源码均已移除；删除弃用键，34项定向测试与22语言目录检查通过。
7. 旧reader不能理解新freshness：作为旧客户端固有限制明确记录，不宣称旧版本拥有新语义。

## 发布边界

候选Mac 0.58.0.1 / build141.1 / Mobile1.23.0 / Sparkle141.1.1.23.0。
禁止执行会force-push tag的release.sh phase1。签名、公证、Sparkle签名与GitHub draft资产工作
在本地测试和review完成后，按用户Goal要求取得发布凭证授权。未授权前不调用Keychain/notary私钥。
