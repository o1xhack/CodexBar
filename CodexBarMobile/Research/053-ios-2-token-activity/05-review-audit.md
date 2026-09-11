# 第六轮前架构复盘

状态：修正已实现并验证，等待最终当前提交 CR。

- PR 审计：https://github.com/o1xhack/CodexBar-Mobile/pull/123#issuecomment-5641138029
- 审计时当前 head：3b52c4539874111df0d536233de0d551ee0198f2；已完成五轮评审事件。
- 重复模式：刷新标识、日历映射和计数完整性在各个 View 中单独拼接，边界规则没有完整传递到所有展示位置。
- 根因：新增图表围绕旧账本增加了局部字符串和数字归约；最初测试偏向单个 reducer，没有覆盖跨层组合。
- 调整：TokenActivity.dayRevision 统一包括 reader 日与全部 producer 日；TokenActivityTotal 明确携带 optional value 和 isLowerBound。Cost 总数卡片、详情总数、单日总数只消费同一结果，不再分别计算/格式化。
- 已保留：同一 actor loader、Cost 主卡片与详情共用 series、Mac payload 不变、确认零/未知区分、安全整数聚合与固定365天边界。
- 回归：东京跨午夜、洛杉矶仍同一日且 publication 不变时，刷新 key 改变且历史映射向前移动一天；已知零、全未知、部分原始/账本计数、不同入口的 ≥ 标识一致。
- `/tmp/cbm-2-semantics-tests.log`：744 tests / 49 suites 全部通过，两个 UI 流程 0 failures；三个相关文件 strict lint 通过。
