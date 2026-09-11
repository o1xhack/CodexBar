# 实现与代码审计

Status: 本地实现及针对性review完成；发布前真机与远端review gate未完成。

## 文件与数据流
- `Models/TokenActivity.swift`：同一 reducer 供两处视图使用；ledger rollup 按账户匹配，避免再叠加当前 blob；显式空 rollup 不回退旧 blob；无费用但有 Token 的 Provider 保留。
- `Storage/CostHistoryWorker.swift`：actor 中查询、必要时迁移旧 blob、按活动设备聚合；任务取消后不发布结果。
- `Storage/CostLedgerModels.swift` / `CostLedgerService.swift`：持久保留已有 wire 的可空 `tokenCountIsKnown`；所有 upsert、seed、设备身份迁移路径传递字段。原始未知/负数不加入 Token 总额；跨 Mac 部分已知仍保留已知贡献及不完整标志。金额加法未改动。
- `Views/TokenActivityView.swift`：7行周列热力图、Provider 色与固定 Token 档位、左右浏览、回到今天、日期点选/日期选择器；未知虚线边框、已知零浅灰、部分总量以 ≥ 展示。Cost 同轴多行默认两个 Provider。
- `Views/ProviderDetailView.swift` / `ContentView.swift`：接入真实设备快照范围；Token 模块独立于是否有当前 cost summary；CodexServiceMixView 仅在 Codex 详情，注明当前 Mac 同步窗口，仍为费用而非 Token。
- Share card 未使用 serviceRows；模型保留该聚合字段兼容现有数据/测试，全局 Cost Service Mix 卡片已移除。
- `project.yml`、CHANGELOG、MobileReleaseNotesCatalog 和四语言同步更新至2.0.0，Xcode项目由xcodegen生成。

## 现有历史约束
ledger 查询仍为365天；不删除历史、不扩大保存承诺。blob fallback 按 producer/reader 逻辑日龄映射并过滤365天以外及未来日，与 ledger 日期语义一致。旧可空字段 nil 沿用旧语义；已丢失的未知标记不能凭空恢复，仍需后续快照重新补齐。

## Mac / CloudKit 审计
相对基线，`Sources/`、`Tests/`、`CodexBarMobile/Shared/`、CloudConstants、CloudKit记录/订阅/索引/zone、Mac `version.env` 均无修改。`SyncDailyPoint.tokenCountIsKnown` 原已存在并用 `decodeIfPresent`；SwiftData新增字段不会自动进入CloudKit，因为ModelContainerFactory配置 `.none`。
因此本轮不需要 Mac 适配版本或 Production schema deploy。未访问/修改线上 schema。超过一年历史回补和真实费用差额调查可能产生独立 Mac 需求，当前没有未经验证的结论。

## 本地 review 发现并修正
1. 初始空 Group 导致task未启动：改为具体VStack承载任务。
2. 部分已知Token在第二次聚合被清零：仅在原始行进入聚合时过滤未知，后续保留已知贡献；新增双Mac回归。
3. 仅未知但有已知贡献的 ledger provider 被隐藏：按 recordedTokens 判断可展示性。
4. blob fallback 超窗/时区：加入365天边界及producer/reader日龄映射测试。
5. Overview Provider 名称随横轴滑走：固定左侧标签；默认两行减少纵向长度。
6. 容器AX标识覆盖子日期标识：移除容器级标识；日期选择改为单一Date状态。
7. 密集Button邻格命中：格子改为精确矩形tap区域并保留VoiceOver按钮action；指定日期点选回归通过。
8. 回到今天定位到左侧的1px锚点：将锚点改为整个日历内容，按trailing回到末端；先横向回看再返回的UI测试通过。
9. 大字号：日历文字高度随Dynamic Type伸缩，末端月份向内对齐，避免叠行和裁切。
10. 关闭ledger时的365日映射也移入后台actor，避免在主线程处理整个Provider集合。
11. ledger开启时始终读本地账本，即使来源快照暂时为空也不绕过clear墓碑回退旧blob。

正式远端 PR review 尚未运行；没有 push 授权，不将本地自查写成远端review通过。
