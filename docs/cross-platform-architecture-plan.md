# CodexBar 跨平台架构方案

## 项目概述

将 CodexBar（macOS 菜单栏 API 用量监控工具）扩展为跨平台应用，支持 iOS 和 Android，同时保持 macOS 全部功能不变。

---

## 支持平台

| 平台 | 状态 | 最低版本 | UI 范式 |
|------|------|----------|---------|
| macOS | 生产环境 | macOS 14 (Sonoma) | 菜单栏 + SwiftUI |
| iOS | 已完成架构 | iOS 17 | Tab 导航 + SwiftUI |
| Android | 架构就绪 | — | Skip 框架 (SwiftUI → Jetpack Compose) |
| Linux | CLI 支持 | — | 命令行 |

---

## 模块架构

```
CodexBar/
├── Sources/
│   ├── CodexBarCore/          # 跨平台共享核心（18K+ LOC）
│   │   ├── Providers/         # 23 个 Provider 的抓取逻辑
│   │   ├── Platform/          # 平台抽象层（新增）
│   │   ├── Logging/           # 结构化日志
│   │   ├── Config/            # 配置管理
│   │   └── WebKit/            # Web 抓取工具
│   │
│   ├── CodexBarMobile/        # 共享移动端 UI（新增）
│   │   ├── Dashboard/         # 用量卡片视图
│   │   ├── Navigation/        # Tab 导航
│   │   ├── ProviderDetail/    # Provider 详情
│   │   └── Settings/          # 移动端设置
│   │
│   ├── CodexBariOS/           # iOS App 入口（新增）
│   ├── CodexBar/              # macOS App（18K+ LOC）
│   ├── CodexBarCLI/           # 命令行工具
│   ├── CodexBarWidget/        # macOS WidgetKit 扩展
│   └── ...
```

### 模块依赖关系

```
macOS App:
  CodexBar → CodexBarCore

iOS App:
  CodexBariOS → CodexBarMobile → CodexBarCore

Android App (Skip):
  CodexBariOS (复用) → CodexBarMobile → CodexBarCore
```

---

## 平台抽象层

### PlatformCapabilities

运行时检测平台能力，决定可用的抓取策略：

| 能力 | macOS | iOS/Android |
|------|-------|-------------|
| CLI 访问 | ✅ | ❌ |
| 浏览器 Cookie | ✅ | ❌ |
| WebKit 抓取 | ✅ | ❌ |
| 安全存储 (Keychain) | ✅ | ✅ |
| OAuth/API 调用 | ✅ | ✅ |

### Provider 可用性分类

- **fullNative** — 全平台可用（OAuth/API 方式）
- **limitedNative** — 部分功能仅桌面端
- **desktopOnly** — 需要桌面端完整能力
- **syncedFromMac** — 未来通过 Mac 同步

### 全平台支持的 Provider（10 个）

Claude、Codex、Copilot、Gemini、MiniMax、Kimi、Kimi K2、z.ai、Warp、Vertex AI

### 仅桌面端 Provider

Factory/Droid、JetBrains AI、Augment、OpenCode、Kiro、Antigravity 等（依赖 Cookie/CLI/本地文件）

---

## 抓取策略管线

```
Provider Fetch Pipeline:
  1. 根据 PlatformCapabilities 过滤可用策略
  2. 按优先级依次尝试：OAuth → Web → CLI → 本地探测
  3. 成功 → 返回结果
  4. 失败且 shouldFallback → 尝试下一策略
  5. 无可用策略 → 返回 noAvailableStrategy 错误
```

移动端自动跳过不可用的策略（Cookie、WebKit、CLI），无需硬编码平台判断。

---

## 数据源协议

```swift
protocol UsageDataSource {
    func fetchSnapshots(for providers: [UsageProvider]) -> [UsageProvider: UsageSnapshot]
    func fetchStatuses(for providers: [UsageProvider]) -> [UsageProvider: ProviderStatusSnapshot]
}
```

- **DirectFetchDataSource** — 直接 HTTP/OAuth 调用（移动端默认）
- **MacSyncDataSource** — 未来：从配对的 Mac 接收数据

---

## 实施阶段

### Phase 0 ✅ 已完成
- `#if os(macOS)` 条件编译隔离 macOS 专属依赖
- SweetCookieKit 设为条件依赖
- Package.swift 添加 iOS 17 平台目标
- CodexBarCore 解耦为跨平台可编译

### Phase 0.2-0.3 ✅ 已完成
- 平台抽象层（`CodexBarCore/Platform/` 下 5 个新文件）
- `PlatformCapabilities` 注入到 `ProviderFetchContext`
- Provider 可用性分类系统
- 数据源协议设计

### Phase 1-2 ✅ 已完成
- 共享移动端 UI 模块 `CodexBarMobile`
- iOS App 入口 `CodexBariOS`
- 移动端优化视图（Tab 导航替代菜单栏）
- `MobileUsageStore` 可观察状态管理

### Phase 3-5 🔮 未来规划
- Mac ↔ 移动端数据同步
- Android 完整发布（通过 Skip 框架）
- 多账号管理
- 高级分析和费用追踪

---

## 关键设计原则

1. **共享核心，平台特定 UI** — CodexBarCore 完全跨平台，UI 按平台各自实现
2. **Swift 6 严格并发** — 所有平台类型标记 `Sendable`，显式 `@MainActor`
3. **能力驱动** — 运行时检测能力，策略自动过滤，Provider 逻辑中无硬编码平台判断
4. **隐私优先** — Keychain 存储敏感数据，可选 Cookie 访问仅限 macOS
5. **可扩展 Provider 系统** — 基于协议的策略模式 + 宏注册

---

## 仓库迁移

跨平台架构代码已从 `CodexBar` 迁移至独立仓库 `CodexBar-Mobile`：

```bash
# 1. 克隆原始仓库
git clone https://github.com/o1xhack/CodexBar.git CodexBar-Mobile
cd CodexBar-Mobile

# 2. 切换到跨平台架构分支
git checkout claude/cross-platform-architecture-AocZK

# 3. 添加新仓库 remote
git remote add mobile https://github.com/o1xhack/CodexBar-Mobile.git

# 4. 推送为新仓库的 main
git push mobile claude/cross-platform-architecture-AocZK:main

# 5. origin 指向新仓库
git remote set-url origin https://github.com/o1xhack/CodexBar-Mobile.git
git remote remove mobile

# 6. 本地切换到 main，清理旧分支
git checkout -b main origin/main
git branch -d claude/cross-platform-architecture-AocZK
```
