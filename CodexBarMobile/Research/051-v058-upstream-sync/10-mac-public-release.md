# Mac 正式发布执行记录

Status: in-progress。2026-09-10 用户明确要求先正式发布 Mac，随后排查 iOS 365 天历史金额减少与同步期间 tab 卡顿；本次不上传 iOS。

- 上游同步 PR：https://github.com/o1xhack/CodexBar-Mobile/pull/119
- PR head：e8f05af2d0397e3e0492c4bf3844832ec8d0f2a3。远端 Codex review clean，1 轮，0 未解决线程，review gate 通过；Fast Checks 通过。
- merge：9b849af3981fc849d07c5e5875ffc3941d2c18f4。签名包与该提交 Mac 输入零差异。
- Final CI：https://github.com/o1xhack/CodexBar-Mobile/actions/runs/34533139973 ，等待最终结果。
- Developer ID 签名、公证 Accepted、staple validate、distribution policy、隔离环境真实进程启动检查和双架构 dSYM UUID 配对全部通过。
- Apple 公证 submission：b2dde4f3-a328-4c7f-bf57-53d377a8cb76。
- ZIP 内版本：0.58.0.1 / 141.1.1.23.0，CodexGitCommit=e8f05af2d。
- ZIP：76821031 bytes；SHA256 ab79844a960b5d6f805811346b6628c18b28941f26c05815ed03aa4148c1e0bb。
- dSYM ZIP：58410818 bytes；SHA256 6d92cb5995688f5a612552d48a712c402b7c6589d76be557fb6c6dc366c4fad0。
- make_appcast.sh 生成候选条目，sign_update --verify 成功；候选 URL 指向 v0.58.0.1-mobile.1.23.0 对应 ZIP。
- 当前 appcast 变更仅在发布分支。必须在公开资产可下载后合并，以免提前更新 live feed。
- 16 组合仍全部为 substituted，不能称为真实多设备 CloudKit 验证。无 schema 变更，无需 deploy。

尚待：Final CI 通过、tag/draft/公开资产回读、appcast PR exact-head review 与合并、线上 feed/下载/签名验证、issue 完成回写。

此前 03/09 文档中“等待凭证授权/禁止 push/无 PR”描述的是本次用户授权之前的检查点；本记录取代这些发布状态，保留历史验证事实。
