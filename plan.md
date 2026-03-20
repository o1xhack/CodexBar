# CodexBar Mobile — 项目计划

> 最后更新：2026-03-20 · 当前版本：1.0.0 (15) · 分支：mobile-dev

## 项目概况

CodexBar Mobile 是 CodexBar（macOS 菜单栏应用）的 iOS 伴侣应用，通过 iCloud 同步展示 AI 编程工具的用量和费用数据。

## 已完成功能

| 版本 | 功能 | 状态 |
|------|------|------|
| Build 9 | iOS 伴侣应用基础架构、iCloud KVS 同步、Provider 卡片、Usage/Cost/Settings 三 Tab | ✅ 已发布 |
| Build 9 | Provider 详情页：交互式日费用图表、Token 统计、预算进度条 | ✅ 已发布 |
| Build 9 | Cost 仪表盘：Provider 占比、Model Mix、Service Mix、30 天趋势图 | ✅ 已发布 |
| Build 9 | 设置页：显示剩余/已用切换、图表样式、隐私遮罩、默认 Tab | ✅ 已发布 |
| Build 9 | 4 语言本地化（en/zh-Hans/zh-Hant/ja） | ✅ 已发布 |
| Build 9 | Onboarding 引导、Demo 模式、空状态页 | ✅ 已发布 |
| Build 10 | 日费用图表横向滚动（30 天 + 历史） | ✅ 已发布 |
| Build 11 | 用量/费用标签清晰度优化（固定宽度布局） | ✅ 已发布 |
| Build 15 | **Cost 分享卡片**：一键生成分享图片（Today/7d/30d）、堆叠柱状图按 Provider 着色、QR 码 | ✅ 已发布 |
| Build 15 | **调研文档框架**：Research/ 目录 + 状态追踪（draft → done → dropped） | ✅ 已发布 |
| Build 15 | **AGENTS.md 工作流**：完整 7 步开发流程定义 | ✅ 已发布 |

## 进行中 / 待开发

| 优先级 | 功能 | 状态 | 调研文档 | 备注 |
|--------|------|------|----------|------|
| P1 | Daily Provider Utilization Chart | `blocked-upstream` | [001](CodexBarMobile/Research/001-daily-utilization-chart.md) | 等待上游 [PR #565](https://github.com/steipete/CodexBar/pull/565) 合并 |
| P2 | 分享卡片细节优化 | 待用户反馈 | [002](CodexBarMobile/Research/002-cost-share-card.md) | Build 15 已发布，等真机测试反馈 |

## 待调研 / 候选功能

| 功能想法 | 说明 |
|----------|------|
| Widget（桌面小组件） | 显示当日/当周费用摘要 |
| Provider 对比视图 | 多 Provider 费用趋势叠加对比 |
| 费用预算预警推送 | 本地通知：月预算超 80% 时提醒 |
| 深色模式分享卡片 | 当前分享卡片仅白底，可增加深色风格 |
| iPad 适配 | 利用更大屏幕展示更丰富的图表 |

## 技术债 / 改进

| 项目 | 说明 |
|------|------|
| 分享卡片数据桥接 | 7 天 provider 费用目前按 30 天比例缩放，非精确每日 provider 分拆 |
| UI 测试覆盖 | 分享功能尚无 UI 测试 |
| 上游同步 | 当前基于 0.18.0，上游已推进到 0.19.0+ |

## 里程碑

| 里程碑 | 目标 | 状态 |
|--------|------|------|
| M1: App Store 初版 | iOS 伴侣应用上架 | ✅ 完成（Build 9） |
| M2: 分享与社交 | Cost 分享卡片 | ✅ 完成（Build 15） |
| M3: 利用率追踪 | 每日 Session 利用率图表 | ⏳ 等上游 PR |
| M4: Widget | 桌面小组件 | 📋 待规划 |
