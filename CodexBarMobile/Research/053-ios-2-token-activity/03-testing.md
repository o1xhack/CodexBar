# iOS 2.0 测试与兼容证据

Status: in-progress。本地 Simulator 使用合成 PreviewData，不能替代用户两台 Mac 的真实费用对账。

## 环境与命令
- 基线：871829af4；分支 feature/ios-2-token-activity。
- iPhone 17 Pro / iOS 26.5 Simulator `E1DD6B03-ACA4-4962-BA33-AF21EFB1B2BB`。
- `xcodegen generate`（CodexBarMobile目录），生成project，2.0.0(200)全部target一致。
- 测试：`xcodebuild test -project CodexBarMobile/CodexBarMobile.xcodeproj -scheme CodexBarMobile -destination 'platform=iOS Simulator,id=E1DD6B03-ACA4-4962-BA33-AF21EFB1B2BB' -derivedDataPath /tmp/cbm-2-build -only-testing:CodexBarMobileTests -packageAuthorizationProvider netrc`。
- UI测试必须完整指定 `CodexBarMobileUITests/CodexBarMobileUITests/testTokenActivityOverviewScrollsAndSelectsDay` / `testProviderTokenActivityReplacesDailyList`。只指定target/method可能运行0个UI测试，不能视为通过。
- lint：`PATH=/opt/homebrew/bin:$PATH bash Scripts/lint.sh lint`，工具复用已有lint-tools缓存。首次完整lint为2226文件零违规，四语言与source-key检查通过；重跑 `/tmp/cbm-2-lint-final.log` 退出0，同样2226文件零违规及四语言通过。

## 最终本地验证
- `/tmp/cbm-2-verified.log`：最终数据代码737 tests / 49 suites全部通过，包含旧库迁移、8项TokenActivity数据测试，以及后台worker短快照/暂缺来源时仍保留1200历史Token的断言。该次UI暴露夹具未写入ledger的问题，见下文，不把整包标为通过。
- `/tmp/cbm-2-fixture-ui.log`：**2 UI tests / 0 failures，TEST SUCCEEDED**；xcresult `/tmp/cbm-2-build/Logs/Test/Test-CodexBarMobile-2026.09.11_13-42-11--0700.xcresult`。覆盖日期精确点选、横向滑动、回到今天、去除旧展开入口、Codex详情包含Service Mix且Cost全局不包含。
- `/tmp/cbm-2-dark-large.log`：dark + accessibility-large，Provider横向浏览/回到今天测试通过。已检查[暗色大字号截图](evidence/provider-dark-large.png)；看到末端月份被裁切后将最后3周标签改为右对齐，最终标准字号截图验证月份完整。未声称已验证所有字号/小屏/iPad。
- [Cost总览](evidence/cost-overview-light.png)、[Provider与Service Mix](evidence/provider-light.png)、[横向回看历史](evidence/provider-older-history.png) 均为实际Simulator合成数据截图。
- `/tmp/cbm-2-target-lint-final.log`：显式检查7个新增/相关iOS文件，零违规。仓库默认SwiftLint只包含Sources/Tests；另外单独检查CostLedgerService时存在4项既有结构违规（3项参数数量、1项类型长度），用HEAD原文件 `/tmp/cbm-2-baseline-lint.log` 证实同4项原已存在。未把默认lint误报成全部iOS文件零违规。
- `git diff --check` 通过；本轮新的源字符串全部en/zh-Hans/zh-Hant/ja translated。

UI夹具说明：`UI_TEST_PREVIEW_DATA`只注入内存快照，不写本地账本。新增UI测试显式传 `-cwlEnabled NO`，验证真实快照呈现路径；实际ledger聚合由worker/数据库单测验证。不能把这些UI截图当作实体iCloud或真实ledger来源的UI证明。生产模式开启ledger时绝不因暂缺来源快照而绕过clear墓碑。

## 数据测试内容与边界
- 未知、缺失与确实为零；不提供费用但有Token；空ledger不回退blob；固定强度档位。
- 双Mac独立100+200合计300，重复Mac A批次不重复入账；一台100、一台未知999时仍为已知贡献100且带不完整标记。
- producer与reader跨时区的今天映射，365天以外和未来记录排除。
- `TokenHistoryMigrationTests` 使用冻结1.24 DailyCostPoint模型实际写入磁盘，再用2.0模型打开：测试行costUSD12000和totalTokens1000000均保留，新可空字段nil且可保存为true。这不是用户数据库或全App多实体迁移证明。
- 旧尝试日志中的UI失败已推动修正：空Group任务、AX标识覆盖、密集按钮邻格命中、回到今天锚点。最终回归是上述fixture-ui，未把0项UI或中间通过画面作为最终证据。

## CloudKit审计
`git diff origin/mobile-dev -- Sources Tests CodexBarMobile/Shared version.env` 无输出；CloudConstants、记录类型/字段/索引/zone/订阅未改变。新增字段只在配置 `cloudKitDatabase: .none` 的iOS本地表。结论：本轮无需Production schema deploy，也无需Mac发新版。未执行线上schema变更。

## 16组合兼容gate
本轮修改缓存字段及显示，gate适用。Mac old/new在本轮为同一0.58.0.1实现（无Mac差异），iPhone old=1.24.0(199)，new=2.0.0(200)本地候选。
未对用户两台实体Mac和两台实体iPhone执行安装/降级/账户同步实验；当前证据只有本地Simulator、合成数据库与源代码审计。以下全部标为substituted，绝不等于真机通过。

替代证据：A=Shared wire/CloudKit无变化代码审计；B=旧schema磁盘迁移；C=双Mac身份/重复/部分未知Token合成回归；D=既有ledger乱序、clear、来源过滤、窗口/时区与payload解码单测。剩余共同风险R=真实CloudKit投递、两独立手机缓存收敛、离线/前后台、用户历史差额、真机滚动未证明。

| Case | Mac A | Mac B | iPhone A | iPhone B | Result | Evidence | Notes |
|---:|---|---|---|---|---|---|---|
| 1 | old | old | old | old | substituted | A/B/C/D | R；Mac两标签同二进制 |
| 2 | old | old | old | new | substituted | A/B/C/D | R；Mac两标签同二进制 |
| 3 | old | old | new | old | substituted | A/B/C/D | R；Mac两标签同二进制 |
| 4 | old | old | new | new | substituted | A/B/C/D | R；Mac两标签同二进制 |
| 5 | old | new | old | old | substituted | A/B/C/D | R；Mac两标签同二进制 |
| 6 | old | new | old | new | substituted | A/B/C/D | R；Mac两标签同二进制 |
| 7 | old | new | new | old | substituted | A/B/C/D | R；Mac两标签同二进制 |
| 8 | old | new | new | new | substituted | A/B/C/D | R；Mac两标签同二进制 |
| 9 | new | old | old | old | substituted | A/B/C/D | R；Mac两标签同二进制 |
| 10 | new | old | old | new | substituted | A/B/C/D | R；Mac两标签同二进制 |
| 11 | new | old | new | old | substituted | A/B/C/D | R；Mac两标签同二进制 |
| 12 | new | old | new | new | substituted | A/B/C/D | R；Mac两标签同二进制 |
| 13 | new | new | old | old | substituted | A/B/C/D | R；Mac两标签同二进制 |
| 14 | new | new | old | new | substituted | A/B/C/D | R；Mac两标签同二进制 |
| 15 | new | new | new | old | substituted | A/B/C/D | R；Mac两标签同二进制 |
| 16 | new | new | new | new | substituted | A/B/C/D | R；Mac两标签同二进制 |

## 发布前剩余门槛
- 用户两台Mac→iPhone逐日对账，解释1.24费用降低的具体来源，不能用合成测试替代。
- 真机同步过程中的tab切换/滚动与两手机收敛验证；小屏/全部字号/Cost暗色大字号渲染仍未全覆盖（Provider暗色大字号已完成）。
- 实施上限365天；多年历史回补尚未提供。
- 远端PR review与发布流程未运行；本轮无push/upload/live release授权。

## PR #123 第一轮 CR 修复
- Codex 在 49a8d23c0 指出：同 usage/device timestamp 的 provider catch-up publication 不会触发热力图刷新。
- 新增按 device/card/publicationTimestamp 排序的 sourceRevision，纳入 TokenActivitySection task ID。
- 回归固定 usage/device timestamp，仅增加 provider publication，并断言 refresh revision 改变；输入顺序改变不产生无效刷新。
- `/tmp/cbm-2-cr1-tests.log`：TokenActivityTests + CostHistoryWorkerTests，11 tests / 2 suites passed；相关 3 个文件 strict lint 与 diff check 通过。
- 应用代码已变化，上传前必须重新归档，原 build 200 archive 不再作为最终上传产物。
- 同轮自查补充：新热力图日合并、全年总计和所选日总计均使用现有 SyncCounterMath.saturatingSum，避免极端同步计数溢出。`/tmp/cbm-2-counter-tests.log`：12 tests / 2 suites passed，包含 Int.max + 1 回归；相关文件 strict lint 通过。
- 自查空日总计：所选日所有 provider 都没有可用计数时显示 Unavailable，保留已知 0；复用已有四语言文案。`/tmp/cbm-2-cr-final-ui.log`：Cost overview 滑动/日期选择 UI 测试通过；strict lint 通过。上传使用该修正之后的重新归档。
