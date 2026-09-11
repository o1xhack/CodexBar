# 实现进度

Status: in-progress。

## 数据库非破坏恢复
打开持久库失败不再主动删除SQLite/WAL/SHM，转临时内存库并显示四语言提示。临时模式禁止清除历史，服务层在任何删除/tombstone前拒绝。独立review发现并修复临时模式清除假成功问题，复核阻塞0。

注入open失败测试证明应用恢复分支不主动改文件；不声称能保证SwiftData框架在任意真实迁移失败前绝不触碰WAL。

Mac包不受此独立分支影响。真实金额对账和历史provider退出的产品策略仍待核对。

## 增量提交事务
私有ModelContext暂存整个批次，所有nested save延迟到最终一次save（含token）；失败rollback且不替换cache。网络完成后基于最新cache构造candidate；后台保存期间发生新发布时重新基于最新cache合并。每轮成功后立即发布对应的已提交cache，后续rebase失败保留最后成功结果。full与incremental均遵循这一边界。

## 后台计算与完整结果
`CostHistoryWorker`使用在actor内创建的ModelContext，串行完成写入、seed/prune/aggregate、诊断、clear与展示派生。Sendable请求和结果跨隔离边界，不把SwiftData model传给SwiftUI。Settings诊断不再每次body读取全库。
Cost保留同账户、同窗口、同设备筛选的完整结果；账户/身份/linkage、清除、时区或窗口变化立即失效。异步任务取消/签名不符不会发布旧结果。初次读取显示加载状态；失败提示并保留可用结果。后台计算不等于整个网络与merge链路的所有工作已离开MainActor。

## 时序审查
独立review依次发现并修复：诊断写库与clear竞态、full写库await期间KVS覆盖、账户切换保留旧结果。复核阻塞0。较旧publication现先检查时间再写identity，避免旧legacy数据抹掉新账户标识。新增清除失败可见提示。

## 尚未归因的真实金额
未取得用户所指手机/页面/两次日期的数据库副本，不宣称已找到约$2,000下降的唯一根因。现有provider缺失/明确删除、设备生命周期、账户隔离仍按原策略处理；不取消删除规则制造ghost历史。相同sourceUpdatedAt的价格重算保留既有语义，合法修正可降低金额，不能以max强制累计。若设备证据显示临时provider缺失造成长期账本丢失，需要进一步设计历史owner与活动provider分离，而非草率改变账户隔离。

## 版本
候选iOS1.24.0(199)，project.yml四targets一致并由xcodegen生成。更新同一release notes块及四语言；未上传TestFlight。
