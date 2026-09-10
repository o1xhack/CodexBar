# v0.58.0 一次性上游同步

Status: `in-progress`
Date: 2026-09-10

## 范围与授权

用户 Goal 已确认单版本方案。第一项写操作为从最新 `origin/mobile-dev` (`431a8531a`) 创建
`upstream-sync/v0.58.0-mobile.1.23.0`，所有实现、文档、测试、打包与本地 review 留在此分支。
基线 `version.env`: `UPSTREAM_VERSION=v0.56.0`, `UPSTREAM_SYNC_DATE=2026-08-28`。
GitHub Releases 确认目标 `v0.58.0` published 2026-09-10T04:06:38Z，peeled SHA
`88fa2f45fa1e7e04c3c96234ddf973ca947208db`，与 `git ls-remote upstream` 一致。
全量 fetch 拒绝覆盖历史同名 fork tags；本轮 10 个 tags 成功获取，不 force 更新旧 tags。

| Issue | 上游版本 | 处理 |
|---|---|---|
| [108](https://github.com/o1xhack/CodexBar-Mobile/issues/108) | v0.56.1 | 本轮统一评估，draft 阶段保持 open |
| [109](https://github.com/o1xhack/CodexBar-Mobile/issues/109) | v0.56.2 | 本轮统一评估，draft 阶段保持 open |
| [111](https://github.com/o1xhack/CodexBar-Mobile/issues/111) | v0.56.3 | 本轮统一评估，draft 阶段保持 open |
| [112](https://github.com/o1xhack/CodexBar-Mobile/issues/112) | v0.56.4 | 本轮统一评估，draft 阶段保持 open |
| [113](https://github.com/o1xhack/CodexBar-Mobile/issues/113) | v0.56.5 | 本轮统一评估，draft 阶段保持 open |
| [114](https://github.com/o1xhack/CodexBar-Mobile/issues/114) | v0.56.6 | 本轮统一评估，draft 阶段保持 open |
| [115](https://github.com/o1xhack/CodexBar-Mobile/issues/115) | v0.56.7 | 本轮统一评估，draft 阶段保持 open |
| [116](https://github.com/o1xhack/CodexBar-Mobile/issues/116) | v0.56.8 | 本轮统一评估，draft 阶段保持 open |
| [117](https://github.com/o1xhack/CodexBar-Mobile/issues/117) | v0.57.0 | 本轮统一评估，draft 阶段保持 open |
| [118](https://github.com/o1xhack/CodexBar-Mobile/issues/118) | v0.58.0 | 本轮统一评估，draft 阶段保持 open |

历史已关闭 #102–104 在 #105 / v0.56.0.1-mobile.1.23.0 完成，#104 更正评论提供实际版本和 CI 证据。
本轮不关闭 issue，不 push/远程 merge/tag publish/live release/TestFlight。Git 合入上游 tag 是本地
同步实现操作，区别于用户禁止的最终 PR merge。

## 上游事实与风险

完整 release notes 见 04；相关 commits 见 05。范围为 10 releases，649 files。
重点：Codex/Claude cost parser/cache/catch-up、未知费用与 overflow、workspace/Enterprise identity、
provider quota corrections、Sparkle 2.9.6 security、daily ledger、provider row visibility。
Mac-only UI/CLI/OS 修复完整合入；iOS 依据数据语义适配，不复制 menu-bar 配置。

已完成规则阅读与合并预演；尚未完成实现、测试、签名或 release，不宣称闭环。
