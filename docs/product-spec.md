# CodexBar Mobile (iOS) — Product Spec

> Product behavior in code must follow this document. When modifying product requirements, update this document first, then change the code.

---

## Product Overview

### Target Users

使用多个 AI 编程工具（Claude, Codex, Cursor, ChatGPT 等）的开发者，希望在 iPhone 上随时查看各工具的用量和费用。

### Core Value

在 iPhone 上实时查看 Mac 端 CodexBar 同步过来的 AI 编程工具用量和费用数据。

### Product Scope

| In Scope | Out of Scope |
|----------|--------------|
| 通过 iCloud 接收 Mac 同步的用量/费用数据 | 直接从 AI Provider API 获取数据 |
| Provider 用量卡片、费用仪表盘、交互式图表 | Mac 端数据采集和存储逻辑 |
| 一键分享费用报告图片 | 账户登录/认证流程 |
| 4 语言本地化（en/zh-Hans/zh-Hant/ja） | 除这 4 种外的其他语言 |
| iPhone 适配 | iPad 专用布局（暂不做） |

---

## Page Structure

### Page Overview

| Page | Entry Point | Description |
|------|-------------|-------------|
| Usage Tab | 底部 Tab 栏 "用量" | Provider 列表，每个展示实时 rate limit 进度条 |
| Cost Tab | 底部 Tab 栏 "费用" | 费用仪表盘：概览、趋势图、Provider/Model 占比 |
| Settings Tab | 底部 Tab 栏 "设置" | 显示偏好、图表样式、隐私、关于、Release Notes |
| Provider Detail | 点击 Provider 卡片 | 单个 Provider 的详细 rate limit + 日费用图表 + 预算 |
| Share Sheet | Cost Tab → 分享按钮 | 选择 Today/7d/30d → 预览卡片 → 系统分享 |
| Onboarding | 首次启动（无 iCloud 数据时） | 3 步引导设置 iCloud 同步 |

### Usage Tab

**功能：** 展示所有已同步 Provider 的实时用量

**页面元素：**
- Provider 卡片列表（按 Provider 排列）
- 每张卡片：Provider 名称、账户邮箱、登录方式（Max/Pro/Business 等）
- Rate limit 进度条（Session、Weekly、Opus 等动态窗口）
- 费用摘要行（今日: $X · 30天: $Y）
- 点击展开 Provider 详情页

**交互规则：**
- 下拉刷新 → 请求 iCloud 同步 → 更新数据
- 切换"显示剩余"设置 → 进度条显示已用%或剩余%

### Cost Tab

**功能：** 综合费用仪表盘

**页面元素：**
- 概览卡片（30天总额、今日、最高来源、活跃天数）
- 日费用趋势图（折线/柱状图可切换，30 天横向滚动，长按查看详情）
- Provider 占比（前 6 个 Provider，彩色进度条）
- Model Mix（模型费用占比）
- Service Mix（服务费用占比，仅 Codex）
- Budget 列表（有预算的 Provider 进度条）
- 右上角分享按钮

**交互规则：**
- 长按图表 → 显示该天的具体费用和 Token 数
- 点击分享按钮 → 弹出 Share Sheet

### Share Sheet

**功能：** 生成并分享费用报告图片

**页面元素：**
- Segmented Picker（Today / 7 Days / 30 Days）
- 卡片实时预览
- ShareLink 按钮

**交互规则：**
- 切换 Picker → 实时刷新预览卡片
- 点击 Share → 调用系统分享（AirDrop、社交媒体、保存图片等）

**分享卡片规格：**
- 尺寸：390×520pt（@3x = 1170×1560px）
- Today：Provider 明细 + 占比条 + Top Models
- 7d/30d：堆叠柱状图（按 Provider 着色，最大在底部）+ 指标行
- 底部：QR 码 + CodexBar 品牌
- Provider 数量限制：前 3 + "Others"

---

## Interaction Flows

### iCloud 同步流程

```
Step 1: 用户打开 App
    -> App 读取 iCloud KVS 中的 snapshot
    -> 渲染 Provider 卡片和费用数据
Step 2: Mac 端 CodexBar 更新数据
    -> 自动推送到 iCloud KVS
    -> iOS 收到通知 → 刷新 UI
Step 3: 用户下拉刷新
    -> 主动请求 iCloud 同步
    -> 更新数据显示
    -> 异常：iCloud 配额超限 → 显示错误提示
```

### 费用分享流程

```
Step 1: 用户在 Cost Tab 点击分享按钮
    -> 弹出 Share Sheet（默认 30 Days）
Step 2: 用户选择时间段（Today / 7d / 30d）
    -> 实时渲染对应的卡片预览
Step 3: 用户点击 Share
    -> ImageRenderer 生成 PNG（@3x）
    -> 调用系统分享（UIActivityViewController）
```

---

## Feature List

| Feature | Priority | Status | Description |
|---------|----------|--------|-------------|
| iCloud 数据同步 | P0 | Implemented | 通过 NSUbiquitousKeyValueStore 接收 Mac 端数据 |
| Provider 用量卡片 | P0 | Implemented | 实时 rate limit 进度条 + 账户信息 |
| Cost 仪表盘 | P0 | Implemented | 概览、趋势图、占比分析 |
| 交互式图表 | P0 | Implemented | 折线/柱状图、长按查看、横向滚动 |
| 4 语言本地化 | P0 | Implemented | en/zh-Hans/zh-Hant/ja |
| 一键分享费用卡片 | P1 | Implemented | 3 种时间段、堆叠图表、QR 码 |
| Daily Utilization Chart | P1 | Blocked | 等上游 PR #565 合并 |
| Widget 桌面小组件 | P2 | Pending | 显示当日/当周费用摘要 |
| iPad 适配 | P2 | Pending | 利用大屏展示更丰富图表 |

---

## Copy Guidelines

### Fixed Copy

| Location | Copy | Description |
|----------|------|-------------|
| Share Sheet 标题 | "Share Cost Report" | 分享弹窗导航栏标题 |
| 分享卡片顶部 | "AI CODING SPEND" | 所有卡片共用标题 |
| QR 码旁文字 | "Track your AI coding costs" | 品牌引导语 |
| Provider 合并标签 | "Others" | 第 4+ Provider 合并显示 |

### Localization

4 种语言：English、简体中文、繁体中文、日本語。所有用户可见文本通过 `String(localized:)` + `Localizable.xcstrings` 管理。

---

## Notifications & Messages

| Trigger Scenario | Notification Type | Content | Description |
|------------------|-------------------|---------|-------------|
| iCloud 同步失败 | In-app banner | 同步错误详情 | 显示在 Usage Tab 顶部 |
| iCloud 配额超限 | In-app banner | "iCloud 存储配额已满" | 提示用户清理空间 |

---

## Permissions & Roles

| Role | Accessible Pages | Allowed Actions |
|------|-----------------|-----------------|
| 普通用户（唯一角色） | 全部页面 | 查看数据、刷新、分享、修改设置 |
