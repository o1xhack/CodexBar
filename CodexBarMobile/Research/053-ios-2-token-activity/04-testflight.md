# 2.0 TestFlight 准备

Status: blocked-review-authorization（尚未上传）。

## 本次授权
用户要求完成更新说明后上传TestFlight，上传本身已授权。此前“不push/merge，除非明确要求”的限制仍在；当前分支没有PR，不能把TF授权自行扩展为push/merge。

## 已完成
- 四语言商店/TF更新说明已生成：`CodexBarMobile/AppStoreMetadata/2.0.0/{en-US,zh-Hans,zh-Hant,ja}/release_notes.txt`。与MobileReleaseNotesCatalog使用同一组已翻译文案，不声称历史费用差额已修复。
- ASC只读确认：bundle `com.o1xhack.codexbar.mobile`，app ID `6760216772`。最高现有build 199 VALID；1.24.0当前READY_FOR_SALE。未创建2.0商店版本或修改线上metadata。
- `bash Scripts/lint.sh audit-i18n`通过，331个源key齐全，四语言translated。
- `xcodegen generate --spec CodexBarMobile/project.yml`无生成差异。
- Release archive成功：`/tmp/CodexBarMobile-2.0.0-200.xcarchive`；日志 `/tmp/cbm-2-archive.log`。
- 主App、Widgets、PushExtension均2.0.0(200)。归档应用`codesign --verify --deep --strict`通过，CloudKit entitlement为Production。
- AppIcon源图1024x1024，无Alpha；归档编译图120x120，无Alpha，解码查看内容正确。尚未上传，因此没有Apple处理后的CDN图标证据。
- 归档主可执行SHA-256：`bbd63c4ee8fda01eab3a29c4f098ed6f986797e149409e646960b409d8a2296f`。应用代码为d92c5008e，后续本次修改仅发布说明和证据文档。

## 阻塞与后续动作
`gh pr list --head feature/ios-2-token-activity --state all`返回空。`docs/RELEASE-CHECKLIST.md`第6节与`.agents/skills/codexbar-git-workflow/SKILL.md`明确：当前head PR review gate未通过时禁止TestFlight上传。
需要用户补充授权发布所需的分支push、PR与审核后merge；随后跑当前head review/修复/复测，满足gate后继续已授权的TF上传，回读build VALID及beta可用状态，写入四语言beta更新说明。

本地归档并不等于上传成功；未执行export/upload、push、merge、tag或live release。真实费用差额与实体设备同步/性能验收仍按03-testing保留，TF阶段也不得声称已解决。
