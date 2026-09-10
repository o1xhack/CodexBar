# 测试与发布证据

Status: `in-progress`（本地实现、测试与review完成；签名/draft等待发布凭证授权）
证据目录：`/tmp/codexbar-v058-evidence`。本页不将模拟器、冻结旧解码器或mock当作真机测试。

## 环境与测试

- macOS本机：Xcode26.6(17F113)、Swift6；未请求真实provider/Keychain测试。
- iOS26.5 iPhone17Pro Simulator：`E1DD6B03-ACA4-4962-BA33-AF21EFB1B2BB`；本地ad-hoc签名保留测试运行所需entitlements，未使用发布证书或上传。
- iOS最终：`ios-tests-final.log`，719 tests /46 suites PASS，包括WidgetSnapshotBuilderTests、多设备/账户/日成本/未知值/缓存与本轮V058SyncSemanticsTests。
- iOS xcresult：`/tmp/codexbar-v058-ios/Logs/Test/` 对应本轮最终运行（精确路径见ios-tests-final.log）。
- iOS Release build：`ios-release-build.log`，Release iphonesimulator BUILD SUCCEEDED（不是iOS设备archive）。
- Mac最终Debug build：`mac-debug-build-final.log` BUILD complete；arm64 Release PASS（338.75秒）、x86_64 Release PASS（323.36秒）；lipo核对两架构，thin executable SHA-256/size见`evidence/mac-release-builds.json`。尚未形成签名分发bundle。
- Mac focused初轮840 tests发现catalog重复查找、gpt-6 fallback既有fork预期差异、架构锚点漂移；分别修复，首次全量1102 selections/92组在第52组发现Kiro无cap详情回归并停止；修复后20项定向测试PASS。`mac-full-tests-final.log`重跑前52组全部通过（含Kiro），第53组发现土耳其语遗留弃用key；删除该未使用key后本地化34项通过。使用同一repo discovery/run_group继续53–92组，`mac-remaining-tests.log`第53–87组通过，第88组发现Moonshot旧测试要求隐藏零余额，与本轮明确的确认零语义冲突；更新该端到端测试并验证6项通过，再用`mac-final-five-tests.log`完成88–92组。只变更一个无调用者的资源key，不重跑无关前52组；总覆盖按三段并集核验：92/92组、1102/1102 selections、11027项Swift Testing测试通过。机器核验见`evidence/mac-test-coverage.json`；不是单次零重试运行。
- Swiftlint：`swiftlint-final.log`，2226 files /0 violations。最终完整`lint-complete-final.log` PASS：2226文件零Swiftlint问题、SwiftFormat、portable/JS/22语言/319键检查通过，基于实际commit的parser版本bump检查通过。
- 签名脚本mock：16 configuration×signing×profile×LLDB组合PASS；仅脚本策略验证，不表示真实签名、公证或profile有效。
- README/CI guards PASS；上游README v0.56.0..v0.58.0 diff为空。

核心命令：
```sh
CODEXBAR_SUPPRESS_TEST_KEYCHAIN_ACCESS=1 CODEXBAR_TEST_CODEX_FILE_ISOLATION=1 CODEXBAR_TEST_SESSION_FILE_ISOLATION=1 swift test --filter 'SyncCoordinatorV058MapperTests|CostUsage|CodexExtraUsage|SubprocessRunner|CLILoginRunner|ProviderArchitectureGatekeeper'
xcodebuild -project CodexBarMobile/CodexBarMobile.xcodeproj -scheme CodexBarMobile -destination 'platform=iOS Simulator,id=E1DD6B03-ACA4-4962-BA33-AF21EFB1B2BB' -configuration Debug -derivedDataPath /tmp/codexbar-v058-ios -only-testing:CodexBarMobileTests test CODE_SIGN_IDENTITY=-
```

## 16组合兼容矩阵

旧Mac：published0.56.0.1 /Mobile1.23.0；新Mac：候选0.58.0.1。
旧iPhone：1.23.0(197)；新iPhone：1.24.0(198)。
本环境只有一个可执行开发Mac和一个未登录iCloud的Simulator。`devicectl list devices`发现2个已配对iPhone，但连接状态分别为unavailable/disconnected；没有可执行的第二Mac，因此不能实测2Mac×2iPhone的Production传输。设备ID/名称不复制进研究文档。
所有组合采用替代验证，不报告physical pass。

证据E1：`V058SyncSemanticsTests.two distinct writers and independent old-new reader caches preserve supported amounts`，
参数mask0...15。Mac A/B有不同deviceID；两个reader各自新建SnapshotCache、相反摄取顺序，
使用真实JSON编解码/ProviderUsageEnvelope/merge。旧reader使用冻结的旧amount结构和旧quota-time选择器，
不是启动旧App。E2：新旧daily/budget optional解码、zero/observedAt/overflow/session-fallback精确回归。
E3：同次完整719项iOS tests包含既有删除/ghost/cache/fleet/account/widget用例；不是对16每一格实测silent push。

| Case | Mac A | Mac B | iPhone A | iPhone B | Result | Evidence | Notes |
|---:|---|---|---|---|---|---|---|
| 1 | old | old | old | old | substituted | E1 mask=0; E2/E3 | R1/R2/R3 |
| 2 | old | old | old | new | substituted | E1 mask=1; E2/E3 | R1/R2/R3 |
| 3 | old | old | new | old | substituted | E1 mask=2; E2/E3 | R1/R2/R3 |
| 4 | old | old | new | new | substituted | E1 mask=3; E2/E3 | R1/R2/R3 |
| 5 | old | new | old | old | substituted | E1 mask=4; E2/E3 | R1/R2/R3 |
| 6 | old | new | old | new | substituted | E1 mask=5; E2/E3 | R1/R2/R3 |
| 7 | old | new | new | old | substituted | E1 mask=6; E2/E3 | R1/R2/R3 |
| 8 | old | new | new | new | substituted | E1 mask=7; E2/E3 | R1/R2/R3 |
| 9 | new | old | old | old | substituted | E1 mask=8; E2/E3 | R1/R2/R3 |
| 10 | new | old | old | new | substituted | E1 mask=9; E2/E3 | R1/R2/R3 |
| 11 | new | old | new | old | substituted | E1 mask=10; E2/E3 | R1/R2/R3 |
| 12 | new | old | new | new | substituted | E1 mask=11; E2/E3 | R1/R2/R3 |
| 13 | new | new | old | old | substituted | E1 mask=12; E2/E3 | R1/R2/R3 |
| 14 | new | new | old | new | substituted | E1 mask=13; E2/E3 | R1/R2/R3 |
| 15 | new | new | new | old | substituted | E1 mask=14; E2/E3 | R1/R2/R3 |
| 16 | new | new | new | new | substituted | E1 mask=15; E2/E3 | R1/R3 |

### 替代边界与剩余风险

- R1：未验证真实CloudKit多writer并发写、网络乱序、subscription/silent push、前后台收敛和物理缓存升级。模拟器未登录iCloud，运行日志有account-unavailable；这不是Production读写通过。
- R2：旧writer没有新日请求/独立budget时间，新reader只能回退旧quota时间；旧reader不认识新observedAt。额外fixture明确证明旧reader可能选到25旧余额，而新reader正确选择0；不保证新旧版本显示完全相同。旧字段保持可解码且未删数据。
- R3：日请求只覆盖当前同步窗口；长期CWL不回填此前未保存的计数。不同bucket timezone沿用既有不可比较规则，不能制造准确汇总。
- 本轮兼容gate按允许的替代路径完成（16/16 substituted），不是16组合真机认证。授权发布时仍应告知上述风险；无schema deploy能消除旧客户端固有限制。

## UI与本地化

生产`ProviderAmountCard`+`SyncedDailyActivityView`经ImageRenderer在Simulator实际渲染。
已查看当前系统简体中文、390pt宽、普通及accessibility3字号图片：zero余额可见，未知值为不可用，
大字号纵排不裁剪。图片见`visual/v058-cards-standard.png`及`visual/v058-cards-accessibility.png`，来自本轮测试App。
本路径是原生SwiftUI渲染，不是Xcode Canvas MCP；未模拟完整页面导航/展开按钮交互。
四语言资源审计独立于截图；Locale environment不会切换String(localized:)的实际bundle语言，不把这类截图声称为四语言实测。

## CloudKit审计

比较最后published `v0.56.0.1-mobile.1.23.0` 与最终候选工作树。
`Shared/iCloud/CloudConstants.swift`零diff，新增仅amount/budget observedAt、daily requestCount/tokenCountIsKnown可选JSON字段。
直接CK record type/field/zone/index/query/subscription/encoding version无变化，providerPayloadVersion=1。
结论：**本轮不需要Production schema deploy**；未用发布凭证运行cktool export，未声称已读回线上schema。

## 上游CI来源

目标tag peeled SHA `88fa2f45fa1e7e04c3c96234ddf973ca947208db`。
`upstream-checks.json`记录GitHub check-runs：lint成功、CLI release多平台构建成功，
但macOS测试两shards cancelled；因此不复用为成功heavy CI。
本轮禁止push，未创建PR或触发fork远端Final CI；后续获授权merge时必须走fork fallback CI及exact-head review gate。

## 候选版本与发布状态

- Mac0.58.0.1 /BUILD_NUMBER141.1 /MOBILE_VERSION1.23.0 /Sparkle141.1.1.23.0。
- tag候选v0.58.0.1-mobile.1.23.0，未publish。
- iOS1.24.0(198)，四targets一致；未TestFlight。
- parserLogicVersion15；CodexParserHash `d6190f4e899a6d66`。
- 根CHANGELOG的fork段可被changelog-to-html.sh正确提取，证据release-notes.html。
- 签名、公证、candidate appcast EdDSA、GitHub draft/资产尚未执行；按用户Goal需要发布凭证授权。
- issues108/109/111–118保持open，与本train绑定；无PR，draft阶段不关闭issues。

## 最终静态review

可用agent复核merge/bridge/iOS及release-facing两条独立路径，新增阻塞0。
没有可调用Opus4.7，使用当前可用review agent作为替代，不冒称Opus审查。
发现并修复的字段时间戳、未知计数、catalog work-count、架构锚点和fork About问题见02/06/07。
release reviewer要求签名前先提交源码，以确保CodexGitCommit不是研究提交；此项为待打包前强制步骤。
Kiro条件已独立复核；土耳其语弃用键删除与Moonshot测试语义更新均已自查、定向测试及剩余全量覆盖。
无PR，故本轮未声称GitHub exact-head review完成；后续push/merge仍必须按repo gate。
