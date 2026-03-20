# CodexBar — Project Overview

CodexBar is a macOS menu bar app that tracks AI coding tool usage (Claude, Codex, Cursor, etc.). It has an iOS companion app that syncs data from Mac via iCloud.

- **We only work on the iOS app.** Mac-side code is maintained upstream — do not modify Mac-only files unless explicitly asked.
- iOS project lives in `CodexBarMobile/`.
- Shared sync layer lives in `CodexBarMobile/Shared/` (used by both Mac and iOS).

## Repositories

| Remote | Repo | Role |
|--------|------|------|
| `upstream` | steipete/CodexBar | Original open-source repo, read only |
| `origin` | o1xhack/CodexBar | Our fork |
| Branch | `mobile-dev` | Main working branch |

## Workflow

**All development follows the 7-step workflow defined in [`AGENTS.md`](AGENTS.md).**

Quick summary:

> Research → Design → Implementation → Testing → Documentation → Commit → Push & Release

See `AGENTS.md` for the full process, rules, and checklists.

## Key File Locations

| Path | Purpose |
|------|---------|
| `AGENTS.md` | Complete development workflow and agent rules |
| `CodexBarMobile/Research/` | Feature research documents ([index](CodexBarMobile/Research/README.md)) |
| `CodexBarMobile/project.yml` | Build number (`CURRENT_PROJECT_VERSION`) and version (`MARKETING_VERSION`) |
| `CodexBarMobile/CHANGELOG.md` | iOS changelog (technical, Keep a Changelog format) |
| `CodexBarMobile/CodexBarMobile/ContentView.swift` | Main views, settings, in-app release notes (`MobileReleaseNotesCatalog`) |
| `CodexBarMobile/CodexBarMobile/Localizable.xcstrings` | All translations (JSON, 4 languages) |
| `CodexBarMobile/CodexBarMobile/Views/` | Feature views (provider detail, usage cards, onboarding) |
| `CodexBarMobile/CodexBarMobile/Models/` | Data models and formatters |
| `CodexBarMobile/CodexBarMobile/Preview Content/PreviewData.swift` | Demo / preview data |
| `CodexBarMobile/Shared/` | Shared iCloud sync layer |
| `plan.md` | 项目计划与功能进度跟踪 |

---

## 协作模式（iSparto）

本项目支持 Agent Teams 多角色协作。以下定义各角色职责和触发条件。

### 角色定义

| 角色 | 职责 | 说明 |
|------|------|------|
| **PM（产品经理）** | 需求分析、功能优先级、验收标准 | 由用户担任 |
| **Architect（架构师）** | 技术方案设计、调研文档 | 对应 Step 1–2（Research + Design） |
| **Developer（开发者）** | 编码实现、测试 | 对应 Step 3–4（Implementation + Testing） |
| **Release Engineer** | 文档更新、版本管理、发布 | 对应 Step 5–7（Documentation + Commit + Push） |

### 触发条件表

| 用户指令 | 触发角色 | 执行动作 |
|----------|----------|----------|
| 调研 / research | Architect | 执行 Step 1–2，输出 Research/ 文档 |
| 开发 / implement | Developer | 执行 Step 3–4，编码 + 测试 |
| 提交 | Release Engineer | 执行 Step 6a–6c（bump + changelog + jj commit） |
| 提交推送 | Release Engineer | 执行 Step 6a–6d（+ push） |
| 上传 / Archive | Release Engineer | 执行 Step 7（archive + TestFlight） |
| 安装到手机 | Release Engineer | xcodebuild 直连真机安装 |

### 分支策略

| 分支 | 用途 |
|------|------|
| `mobile-dev` | 主开发分支，所有 iOS 开发在此进行 |
| `main` | 上游同步分支，不直接修改 |

使用 jj bookmark 管理分支指针，详见 `AGENTS.md`。

### 操作护栏

- **不修改 Mac 端代码**：`Sources/`、`Tests/` 下的文件属于上游，只读
- **不推送到 upstream**：只推送到 `origin`（o1xhack/CodexBar）
- **不跳过本地化**：所有用户可见文本必须包含 4 种语言
- **不跳过版本号**：每次提交必须 bump `CURRENT_PROJECT_VERSION`
- **不手动编辑 .xcodeproj**：通过 `xcodegen generate` 从 `project.yml` 生成
