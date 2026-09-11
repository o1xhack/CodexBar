# iOS 2.0 — Token Activity 与信息归属

Status: done（已实施；最终 Cost 信息层级以末尾用户确认修订为准，2.0.0(200) 已进入 TF）。
基线：origin/mobile-dev 871829af4，iOS 1.24.0 (199)。实施分支 feature/ios-2-token-activity。

## 用户目标与事实
两台Mac独立运行任务，远程控制本身不代表重复会话。不能将未经验证的跨设备重复作为金额下降的解释。1.24升级前后约一万到八千的差额尚未对账，不能声称已修复。
用户提供贡献图参考：7行日格、按周排列、月份标记、横向浏览。2.0采用其日历结构，不照搬桌面密度或缺乏数据依据的聊天时长/连续天数指标。

现有 SyncedDailyActivityView 仅展示 summary.daily 最近7天并展开，包含Requests/Tokens/Cost；ProviderDetailView将它放在UtilizationHistoryView之后。此数组来自当前producer窗口，不等于iPhone长期历史。CostLedgerService.aggregate将窗口限制为1...365。基础数据支持tokenCountIsKnown，但需继续审计本地存储是否完整保留可用性信息和无费用Token记录。

## 页面方案
### Usage → Provider详情
顺序：现有摘要/预算 → Subscription Utilization → Token Activity → Daily Spend；Codex详情在Token Activity与Daily Spend之间增加Codex Service Mix。
Token Activity替代Show all days列表。7行代表星期、列代表周，显示月份及年份；横向滑动，首次定位最新日期，提供回到今天入口。每个小格是一天，使用现有统一Provider色，4档非零强度；同一Provider跨年份采用一致分档，图例明确强度含义。
点选格子，在卡片下方展示日期、Token数与可用覆盖信息；可提供请求数（源数据可用时），不再在这里重复Cost。
区分已知0、未知/未同步、未来日期；不能用同一种灰格表示全部状态。VoiceOver朗读日期/Provider/Token/状态，大字号可读详情、提供按日列表的无障碍替代入口。

### Cost → Daily Tokens Overview
放在Daily Spend正上方。复用同一日历组件及Token聚合结果，不从costDailyPoints过滤后反推Token。
建议采用按Provider分行的可折叠日历组：每个Provider一组7行日历，月份/日期与水平滚动位置共享；只展示当前范围有日Token数据的Provider。默认展开有数据的前两组，其余通过Provider选择器查看，避免页面无限增高。
顶部显示选中范围可用Token合计；点选一天显示当天跨Provider合计及分项。同一天多Provider活动不会被单一颜色吞掉。Provider身份用色，强度只表示各Provider自身活动，不暗示不同Provider相同色深代表相同Token量。
不提供日Token的Provider不出现在图中；部分日期缺失的Provider仍保留，标记缺失。支持Token而不提供Cost的Provider必须能进入该图。
不使用“当天最多Provider的颜色”作为唯一总览格色，避免隐藏其他Provider。

### Codex Service Mix
从Cost全局移到Usage的Codex详情。仅当前Codex账户/设备筛选范围，明确沿用实际service breakdown的单位和可用时间窗口，不把美元分布标成Token分布。无数据隐藏。Cost的Model Mix与分享卡内是否仍含Service Mix须一并检查，避免遗漏迁移入口。

## 历史与一致性
至少支持浏览过去一年；更早年份仅在实际保存数据存在时开放。显示最早可用日期，不能把一年空格描述为已有一年完整数据。
热力图范围独立于Cost金额窗口（如30天）；持久保存策略需独立审计，不能只把查询上限从365改大，因为既有prune可能已删除更早记录。先确定按日Token保留策略及迁移，新增长期Token存储时使用版本化迁移、不删除原库、不伪造旧Token。UI无需扩展Mac wire的结论只能在Shared/payload审计后给出。
两台Mac同一Provider的本地Token按设备分别保留再按日汇总；账户级Provider遵循该源的作用域，不重复相加账户汇总。重复同步幂等、迟到数据按明确版本规则更新，短快照不删除长期历史。逐日日期采用明确的producer/reader时区映射，避免跨日错位。
已知金额下降的真实数据对账单独推进，作为2.0发布前的数据可靠性门槛；不靠重做UI掩盖问题。设计和原型可先做。

## 推进阶段
1. 数据审计：Provider日Token能力矩阵、两Mac逐日来源对账、旧库/新库/同步窗口与prune检查，保存只读证据。输出错误的具体位置或明确的数据缺口。
2. 交互原型：先确认Provider卡片和Cost总览的实际iPhone截图，包含有数据/未知/零、双Provider、暗色和大字号。
3. 数据实现：共享TokenActivity读取/聚合模型；后台查询完成后一次发布，按周惰性渲染，分页读取旧年，避免主线程扫描全年历史。
4. UI实现：两处热力图、Provider筛选、日期详情、Service Mix迁移；保留现有配额与费用模块语义。
5. 验证与交付：单元/集成/渲染/真机滚动测试，四语言，CHANGELOG与同一2.0.0发布说明；触发docs/ios-sync-compatibility-testing.md的16组合gate，记录实测与替代证据。

## 版本
目标MARKETING_VERSION 2.0.0；进入可交付实现阶段统一更新所有target。本地候选2.0.0 (200)，上传前仍需确认ASC最新build，不预占号码。不因iOS大版本自动提升Mac版本；如需Mac桥接改动再按version.env/docs/versioning.md计算。

## 验收重点
- 同一日期详情Token总额等于同范围Provider分项之和；两个页面使用同一聚合结果。
- 两Mac相加、重复批次、短快照、离线、乱序更新、账户切换、升级迁移均有回归证据。
- 366天闰年、年界、DST/时区、未知与零、缺失Provider、只有Token没有Cost均覆盖。
- 可横向回看一年，不承诺不存在的历史；更早数据保留方案先定再开放多年入口。
- 同步时切tab、滚动和日期点选不卡顿；Simulator与真机证据分开记录。
- en、zh-Hans、zh-Hant、ja全部完成；符合iOS17与Swift6既有约束。

## 本轮实现边界
第一版提供过去365天，日期选择器作为小格点选的可访问替代入口。Cost 默认展示两个 Provider，可展开其余；所有 Provider 共享横向日期轴和固定名称列。多年查询/历史回补尚未实施，不能承诺旧数据存在；无数据和未知日不填成零。

## 用户确认的 Cost 信息层级调整（2026-09-11）
Cost 的 Daily Spend 上方改为单张总 Token 卡片，只显示所有支持 provider 的合计及过去一年范围。点击进入 Token Activity 详情，再显示按 provider 区分的热力图。Usage 单 provider 热力图保留。主卡片与详情复用同一份已加载 series，不在导航时发起第二次数据库聚合；未知/零、按设备与账号合并规则保持一致。
