# 设计与执行方案

Status: `ready`（用户 Goal 已确认）

## 合并与保留规则

以 published v0.58.0 为第二 parent 做本地 merge，不 squash 或整树 ours/theirs。
README.md 与 live appcast.xml 保持 fork 字节；单独审计 upstream README factual/security diff。
保留 fork CI Fast Checks / post-merge heavy policy、upstream-monitor、AGENTS、release pipeline、
Production signing、Mobile payload、parser hash 和 fork identity。逐 hunk 合并费用/账号/子进程冲突。
About.swift 被上游删除改用新 About pane，须迁移 fork version/download 文案而非保留重复入口。

## 数据审计与 iOS 方案

Mac→DeviceProviderSnapshot.payload→ProviderUsageSnapshot→iOS mapper/CWL/widgets 为主链。
逐项确认：Codex purchased balance/monthly limit，Moonshot CNY，Ollama included credits，
Command Code unknown monthly quotas，Kimi versions/details，Antigravity raw windows、Codex workspace 与
Copilot Enterprise identity、partial/unknown costs/request counts，cached snapshot measurement age。
动态 rateWindows/details/credits/costSummary 能表达时复用；缺失数据用 optional Codable 扩展，
保持 providerPayloadVersion=1。禁止发送 credentials、paths 或 raw transcript。
Daily ledger：已有 iOS CWL 日账本，审计其 tokens/request/cost/timezone/unknown 语义后补缺口。
Menu row visibility / percent window / reset layout 是 Mac UI 设置，默认不隐藏 iOS quota，保留原始数据。
Mac CLI breakdown/local scan/auth/OS/AppKit features 只通过结果影响 iOS，不在 iOS 执行本地扫描。

## 单版本方案

Mac MARKETING_VERSION=0.58.0.1；BUILD_NUMBER=141.1（上游 v0.58.0 为 141）；
MOBILE_VERSION=1.23.0（沿用现有配套版本，未把未上传 iOS 当作已发版本）；
Sparkle=141.1.1.23.0；candidate tag=v0.58.0.1-mobile.1.23.0。
UPSTREAM_VERSION=v0.58.0 / UPSTREAM_SYNC_DATE=2026-09-10。
iOS 最终候选 1.24.0 (198)，四 targets 同步；日请求明细与购买额度是功能新增，因此采用feature minor。
不因 checkpoint 增加用户可见版本。docs/versioning.md 后半旧决策树与顶部冲突时以顶部明确四段规则为准。

## 验证与 review

Mac build/lint/full unit tests；focused provider/parser/cost/account/Mobile sync/fleet tests；
禁止 live provider/Keychain prompt probe，使用 stubs/no-UI stores。
iOS simulator build、相关 unit/widget parity/localization tests；需要 UI 变更时补 simulator visual proof。
16-case gate 必须完整列出，两 writer IDs 与两个 reader caches；硬件不足采用真实测试支撑 substituted。
CloudKit audit 比较最后 published v0.56.0.1-mobile.1.23.0 与最终代码，检查直接 CK fields/types/zone/query。
按 merge / bridge / iOS 各阶段独立 agent review（可用模型，无 Opus tool 时如实标记替代），修复后复测。

## Draft 方案

release.sh phase1 包含 force tag push，不能执行。按已有 049 方案拆出 sign-and-notarize、
本地 candidate appcast 验签、GitHub unpublished draft API/资产上传、digest/source SHA readback。
使用发布凭证前按用户要求暂停取得授权，继续完成不依赖凭证的实现和测试。
未 push 的 source SHA 无法成为远程 target：draft 暂指已存在基线并在正文明确本地 source SHA；
发布前必须重新绑定最终远程提交并通过 exact-head PR gate。不发布 tag、不更新 live feed。
