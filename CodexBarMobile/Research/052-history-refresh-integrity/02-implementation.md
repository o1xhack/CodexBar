# 实现进度

Status: in-progress。

## 数据库非破坏恢复
打开持久库失败不再主动删除SQLite/WAL/SHM，转临时内存库并显示四语言提示。临时模式禁止清除历史，服务层在任何删除/tombstone前拒绝。独立review发现并修复临时模式清除假成功问题，复核阻塞0。

注入open失败测试证明应用恢复分支不主动改文件；不声称能保证SwiftData框架在任意真实迁移失败前绝不触碰WAL。

其他历史生命周期、增量事务、后台刷新尚待完成。Mac包不受此独立分支影响。

## 增量提交事务
私有ModelContext暂存整个批次，所有nested save延迟到最终一次save（含token）；失败rollback且不替换cache。所有网络await后才复制最新cache，避免KVS回调更新被过早副本覆盖。审查该项已修复，阻塞0。后台actor性能工作未完成。
