# 2.0 TestFlight 准备

Status: uploaded（2.0.0 / 200：VALID，IN_BETA_TESTING）。

下文“已完成/审查与后续动作”保留历史准备过程；最终结果以末尾发布闭环为准。

## 本次授权
用户要求完成更新说明后上传TestFlight，上传本身已授权。随后用户明确要求先完成 iOS PR / CR，分支 push 与 PR 审查现已授权。PR：https://github.com/o1xhack/CodexBar-Mobile/pull/123 。

## 已完成
- 四语言商店/TF更新说明已生成：`CodexBarMobile/AppStoreMetadata/2.0.0/{en-US,zh-Hans,zh-Hant,ja}/release_notes.txt`。与MobileReleaseNotesCatalog使用同一组已翻译文案，不声称历史费用差额已修复。
- ASC只读确认：bundle `com.o1xhack.codexbar.mobile`，app ID `6760216772`。最高现有build 199 VALID；1.24.0当前READY_FOR_SALE。未创建2.0商店版本或修改线上metadata。
- `bash Scripts/lint.sh audit-i18n`通过，331个源key齐全，四语言translated。
- `xcodegen generate --spec CodexBarMobile/project.yml`无生成差异。
- Release archive成功：`/tmp/CodexBarMobile-2.0.0-200.xcarchive`；日志 `/tmp/cbm-2-archive.log`。
- 主App、Widgets、PushExtension均2.0.0(200)。归档应用`codesign --verify --deep --strict`通过，CloudKit entitlement为Production。
- AppIcon源图1024x1024，无Alpha；归档编译图120x120，无Alpha，解码查看内容正确。尚未上传，因此没有Apple处理后的CDN图标证据。
- 归档主可执行SHA-256：`bbd63c4ee8fda01eab3a29c4f098ed6f986797e149409e646960b409d8a2296f`。应用代码为d92c5008e，后续本次修改仅发布说明和证据文档。

## 审查与后续动作
- 2026-09-11：feature/ios-2-token-activity 已推送 origin，PR #123 以 mobile-dev 为 base；已请求 GitHub Codex review。
- 当前提交的审查、Fast Checks 与全部 review thread 必须通过，才可继续 TestFlight。任何修复 push 后重新请求 review。
- 用户明确不使用 Claude。旧 Opus 4.7 要求来自 fork 提交 e275f0233（2026-05-26），本轮已移除该专属门槛，保留完整 Codex PR review gate；无需 Claude 登录。
- Todoist Dev 已记录本轮 PR / TestFlight，保持 In Progress。

本地归档并不等于上传成功；尚未执行 export/upload、merge、tag 或 live release。真实费用差额与实体设备同步/性能验收仍按03-testing保留，TF阶段也不得声称已解决。

## 当前发布候选
- Cost 主页面为总 Token 卡片，点入 Provider 热力图；四语言说明与该布局一致。
- 本轮 CR 修复 catch-up 刷新、未知/零、365 天补齐与完整 Token 聚合溢出边界；最新完整回归为 742 项单元测试与 2 项 UI 测试通过，详见03-testing。
- 上传前按最终审查提交重新生成归档；本节前述 d92c5008e 及中间归档仅为历史准备证据，不可作为最终上传产物。
- 最终 current-head clean、review gate、CI 与上传回读结果继续记录到 PR #123，避免以尚未完成的结果预填已通过。


## 2026-09-11 发布闭环
- 用户明确授权 merge #123 后上传 TF，并明确 TF 不以 PR/CR/merge/远端 CI 为前置条件；后续合并和公开发布 gate 保留。
- PR #123 已 squash merge 到 mobile-dev：f9a5754583e89e33acf5582ac19fcc70aab3a2c1；与审查 head b8c0c0e5e3cbbfd924f0cecf7991f69caa4fc609 tree 完全一致。
- 六轮 CR 最终 clean、0 unresolved，架构复盘已记录；Final CI 34657352376 success。
- 上传归档：`/tmp/CodexBarMobile-2.0.0-200-b8c0c0e5e.xcarchive`；`/tmp/cbm-2-upload.log` 显示 EXPORT SUCCEEDED / Upload succeeded。
- ASC app 6760216772，iOS train 2.0.0，build 200，ID 4e53fcca-dd57-45ee-b360-04a692c8f52a，processingState VALID，internalBuildState IN_BETA_TESTING。
- Internal 组 hasAccessToAllBuilds=true；读取组 builds 确认包含200。未提交外部 Beta Review、App Review 或 live release。
- en-US / zh-Hans / zh-Hant / ja betaBuildLocalizations 已通过 API 写入，并与版本目录四份更新说明逐字比对一致。
- 源图及 archive 图标此前已视觉核对；本次 altool build-status 的 iconAssetToken 已在 Aside 打开，实际 Apple CDN 图标视觉正确。截图：`/Users/yuxiao/.aside/u/0/sessions/2026-09-11_19B1vTfBR0fpLH0N/tmp/cbm-2-cdn-browser.png`。
- 新 TF 工作流同步至 AGENTS.md、codexbar-git-workflow/SKILL.md 与 RELEASE-CHECKLIST.md。仍保留本地测试、版本、四语言、签名与 Production 检查；上传不代表合并/公开发布授权。
- 真机费用差额与实体多设备验收仍未完成，不因 TF 可用而宣称已修复。
