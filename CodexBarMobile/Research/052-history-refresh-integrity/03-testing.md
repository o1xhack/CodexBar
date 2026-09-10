# 测试证据

Status: in-progress。

基线：已有CWLPerformanceTests 1/1通过，365×40直接aggregate，内部<2秒断言通过；并不覆盖全刷新/主线程卡顿。日志：/tmp/codexbar-ios-history-performance-baseline.log。
实际问题设备/页面待用户回答；当前可连接iPhone所报CodexBar1.0(1)，不代表用户问题安装。未安装、清除或修改真机数据。
Mac发布Final CI仍在运行，iOS尚未改生产代码。

数据库恢复定向6/6通过，包括原SQLite/WAL/SHM保留、恢复后历史可读、临时模式拒绝清除且不写tombstone。日志 /tmp/codexbar-ios-history-recovery-tests-final.log；Simulator证据，不是真实故障手机复现。独立agent复核本组diff阻塞0。

事务阶段：SwiftDataBridge23/23通过，含两Mac批次beforeSave失败后重新开库旧金额/旧token保留、重放后一起前进；同一mainContext先读取旧值、私有context提交后可见新值。日志/tmp/codexbar-ios-history-context-tests.log。未声称已模拟网络KVS回调端到端；该时序通过将candidate复制移到最后await后且无后续suspension消除，独立review通过。
