# Mac 正式发布执行记录

Status: done（Mac正式发布范围）。2026-09-10 用户明确要求先正式发布 Mac，随后排查 iOS 365 天历史金额减少与同步期间 tab 卡顿；本次不上传 iOS。

- 上游同步 PR：https://github.com/o1xhack/CodexBar-Mobile/pull/119
- PR head：e8f05af2d0397e3e0492c4bf3844832ec8d0f2a3。远端 Codex review clean，1 轮，0 未解决线程，review gate 通过；Fast Checks 通过。
- merge：9b849af3981fc849d07c5e5875ffc3941d2c18f4。签名包与该提交 Mac 输入零差异。
- Final CI：https://github.com/o1xhack/CodexBar-Mobile/actions/runs/34533139973 ，全部通过（macOS六分片、Linux三平台、lint与最终汇总）。
- Developer ID 签名、公证 Accepted、staple validate、distribution policy、隔离环境真实进程启动检查和双架构 dSYM UUID 配对全部通过。
- Apple 公证 submission：b2dde4f3-a328-4c7f-bf57-53d377a8cb76。
- ZIP 内版本：0.58.0.1 / 141.1.1.23.0，CodexGitCommit=e8f05af2d。
- ZIP：76821031 bytes；SHA256 ab79844a960b5d6f805811346b6628c18b28941f26c05815ed03aa4148c1e0bb。
- dSYM ZIP：58410818 bytes；SHA256 6d92cb5995688f5a612552d48a712c402b7c6589d76be557fb6c6dc366c4fad0。
- make_appcast.sh 生成候选条目，sign_update --verify 成功；候选 URL 指向 v0.58.0.1-mobile.1.23.0 对应 ZIP。
- appcast PR120 exact-head review通过（52b554795bc150490b8086469dc6559797f7e275，1轮，0未解决线程），在公开ZIP成功下载后合并；merge 5500b499d0ce22e083730a9a9c9cea01cb9ea3b0。
- 16 组合仍全部为 substituted，不能称为真实多设备 CloudKit 验证。无 schema 变更，无需 deploy。

## 公开发布证据
- 正式release：https://github.com/o1xhack/CodexBar-Mobile/releases/tag/v0.58.0.1-mobile.1.23.0 ，publishedAt=2026-09-10T22:42:28Z，isDraft=false。
- annotated tag v0.58.0.1-mobile.1.23.0 → 9b849af3981fc849d07c5e5875ffc3941d2c18f4；仅推送该新tag，无force。
- 公开下载ZIP的SHA256与签名候选一致，未从本地旧文件代替公网验证。
- 发布后Mac Release Verify：https://github.com/o1xhack/CodexBar-Mobile/actions/runs/34538762671 ，success。
- embedded SUFeedURL=https://raw.githubusercontent.com/o1xhack/CodexBar-Mobile/mobile-dev/appcast.xml；普通embedded raw URL、GitHub API和不可变merge URL均已读到141.1.1.23.0；公开ZIP大小/URL一致，线上feed的EdDSA签名对公网下载ZIP验证通过。最初读到旧CDN内容，等待传播后重新验证通过。
- issues #108/#109/#111–118均已在正式发布后附release URL并以completed关闭。
- Todoist对应任务已移至Release，未标记用户验收完成。
- Release CLI工作流34538762613已success：六平台tar.gz及各自sha256附件均uploaded；`bash Scripts/check-release-assets.sh v0.58.0.1-mobile.1.23.0`通过。Mac GUI ZIP已公开且通过独立启动验证。

## iOS后续边界
用户未要求本次上传iOS。mobile-dev保留原候选1.24.0(198)；追加历史安全/原子事务/后台刷新修复独立保存在本地 `fix/ios-history-refresh-integrity`，提交 c96ef5f21/02486cdbb/39d7eeb08/2b671a46b，候选1.24.0(199)。727项单元测试、3项Simulator UI、Release Simulator构建与独立review通过；14,600条历史后台读取约1.39秒，MainActor heartbeat约30毫秒。没有上传TestFlight，没有覆盖问题真机数据；实际约$2,000下降仍待设备/页面和源数据对账。完整记录见该分支Research052。

此前 03/09 文档中“等待凭证授权/禁止 push/无 PR”描述的是本次用户授权之前的检查点；本记录取代这些发布状态，保留历史验证事实。
