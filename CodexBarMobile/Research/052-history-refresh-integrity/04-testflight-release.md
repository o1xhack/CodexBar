# iOS 1.24.0 TestFlight 与 ASC 元数据

Status: in-progress。

用户已授权上传 TestFlight，并通过 API 创建对应 App Store version、填写更新说明和绑定 build；未要求提交 App Review，随后明确授权直接发布1.23.0。

- 候选 1.24.0 (199)，源代码测试证据见03-testing.md；真实约$2,000差额仍未完成设备对账。
- App Store / TestFlight 四语言发布文案保存在 AppStoreMetadata/1.24.0/，应用内说明继续合并在同一1.24.0条目。
- ASC已核对 bundleId=com.o1xhack.codexbar.mobile；最新已有build197 VALID，199尚未占用。
- 用户明确授权后，API发布1.23.0 (197)，回读READY_FOR_SALE；随后创建1.24.0（9c758ebd-07b8-4b79-b3c3-386a0e3e27c9），PREPARE_FOR_SUBMISSION / MANUAL。en-US、zh-Hans、zh-Hant、ja四份whatsNew已写入并逐字回读一致，build待上传后绑定。
- 发布命令使用Xcode登录会话完成cloud signing，不将App Manager API key传给Xcode；package resolver显式netrc，导出保持审核过的build number。新增静态contract纳入portable lint。
- 图标源图1024×1024，RGB无Alpha，已实际查看；archive及Apple处理后图标待核对。
- PR exact-head review、Final CI、Archive、上传、Apple处理VALID和元数据回读待完成。
