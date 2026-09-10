# Nimbo Codex 开发交接说明

## 1. 任务目标

请基于本资料包开发 Nimbo。

Nimbo 是一款 **仅面向 HarmonyOS 的原生 API 调试工具**。当前优先开发 HarmonyOS PC，大屏/键鼠体验优先；平板和手机只需要在架构上保持可适配，不要阻塞第一阶段。

不要把 Nimbo 理解成“立刻完整复刻 Postman”。第一版核心是：

> 打开应用 → 创建/导入请求 → Send → 清晰查看 Response → 保存到 Collection → 使用 Environment 重复调试。

---

## 2. 开发时必须阅读

按顺序阅读：

1. `docs/01-Nimbo-PRD.md`
2. `docs/02-Nimbo-UIUX-Spec.md`
3. `docs/03-Nimbo-Design-System.md`
4. `assets/nimbo-main-ui.png`
5. `assets/nimbo-ui-six-screens.png`

若视觉稿与文字规范冲突，以文字规范为准。

---

## 3. 当前阶段：UI Skeleton

### 必须完成

- HarmonyOS PC 主窗口
- Light Mode
- Global Toolbar
- Primary Sidebar
- Collection Sidebar
- Collection Tree 展开/折叠
- Request Tab 新建、切换、关闭
- Request Toolbar
  - Method selector
  - URL input
  - Send / Cancel 状态
- Params
- Headers
- Auth 基础布局
- Body / JSON Editor 基础布局
- Request / Response Splitter
- Response Empty / Sending / Success / Error Mock State
- JSON Response Viewer
- Environment Switcher
- 1024px 宽度时布局不崩

### 此阶段禁止提前做

- 真实 HTTP 请求
- WebSocket
- SSE
- GraphQL
- gRPC
- 登录/账号
- 云同步
- AI
- Mock Server
- Runner
- Script 系统
- 插件系统
- 团队协作

UI 必须先完全可由 Mock State 驱动。

---

## 4. UI Skeleton 完成后的 Gate

在接真实 HTTP Engine 前，以下状态都必须能通过 Mock 数据直接切换：

```text
Response.Empty
Response.Sending
Response.Success
Response.ConnectionRefused
Response.Timeout
Response.TLSFailure
Response.Large
Response.Binary
```

并且：

- GET / POST UI 完整
- Params UI 完整
- Headers UI 完整
- Auth UI 完整
- Body UI 完整
- Error UI 完整
- Light Mode 主界面稳定
- 1024 / 1280 / 1440 宽度稳定

---

## 5. 推荐实现顺序

### Milestone 0 — 工程骨架

建立清晰目录：

```text
entry/src/main/ets/
├── app/
├── pages/
├── ui/
│   ├── tokens/
│   ├── theme/
│   └── components/
│       ├── common/
│       ├── request/
│       ├── response/
│       ├── collection/
│       ├── environment/
│       └── history/
├── models/
├── state/
├── mock/
└── services/
```

不要把全部 UI 写进一个 Page。

### Milestone 1 — Shell

实现：

```text
NimboWindow
GlobalToolbar
PrimarySidebar
CollectionSidebar
Workspace
RequestTabBar
```

### Milestone 2 — Request

实现：

```text
RequestToolbar
MethodSelector
UrlInput
SendButton
RequestConfigTabs
KeyValueEditor
AuthEditor
BodyEditor
JsonEditor
```

### Milestone 3 — Response

实现：

```text
ResponsePanel
ResponseHeader
ResponseSummary
ResponseTabs
JsonViewer
RawViewer
ErrorPanel
LargeResponseViewer
```

### Milestone 4 — Supporting Pages

实现：

- Environment
- History
- Import cURL Dialog
- Postman Import UI
- Settings
- Toast / Dialog / Context Menu

### Milestone 5 — Real HTTP

只有 UI Gate 完成后才接：

```text
Request UI
    ↓
RequestController
    ↓
HttpEngine
    ↓
ResponseModel
    ↓
ResponsePanel
```

先只打通 GET，再扩展 POST / PUT / PATCH / DELETE。

### Milestone 6 — Local Data & Preferences

在真实 HTTP 稳定后，将内存态原型升级为可持续使用的本地工作区：

```text
UI State
    ↓
LocalDataStore（带 schema version）
    ↓
HarmonyOS PersistentStorage
```

按顺序实现：

1. Collection、Request Tab、Environment、History 本地持久化
2. Restore Workspace、History、Network、Privacy 设置真正生效
3. UI 语言资源化与应用内语言切换
4. 真实 cURL 导入/导出与 Postman Collection / Environment 导入
5. 数据版本迁移、损坏数据回退、Reset Nimbo

验收要求：重启应用后本地状态可恢复；关闭历史记录后不再写入；Reset 可恢复到安全默认值；导入失败不得污染现有数据。

### Milestone 7 — Nimbo 1.0 Completion

Milestone 6 完成后，按 PRD 的 `Nimbo 1.0 必须完成` 收口仍缺失的 P0 能力，不进入 1.1 的协议与协作范围。

按顺序实现：

1. Nimbo 本地备份导出 `*.nimbo.json`；默认脱敏 Secret，包含 Secret 的导出必须再次确认
2. 二进制响应保留原始字节并支持通过系统文件选择器保存
3. Light / Dark / System 主题真正生效
4. HarmonyOS PC 细节打磨与 1024px 窗口验收
5. Tablet / Phone 基础响应式验收

第一批验收要求：导出文件可被标准 JSON 解析；默认导出不包含认证密码、Token、API Key 或标记为 Secret 的变量值；二进制下载与保存后的字节数和内容一致；取消文件选择不得产生空文件或错误提示。

当前进度（2026-09-09）：Milestone 7 第 1–5 项已全部完成。Light / Dark / System 可在设置页即时切换，主题选择随 schema v3 本地状态持久化，旧 schema v1/v2 数据可无损迁移；深色模式下重启应用后主题、集合、请求与历史记录均可恢复。PC 端已验证 1024px Compact、1280px Desktop 和最大化大屏布局。Tablet 横屏采用 60px Icon Rail + 220px Secondary Sidebar + Workspace；Phone（<720px）采用精简顶栏、底部导航、Request / Response 页面切换和 Collection Drawer，设置、环境与历史记录切换为单栏布局。已在 HarmonyOS PC 模拟器通过 800px 平板宽度与 360px 手机宽度的运行时缩窗验收，无严重溢出。至此 Nimbo 1.0 Completion 收口完成；继续开发前应先定义后续里程碑，不得自行进入 1.1/1.2 暂缓范围。

### Milestone 8 — Core UX & UI Polish

Milestone 8 只完善 Nimbo 1.0 已有功能，不新增 1.1/1.2 能力。目标是让现有功能在 PC、Tablet、Phone 上具备一致、可信、可交付的视觉与交互质量。

按顺序实现：

1. 清理无效或误导性交互；尚未实现的入口不展示，不以静态控件暗示可用
2. 补齐现有操作的 Hover / Pressed / Focus / Disabled / Loading 与结果反馈
3. 统一页面标题、间距、边框、按钮、空状态、错误状态和危险操作层级
4. 完成所有现有界面文案资源化，消除静态中英文混排
5. 修复 PC / Tablet / Phone 的裁切、拥挤、触控热区与信息层级问题
6. 对请求、响应、集合、历史、环境、设置的已有操作路径做回归验收

验收要求：界面不展示无响应的按钮或未兑现的快捷键；切换中英文后静态 UI 与 Toast 使用同一语言；Light / Dark / System 均无不可读或硬编码颜色；1280px、1024px、800px、360px 宽度下核心页面无严重溢出；真实 HTTP 发送、取消、历史回放、环境变量、导入导出和本地恢复不退化；构建无新增 warning。完成情况必须记录在本节后再进入下一里程碑。

当前进度（2026-09-09）：Milestone 8 已完成。已移除顶部全局搜索、集合搜索、集合/环境创建、响应更多菜单、快捷键查看和界面密度等尚未兑现或无响应的入口；保留的创建请求、导入、历史菜单和危险操作均有真实回调。桌面导航、集合树、请求标签和上下文菜单补齐悬停/按压反馈，手机 Toast 避开底部导航，确认弹窗可在 360px 宽度内完整显示。新增集合、环境、历史空状态，并统一认证编辑器、键值编辑器、响应搜索、错误标题和全部操作 Toast 的中英文资源；Toast 的撤销动作改为显式状态，不再依赖英文文案解析。

运行时验收已覆盖 1024px PC、800px Tablet 和 360px Phone，Light / Dark 与中英文均通过实际切换；Phone 的 Request / Response、Collection Drawer、Settings 和危险确认弹窗无严重裁切。使用 `https://httpbin.org/image/png` 完成真实 HTTPS GET，得到 `image/png`、7.9 KB 二进制响应，保存入口正常；语言切换重启后集合、请求、环境与偏好可恢复。最终 HAP 已安装至 HarmonyOS PC 模拟器并完成构建，未新增 ArkTS warning。现存的两条 `HttpEngine` warning 来自 Milestone 5 已采用的 API 22 Redirect Interceptor 与项目 API 20 兼容下限；功能在当前设备已验证，不在 Milestone 8 中通过抬高最低系统版本规避。

集合可用性补完（2026-09-10）：恢复并接通集合创建入口；集合与文件夹节点可创建嵌套文件夹；Collection Tree 改为不可变状态更新并使用递归刷新键，任意层级均可即时展开/折叠或显示新增子项；请求工具栏提供保存入口，首次保存可选择集合/文件夹并命名，保存后请求内容与 Method 修改自动持久化。以上状态均进入现有本地持久化，不新增在线分享、Runner、脚本、拖拽等暂缓能力。

### Milestone 9 — Open Source Release Readiness

Milestone 9 只完成 Nimbo 对外开源和首次公开发布所需的工程、治理与仓库配置，不新增产品功能，不进入 1.1/1.2 暂缓范围。

按顺序完成：

1. 确立 AGPL-3.0-only 开源许可和可选商业授权路径，补齐 CLA、贡献指南、行为准则与安全政策
2. 补齐 Issue / Pull Request 模板、CODEOWNERS、变更日志和中英文仓库入口
3. 增加 GitHub Actions 质量门禁，检查 JSON、语言资源键、敏感信息、文档链接和治理文件
4. 从清洁 clone 生成本地构建配置并完成无签名 HAP 构建，确保仓库不依赖本机密钥或凭据
5. 完成 GitHub 描述、Topics、依赖安全与私密漏洞报告配置，发布 `v0.1.0-alpha`

验收要求：公开文档不泄露签名资料、密钥、Token 或本机路径；新贡献者能从 README 找到构建与贡献入口；清洁 clone 能通过仓库检查并生成 unsigned HAP；主分支 GitHub Actions 通过；版本标签、Changelog 与 GitHub Release 一致。

当前进度（2026-09-10）：Milestone 9 已完成。仓库已采用 AGPL-3.0-only，并明确版权持有人可另行提供商业授权；已补齐 `LICENSE`、`CLA.md`、`CONTRIBUTING.md`、`CODE_OF_CONDUCT.md`、`SECURITY.md`、`CHANGELOG.md`、CODEOWNERS 及 Issue / PR 模板。本地质量脚本与 GitHub Actions 共用同一组仓库检查；从无构建缓存的清洁 clone 已成功产出 `entry-default-unsigned.hap`，不需要官方应用的签名凭据。GitHub 已配置仓库描述与 Topics，并开启依赖图、Dependabot 告警/安全更新和私密漏洞报告；首个公开预发布版本为 `v0.1.0-alpha`。命令行构建仍会报告无签名配置，以及 `HttpEngine` 的 SDK 22 Redirect Interceptor / API 20 兼容下限告警；前者符合开源 clone 的预期，后者是 Milestone 5 已验收的已知兼容提示。

继续暂缓：WebSocket、SSE、GraphQL、gRPC、Runner、Scripts、AI、Cloud、Login，以及 PRD 归入 1.1/1.2 的能力。

---

## 6. 架构约束

### UI 不能直接依赖 HTTP 底层实现

禁止：

```text
Button.onClick → HTTP Library
```

应该：

```text
Button
 ↓
RequestController / RequestService
 ↓
HttpEngine
```

### 状态使用 enum / union，而不是 Boolean Explosion

不要：

```text
isLoading
isSuccess
isError
isCancelled
isLarge
```

使用：

```text
ResponseStatus =
  empty |
  sending |
  success |
  error |
  cancelled |
  large |
  binary
```

### Token 驱动 UI

禁止业务代码散落：

```text
#FFFFFF
#333333
13vp
17vp
```

统一走 Theme / Token。

---

## 7. 第一批核心数据模型

建议先创建：

```text
RequestDraft
RequestParam
RequestHeader
RequestAuth
RequestBody
RequestSettings

ResponseModel
ResponseError
ResponseTiming

RequestTabModel
CollectionNode
EnvironmentModel
EnvironmentVariable
HistoryItem
```

Request 与 Response 状态分开，不要塞进一个巨型 PageState。

---

## 8. Mock 数据

首屏 Mock：

```text
Collection: Demo API
Request: GET Get Users
URL: https://jsonplaceholder.typicode.com/users
Params:
  _page = 1
  _limit = 10
Response:
  200 OK
  183 ms
  12.4 KB
```

必须额外提供：

```text
mock/response-success
mock/response-error-connection-refused
mock/response-error-timeout
mock/response-large
mock/response-binary
```

---

## 9. 设计要求

设计关键词：

```text
Soft
Native
Calm
Dense
Fast
```

组合方向：

> Linear 的克制 + HarmonyOS 的圆润 + Postman 的信息结构 + IDE 的桌面信息密度。

不要做：

- 赛博朋克
- 黑底荧光绿
- 大量渐变
- 卡片套卡片
- 强阴影
- 所有区域都有边框
- 手机 App 强行放大到 PC

Response 是视觉核心。

---

## 10. 开发行为约束

每完成一个 Milestone：

1. 保持项目可编译。
2. 保持主页面可运行。
3. 不遗留明显的重复组件。
4. 对照 Design System 抽公共组件。
5. 不为了“未来可能需要”提前构建复杂抽象。
6. 未实现功能不要在 UI 中展示 Disabled 菜单；直接不展示。

---

## 11. 第一阶段验收标准

完成以下全部项目即认为 UI Skeleton Done：

- [ ] App 可在 HarmonyOS PC 目标上启动
- [ ] Light Mode 主界面完成
- [ ] 主窗口结构与视觉稿方向一致
- [ ] Sidebar 可切换
- [x] Collection Tree 可展开/折叠
- [ ] Request Tab 可新增/关闭/切换
- [ ] Method 可切换
- [ ] URL 可编辑
- [ ] Send 有 Idle / Sending / Cancel 状态
- [ ] Params / Headers 使用共享 KeyValueEditor
- [ ] Auth / Body 页面可切换
- [ ] JSON Editor/Viewer 有基础代码样式
- [ ] Splitter 可调节 Request / Response 高度
- [ ] Response Mock Success 可展示
- [ ] Response Mock Error 可展示
- [ ] Environment Switcher 可打开
- [x] 1024px 窗口宽度不出现严重溢出
- [ ] 主要颜色、间距、圆角都来自 Token
- [ ] 没有真实网络请求依赖

完成之后，再进入 HTTP Engine。
