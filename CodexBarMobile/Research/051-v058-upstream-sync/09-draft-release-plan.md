# Mac 0.58.0.1 draft内容与执行边界

Status: `prepared`，尚未创建GitHub draft；签名/公证/资产digest待发布凭证授权。

## 对外release notes

### Added
- Daily activity: inspect requests, tokens, and spending by day on Mac, with the selected time zone and clear unavailable values. iPhone receives daily request counts in the current Mac sync window.
- Mac menus: choose visible usage rows, session or weekly percentages, explicit reset clocks/countdowns, and compact account reset labels; hover daily cost bars for details.
- Mobile sync: send purchased Codex credit balances and monthly limits with their own observation times, preserving confirmed zero balances and freshness across Macs that provide observation timestamps.

### Changed
- One upstream train: include every upstream release from v0.56.1 through v0.58.0 in Mac 0.58.0.1 (Sparkle 141.1.1.23.0). The accompanying iOS candidate is 1.24.0 (198).
- Cost history: retain upstream faster parsing, incremental catch-up, cross-launch report reuse, safe token aggregation, and model-pricing fixes while preserving fork estimate provenance and compatible stored history.
- Updates: include Sparkle 2.9.6 archive and package-signature hardening.

### Fixed
- Provider data: include Codex account/reset/permission fixes, Claude credential and timestamp corrections, host-scoped Copilot Enterprise identities, Antigravity raw quota/history fixes, Kiro regional overage handling, and the remaining upstream provider improvements.
- iPhone balances: correctly parse Moonshot RMB/grouped/zero/negative amounts; display credits as units and preserve Ollama monthly-credit labels.
- Reliability: preserve cancelled-login child-process cleanup, very large timeout safety, unknown costs/counts, source time zones, Production CloudKit, fork CI, versioning, signing, and download identity.

## 内部provenance与no-publish gate

- 当前源码提交：`ba1c054332d785f8fb9d26c9bc8918534f6a4fc6`；implementation merge `fb5217b1693871e53d4d8496932019406b493807`，完整upstream parent `88fa2f45fa1e7e04c3c96234ddf973ca947208db`。
- 分支：upstream-sync/v0.58.0-mobile.1.23.0；所有准备留在该分支。
- 候选Mac0.58.0.1、build141.1、Mobile1.23.0、Sparkle141.1.1.23.0；tag候选v0.58.0.1-mobile.1.23.0尚未创建/发布。
- Mac11027项分段全量覆盖、iOS719项、完整lint与本地review通过；两架构Release最终证据见03。
- iOS1.24.0(198)仅本地候选，未上传TestFlight。
- 16/16组合均为substituted，真实多设备/后台push未实测；旧writer/reader不能使用新观测时间语义。
- 无CloudKit schema改动，无需deploy；不声称已执行线上schema export。
- 用户禁止push/tag publish/remote merge/live/TestFlight；不执行release.sh会push tag的phase1。
- 按既有无push draft流程，远程target暂指已有基线431a8531a，而非未推送源码。draft正文必须明确该差异，发布前重新绑定实际远程源码并通过exact-head gate。
- 发布凭证获授权后：签名、公证、staple、包完整性/Production entitlements/资源launch smoke、Sparkle候选feed签名/验签、GitHub unpublished draft上传资产、API回读database ID/URL/draft=true/published_at=null/target/digests/size。
- 打包launch smoke使用`SWIFT_TESTING_ENABLED=1`及既有Keychain/credential-file/session-file隔离变量，验证bundle资源与存活，不启动真实provider后台探测；发布凭证授权仅用于codesign/notary/Sparkle，不扩大为live provider probe。这些变量不写入分发包。
- 签名前更新正文的最终HEAD；package_app.sh把HEAD写入CodexGitCommit，不能引用研究提交或只引用未提交工作树。
- 根README和live appcast不变；candidate appcast留在独立证据目录，未发布feed。
- issues108/109/111–118仅关联，draft阶段保持open，无closing keywords。

## 待产生的证据

| 项目 | 当前状态 |
|---|---|
| Developer ID签名/Apple公证 | 未执行，等待凭证授权 |
| ZIP/dSYM ZIP digest | 未产生 |
| Candidate appcast/EdDSA | 未产生 |
| GitHub draft database ID/URL | 未创建 |
| Public tag/live feed/TestFlight | 未授权，不执行 |
