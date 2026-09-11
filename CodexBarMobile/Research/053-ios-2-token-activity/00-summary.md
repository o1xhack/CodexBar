# iOS 2.0 Token Activity

Status: in-progress（本地实现完成；真机数据对账与发布gate未闭环）。

目标：Provider 详情在 Subscription Utilization 下展示 Token Activity；Cost 的 Daily Spend 上增加跨 Provider Daily Tokens Overview；Codex Service Mix 移至 Codex 详情。

用户已确认实施。分支 `feature/ios-2-token-activity`，基线 `origin/mobile-dev` 871829af4（iOS 1.24.0 / 199）。本地候选版本 2.0.0 (200)，所有 targets 一致；200 尚未向 ASC 预占，上传前需再确认。

- [设计](01-design.md)
- [实现与代码审计](02-implementation.md)
- [测试与兼容矩阵](03-testing.md)

Mac 不改版本、不改代码：现有 Shared 日 Token、可用性、时区和服务分项已满足本轮展示。新增可空字段仅在 iOS 本地 SwiftData 表，CloudKit database 为 `.none`；无 Production schema deploy。

未闭环：用户 1.24 升级前后约一万到八千的真实费用差额，尚无两台 Mac / iPhone 逐日对账结论。不能以本轮 UI、合成测试或迁移通过宣称该问题已修复。未 push、merge、tag、发布或上传 2.0。

本地验证：737项单元测试通过；2项标准UI交互通过；Provider暗色大字号通过；四语言与仓库lint通过，iOS针对性lint及既有结构债务见03-testing。
