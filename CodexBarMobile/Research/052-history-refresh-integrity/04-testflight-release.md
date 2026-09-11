# iOS 1.24.0 TestFlight 与 ASC 元数据

Status: in-progress。

用户已授权上传 TestFlight，并通过 API 创建对应 App Store version、填写更新说明和绑定 build；未要求提交 App Review，也未授权自行发布旧的 App Store 版本。

- 候选 1.24.0 (199)，源代码测试证据见03-testing.md；真实约$2,000差额仍未完成设备对账。
- App Store / TestFlight 四语言发布文案保存在 AppStoreMetadata/1.24.0/，应用内说明继续合并在同一1.24.0条目。
- ASC已核对 bundleId=com.o1xhack.codexbar.mobile；最新已有build197 VALID，199尚未占用。
- ASC现有1.23.0=PENDING_DEVELOPER_RELEASE。POST创建1.24.0返回409 ENTITY_ERROR.RELATIONSHIP.INVALID（当前状态不能创建下一版本），已询问用户是否授权发布1.23.0；不影响独立TestFlight上传准备。
- 发布命令使用Xcode登录会话完成cloud signing，不将App Manager API key传给Xcode；package resolver显式netrc，导出保持审核过的build number。新增静态contract纳入portable lint。
- 图标源图1024×1024，RGB无Alpha，已实际查看；archive及Apple处理后图标待核对。
- PR exact-head review、Final CI、Archive、上传、Apple处理VALID和元数据回读待完成。
