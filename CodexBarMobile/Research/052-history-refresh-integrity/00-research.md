# 2026-09-10 用户追加范围

Mac：用户明确要求先正式发布，授权必要签名、公证、发布及 Git handoff。PR119已创建；review当前HEAD e8f05af2d0397e3e0492c4bf3844832ec8d0f2a3。未授权iOS TestFlight。

Mac公开后排查iOS：
1. 365天history window，实际使用不足365天，统计总金额曾约12000美元最近约10000美元，每次打开变化。核对Mac原始保留窗口、扫描重算/定价、CloudKit增量、iOS本地数据库保留、writer覆盖/删除/去重、聚合快照与时区，不预设必须单调或已发生数据丢失；保留原始数据不清缓存。
2. 同步/加载时切换tab卡顿。测量主线程计算、存储IO、重复刷新与视图重算，评估后台计算和原子结果发布，验证流畅性与最终一致性。不得只延迟UI来掩盖数据问题。
3. 本轮新增每日用量展示与长期汇总的数据来源及窗口一致性。

## 只读审计初步证据（待复现）
- ContentView.swift CostTab.currentInsights 在 cachedLedgerSignature 与当前签名不同时传入 nil ledger，resolver 退回较短 Mac blob；主线程 refreshLedgerAggregation 结束才恢复长窗口，可能造成显示跳变。
- CostLedgerService.aggregateSeedingFromExistingBlobsIfNeeded 在读之前全表 orphan prune，再逐日 seed lookup 和 aggregate；CostTab 在 MainActor 调用，currentInsights 多次 computed 重算。
- Research/024 DESIGN.md 表格明确 Mac 卸载 provider 时旧 daily 点保留供历史查询，但 SwiftDataBridge provider prune/deleteProviderRecords 会删除 ledger；aggregate 还 pruneLedgerRowsMissingProviderSnapshots。需核对后续研究是否明确改变此产品规则，再写复现与修复。
- Mac historyDays 是扫描窗口，不等同不可变累计账本；iOS按日期更新已存在行允许金额被最新源修正，不能简单用max保证单调而隐藏重算错误。

- ModelContainerFactory.makeContainer 打开持久库失败后直接 deleteStoreFiles 再建库；注释仍声称只是可从CloudKit恢复的cache，但CWL现已包含超出Mac窗口的唯一历史。需改为非破坏恢复/保留原库与可见错误状态，并测试打开失败不删除旧账本。
- CWLPerformanceTests 当前仅直接 aggregate；可能未覆盖真实refresh中的prune、seed逐行查询和UI多次computed工作，不能把现有性能测试通过当作真实卡顿不存在。

## 基线测量
- 2026-09-10 运行已有 CWLPerformanceTests，1/1 通过。测试规模365×40，直接aggregate内部小于2秒断言通过；整体测试含setup2.36秒。不能把整体2.36秒当aggregate耗时，也不能据此声称UI流畅。日志/tmp/codexbar-ios-history-performance-baseline.log。
- iPhone默认窗口90天，Mac扫描窗口独立；实际问题设备与具体Cost/provider页面已异步询问。当前可连接设备所报应用1.0(1)，不得覆盖或认作用户问题安装。
- fromLedger会跳过无live provider匹配的历史rollup，即使保留数据也可能不显示；如果决定保留卸载provider历史，需要一起处理历史metadata/展示及widget一致性，不能只删除prune调用。
