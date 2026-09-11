# 2.0 TestFlight 准备

Status: in-review（PR #123；尚未上传）。

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
