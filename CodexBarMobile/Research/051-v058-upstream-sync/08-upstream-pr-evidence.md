# 相关上游PR与commit核验

来源：GitHub API（2026-09-10），不是以issue标题推断release内容。PR作者的测试声明只是上游证据，不替代fork本地验证。

| PR | Merge commit | 状态 | 本轮关键影响 |
|---|---|---|---|
| [3296](https://github.com/steipete/CodexBar/pull/3296) | `b07fd2ea4106b739daf5fcc52ec8dd935e58dd34` | MERGED; target ancestor=True | cap与purchased balance独立时间，确认零清理，账户隔离；本轮扩展两种observedAt。 |
| [3527](https://github.com/steipete/CodexBar/pull/3527) | `c856e4b127f2a356cfc3df7a2d5d02f79bdb11fe` | MERGED; target ancestor=True | 显式子agent history boundary前记录不计费，缓存有界重解析；仍有上游未解决的独立owned-usage undercount，不能称所有Codex计费问题均已修复。 |
| [3476](https://github.com/steipete/CodexBar/pull/3476) | `d85ef4935d7ee83187588ea5216bbb77015416c5` | MERGED; target ancestor=True | 每报告有界model resolver，UTF-8 key、negative result与1024-entry/512-byte限制；fork estimated标记路径也必须复用resolver。 |
| [2635](https://github.com/steipete/CodexBar/pull/2635) | `5e5a9003efb26b9291e48b31a0088e7b666b65c0` | MERGED; target ancestor=True | 每日ledger区分unknown和zero，OpenCodex全窗口requests；iPhone当前窗口optional计数对应支持。 |
| [3341](https://github.com/steipete/CodexBar/pull/3341) | `707fdda427f32499427d38f0a5518b96f20f71c4` | MERGED; target ancestor=True | Enterprise identity按配置API host，issuer+userID隔离；config revision/cancel防止陈旧登录提交。 |

[#3359](https://github.com/steipete/CodexBar/issues/3359)是issue，不是PR；先调用PR API无法解析后明确改读issue。
上游release对应Kiro区域/enrichment修复，代码保留受支持region与无效ARN预检；不在iPhone发送这些凭证。

目标提交check-runs：lint与CLI release构建成功，macOS测试两shards cancelled。
因此即便相关PR正文记录各自全量测试成功，本轮不把它们当目标提交的exact-head heavy CI。
