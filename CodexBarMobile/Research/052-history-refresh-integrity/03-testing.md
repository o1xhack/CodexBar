# 测试证据

Status: in-progress。

基线：已有CWLPerformanceTests 1/1通过，365×40直接aggregate，内部<2秒断言通过；并不覆盖全刷新/主线程卡顿。日志：/tmp/codexbar-ios-history-performance-baseline.log。
实际问题设备/页面待用户回答；当前可连接iPhone所报CodexBar1.0(1)，不代表用户问题安装。未安装、清除或修改真机数据。
Mac发布Final CI运行中；本独立iOS分支已实施以下修复。

数据库恢复定向6/6通过，包括原SQLite/WAL/SHM保留、恢复后历史可读、临时模式拒绝清除且不写tombstone。日志 /tmp/codexbar-ios-history-recovery-tests-final.log；Simulator证据，不是真实故障手机复现。独立agent复核本组diff阻塞0。

事务阶段：SwiftDataBridge23/23通过，含两Mac批次beforeSave失败后重新开库旧金额/旧token保留、重放后一起前进；同一mainContext先读取旧值、私有context提交后可见新值。日志/tmp/codexbar-ios-history-context-tests.log。未声称已模拟网络KVS回调端到端；后台await后的candidate重合并/逐批发布路径经过独立代码review。

## 后台与完整回归
- Debug构建通过。新增worker+resolver+bridge定向43项通过，包含$12,000长历史接收$10,000短快照后仍保持$12,000，以及取消读取不改账本。日志 `/tmp/codexbar-ios-history-worker-tests.log`。
- 全量726项/47suites通过，包含WidgetSnapshotBuilder。日志 `/tmp/codexbar-ios-history-all-tests.log`。随后新增性能用例另跑，不能将726误报包含该新增项。
- 365×40条完整worker读取（含prune/seed检查、聚合、展示）1.529秒；同期间MainActor heartbeat在0.038秒执行。测试不是60fps真机保证，未覆盖网络和全部MainActor merge。日志 `/tmp/codexbar-ios-history-ui-performance-tests.log`，2性能tests通过。
- 3项Simulator UI通过：Cost日用量标题/币种、Cost完整图像、Usage Settings交互。真实XCTest截图已查看，测试数据为mock，不能用于用户金额对账。xcresult `/tmp/codexbar-ios-history-build/Logs/Test/Test-CodexBarMobile-2026.09.10_15-34-04--0700.xcresult`。
- 四语言资源审计、CI/fork README guard通过。新增worker及测试文件SwiftLint严格检查通过；手动扩大到整个iOS历史文件会报既有规则违规，不把该试跑描述为全iOS lint通过。repo正式SwiftLint范围为Sources/Tests。
- 请求结构重构后Release Simulator arm64/x86_64构建通过（`/tmp/codexbar-ios-history-release-build.log`）；最终全量727项/47suites通过（`/tmp/codexbar-ios-history-all-tests-final.log`），含新增性能用例，此次worker1.388秒/MainActor heartbeat0.030秒。最终独立review阻塞0。

## 本轮兼容gate（16组合）
因本地缓存/刷新变化触发。old Mac=0.56.0.1，new Mac=0.58.0.1；old iPhone=1.23.0(197)，new iPhone=1.24.0(199)。只有一个可执行开发Mac；问题手机未确认、第二手机不可连接，Simulator无Production iCloud，因此全部采用substituted，不声称真机矩阵通过。
E1=同次全量测试中的V058SyncSemanticsTests mask0...15，两个writer身份、独立reader缓存、冻结旧decoder/旧金额选择器；E2=本轮SwiftDataBridge事务/worker/全量cache、账户、删除和Widget回归。E1模拟旧reader不是运行旧App；E2不等于每格物理数据库升级。

| Case | Mac A | Mac B | iPhone A | iPhone B | Result | Evidence | Notes |
|---:|---|---|---|---|---|---|---|
| 1 | old | old | old | old | substituted | E1 mask=0; E2 | R1/R2 |
| 2 | old | old | old | new | substituted | E1 mask=1; E2 | R1/R2 |
| 3 | old | old | new | old | substituted | E1 mask=2; E2 | R1/R2 |
| 4 | old | old | new | new | substituted | E1 mask=3; E2 | R1/R2 |
| 5 | old | new | old | old | substituted | E1 mask=4; E2 | R1/R2 |
| 6 | old | new | old | new | substituted | E1 mask=5; E2 | R1/R2 |
| 7 | old | new | new | old | substituted | E1 mask=6; E2 | R1/R2 |
| 8 | old | new | new | new | substituted | E1 mask=7; E2 | R1/R2 |
| 9 | new | old | old | old | substituted | E1 mask=8; E2 | R1/R2 |
| 10 | new | old | old | new | substituted | E1 mask=9; E2 | R1/R2 |
| 11 | new | old | new | old | substituted | E1 mask=10; E2 | R1/R2 |
| 12 | new | old | new | new | substituted | E1 mask=11; E2 | R1/R2 |
| 13 | new | new | old | old | substituted | E1 mask=12; E2 | R1/R2 |
| 14 | new | new | old | new | substituted | E1 mask=13; E2 | R1/R2 |
| 15 | new | new | new | old | substituted | E1 mask=14; E2 | R1/R2 |
| 16 | new | new | new | new | substituted | E1 mask=15; E2 | R1/R2 |

R1：真实Production网络乱序、silent push、前后台收敛和物理SQLite升级未实测；实际$2,000来源未确认。R2：旧reader不支持独立余额时间及新日计数；价格修正/账户或设备筛选可能合法改变总额，不能保证旧新界面金额完全一致。
CloudKit审计：本052相对9b849af无Shared/wire/record/zone/index/entitlement变化，仅本地事务与读取，不需要Production schema deploy；没有Dashboard deploy，也未声称在线schema读取完成。
