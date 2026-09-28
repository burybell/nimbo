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

### Milestone 10 — Core Editor & Shell Consistency

Milestone 10 只修复公开 Alpha 中已经存在的核心编辑与 Shell 一致性问题，不扩展协议、Runner、脚本、账户或云端范围。

分三批完成并分别提交：

1. 统一请求与响应 JSON 代码表面：请求正文可编辑且具备语法高亮；响应 JSON 使用同一视觉体系，保留光标、选择和复制能力但禁止修改
2. 收口请求主控件：Method 使用方法色和独立顶层菜单；新建与导入入口合并为一体式 Split Button；删除重复的侧栏设置入口
3. 统一环境与全局导航：开发环境 / 预发布环境 / 生产环境作为不可删除的系统环境进入真实持久化数据；顶部选择器读取同一数据源；实现可检索请求、集合、历史、环境和常用命令的全局搜索及 `Ctrl+K`

验收要求：编辑与只读 JSON 均有稳定代码样式；Method 菜单不被工作区遮挡；新建菜单不挤压侧栏；设置只有一个主入口；首次安装、旧 schema 和重置后均存在三个空变量系统环境，旧环境值与 Postman 导入环境不丢失；全局搜索可过滤并打开结果或执行命令；中英文、深浅主题和响应式布局不退化；构建无新增 warning。

当前进度（2026-09-10）：Milestone 10 已完成。新增共享原生 RichEditor JSON 代码表面，请求端可编辑，响应端可移动光标、选择和复制但不可修改；JSON key、string、number、literal 与标点均使用主题 Token 高亮。Method 选择器改为方法色顶层弹层，新建/导入改为一体式分段按钮，重复设置入口已移除。持久化 schema 升级至 v4，三个系统环境会在首次安装、旧数据迁移和重置时自动补齐，已有变量和导入环境保留；环境页与顶部选择器使用同一状态。顶部全局搜索已接通请求、集合/文件夹、历史、环境及新建、导入、设置命令，支持点击和 `Ctrl+K`。仓库质量检查、签名 HAP 构建与 HarmonyOS PC 模拟器运行时验收通过；未新增 ArkTS warning，仍仅保留 Milestone 5 的两条 Redirect Interceptor 兼容提示。

Milestone 10 后续 UI 回归（2026-09-10）：请求发送时不再在工具栏额外插入“正在发送”提示，避免请求配置区发生纵向位移，发送/取消状态继续由按钮反馈；环境变量与历史记录的 Scroll 内容显式从顶部排列，历史空状态仍保持居中展示。

同日视觉与编辑器回归：桌面请求工具栏将 Method + URL、保存、发送拆分为清晰的独立控件；右上角设置入口使用与当前线性图标体系一致的圆角齿轮 SVG，并重绘 AppScope、应用内标题和桌面入口共用的 Nimbo 云端请求图标。RichEditor 的 StyledString 内容变更改由控制器监听，并在发送/保存前让输入法预编辑内容先完成提交，避免正文已经显示为新值但请求仍携带旧值。签名 HAP 构建通过，并在 HarmonyOS PC 模拟器用 httpbin 回显确认响应 `data` 与发送前编辑器显示的最新正文完全一致。

后续全屏与集合回归：桌面全局搜索改为独立居中层，最大化后不再受左侧工作区提示或右侧环境/窗口按钮宽度影响；响应正文、Headers 和 Cookies 内容区统一占用 ResponseHeader 之后的剩余高度，JSON 最后一行和底部内边距可以完整滚动到；集合中的请求可通过行尾三点菜单重命名，名称会同步集合节点、持久化请求以及同 ID 的已打开标签。

同批主题与窄窗回归：代码表面补充独立浅色 Token，Light 模式下 JSON/Raw 编辑器使用浅底和高对比语法色，Dark 模式配色保持不变；新建按钮的导入菜单展开时会占用完整菜单高度，两项操作使用同一图标/文字栅格且不再被下面的导航项覆盖；窗口进入手机断点时标题栏使用紧凑 Logo，并为鸿蒙原生窗口按钮保留动态安全区，最大化、最小化和关闭按钮不会与应用控件相互挤压。

集合树层级回归：集合、文件夹和请求改为每层 24vp 的递进缩进，节点内部间距收紧为 4vp，并限制极深目录的最大缩进；父子结构仍有明确层级，同时减少箭头、文件夹图标与请求 Method 标签叠加造成的横向占位，保留窄侧栏中的名称可读空间。

工作区空状态回归：空状态根容器补齐剩余工作区高度，无请求时的图标、标题和说明现在以请求标签栏下方的可用内容区为基准水平、垂直居中。已通过 HarmonyOS PC 模拟器实际启动验收。

设置内容布局回归：PC 与 Phone 的设置分组滚动容器均显式使用顶部起始对齐；通用、外观、网络、数据、隐私和关于内容从同一顶部基线向下排列，内容较少时空白保留在底部，不再呈现垂直居中效果。PC 模拟器已实际切换通用、外观与网络分组验收。

集合与默认数据回归：集合和文件夹节点移除方框字符，改为接近 VS Code Explorer 的展开箭头加闭合/展开文件夹图标；内置系统环境固定显示为“开发环境 / 预发布环境 / 生产环境”，恢复旧本地状态时保留变量但规范化系统环境名称。首次启动的示例集合、文件夹、请求及参数说明均改为中文，用户自行创建和导入的集合名称不受影响。已在 PC 模拟器验证新文件夹图标与已有环境名称迁移。

集合操作回归：顶层集合、嵌套文件夹和请求统一使用行尾三点菜单，不再展示分散的加号和铅笔入口。集合/文件夹菜单支持直接新建并打开已保存请求、新建子文件夹、重命名和确认后级联删除；请求菜单支持重命名、在原位置创建独立副本和确认后删除。删除集合或文件夹会同步取消并移除其下请求、保存记录与已打开标签；PC 侧栏与 Phone 集合抽屉共用同一数据路径。中英文菜单、确认框和结果提示已补齐，PC 模拟器已验证顶层集合与请求菜单的完整显示。

集合菜单定位回归：行尾三点按钮不再显示背景块或边框，鼠标仅悬停该按钮时图标切换为品牌色。菜单改用独立 Popup 浮层，打开前后集合树节点位置保持不变；PC 端记录鼠标在按钮内的实际按下坐标，并将该点与菜单左上角对齐，鼠标离开菜单区域后自动关闭。无鼠标的触屏设备使用按钮中心作为锚点并支持点击外部关闭。已在 PC 模拟器验证浮层左上角定位与节点坐标稳定性。

集合侧栏尺寸回归：PC 与 Tablet 布局在集合栏右侧提供 8vp 的可拖动热区，宽度限制为 200–420vp，拖动结果通过 `PersistentStorage` 跨重启保留；双击分割线恢复 260vp 默认宽度。Phone 继续使用固定宽度的集合抽屉。已在 MateBook Pro 模拟器验证向两侧拖动、最小宽度限制、双击重置和重启恢复，工作区会随侧栏宽度同步重排。

JSON 输入体验回归：可编辑 JSON RichEditor 不再在每个字符输入后立即重建整段 StyledString，高亮改为输入停顿 120ms 后统一刷新；请求草稿仍实时更新以保证发送使用最新正文，但完整本地状态序列化改为 180ms 防抖。编辑器支持 `{}`、`[]`、`()` 与双引号自动配对，选中文本后输入起始符会包裹选区，输入已有闭合符时只移动光标而不重复插入，退格可成对删除。Enter 会沿用当前行缩进，在空对象/数组内自动生成两空格内层和闭合符所在行；JSON 字符串外输入冒号会补一个空格；Tab / Shift+Tab 支持光标位置及多行选区缩进/反缩进，同时保留 Ctrl+Enter 发送请求。已在 MateBook Pro 模拟器用硬件键盘事件完整验证花括号换行、字段引号、冒号空格、Tab 与 Shift+Tab，测试请求已在验收后关闭。

请求工作区控件回归：桌面 Request Tab 固定为一致宽度，名称占用中间弹性空间，脏状态与关闭按钮稳定贴在右侧；Method 与 URL 使用单一外边框和圆角，中间仅保留低对比度竖分割线。Params、Headers、表单、Multipart 与环境变量复用的行启用框改为圆角方形；Multipart 文本/文件类型不再使用臃肿的系统 Select，改为 92vp 轻量触发器和 116vp 浮层菜单，当前类型有勾选标记。已在 MateBook Pro 模拟器的深色 Compact PC 布局验证标签、组合输入框、方形勾选框和两行 Multipart 类型控件，浮层不会改变表格行高。

请求细节联动回归：KeyValueEditor 表头首列只保留与数据行对齐所需的空白宽度，不再显示无实际含义的对号；Method 触发器使用 14vp 圆角线条 SVG 箭头替代尖锐字符，默认垂直居中，展开时平滑旋转。Request Tab 的 `ForEach` 渲染 Key 纳入名称、Method 与脏状态，集合树重命名已打开请求后不再复用旧 Tab 文本。已在 MateBook Pro 模拟器执行“用户 → 联动验收 → 用户”的实际改名流程，集合行与右侧已打开 Tab 两次均同步更新，原名称已恢复。

URL 输入效率回归：请求 URL 输入框在内容精确为 `h` 时按 Tab 补全为 `http://`，精确为 `hs` 时补全为 `https://`，补全后焦点保留且光标移动到协议末尾；其他内容按 Tab 继续使用系统默认焦点导航，不做猜测性改写。已在 MateBook Pro 模拟器分别验证两条补全路径，并在验收后将测试 URL 恢复为空。

字体与请求配置布局回归：单个请求的 Settings 内容区显式从顶部起始排列，不再因内容较少而垂直居中。全局偏好新增“鸿蒙字体 / 系统默认 / 紧凑字体”三档应用级字体选项，默认使用 `HarmonyOS Sans SC`，代码与 JSON 表面继续保留等宽字体；偏好随本地 schema v5 持久化，schema v1–v4 自动迁移为鸿蒙字体。Params、Headers、表单、Multipart 与环境变量共用表格的输入字号由 13vp 收紧到 12vp，表头按 Checkbox 的真实布局占位校准，与键、值、类型和描述输入列对齐。已在 MateBook Pro 模拟器验证请求 Settings 顶部基线、外观页字体即时切换及重启持久化，并将验收后的字体恢复为鸿蒙字体。

环境管理与标题栏回归：环境页新增自定义环境创建入口，创建后自动选中并可立即编辑变量；自定义环境提供确认后删除，三个系统环境继续禁止删除。标题栏不再使用具有约 50vp 强制最小高度的原生 Select，改为 28vp 高、11vp 字体的轻量环境切换器，菜单支持选中态、悬停态、名称截断与点击外部关闭。已在 MateBook Pro 模拟器完成“创建 QA 环境 → 标题栏同步 → 删除确认 → 重启持久化”验收，验收数据随后已清理。

搜索图标对齐回归：标题栏搜索框、Phone 搜索按钮和全局搜索弹窗不再使用受字体基线影响的 `⌕` 字符，统一改为固定 viewBox 的圆角线性 SVG，并通过 14/16/18vp 图标盒垂直居中。

标题栏窗口行为回归：移除工作区标题区域在 `TouchType.Down` 时直接调用 `startMoving()` 的逻辑，改由鸿蒙 `setWindowTitleMoveEnabled(true)` 处理原生拖动。最大化状态下单击标题栏只聚焦，不再退出最大化；标题工作区的双击手势读取 `WindowStatusType`，浮动状态调用 `maximize()`，`MAXIMIZE / FULL_SCREEN` 状态调用 `recover()`，形成确定且对称的最大化/恢复行为。

媒体响应回归：HTTP Engine 继续以 ArrayBuffer 接收非文本响应，Controller 根据 `Content-Type: image/*` 与 `video/*` 标记媒体类型；NimboWindow 将媒体字节写入应用缓存中的可替换临时文件，成功后以普通 Success 响应进入 ResponseHeader，因此状态码、Headers、Cookies、耗时与协议仍可查看。Body 页对图片使用等比 Contain 预览，对视频使用鸿蒙原生 Video 控件，支持播放、暂停、拖动进度和全屏；两者均保留原始二进制保存，解码或缓存失败时回退到已有 Binary 下载界面。已在 MateBook Pro 模拟器真实请求 `image/png` 与约 2.7 MB 的 `video/mp4`，验证图片显示、视频首帧/播放、媒体元数据和保存入口，随后关闭验收请求。

响应正文操作回归：文本与 JSON 响应的 Body 工具栏新增搜索、复制、下载三个紧凑图标按钮；搜索在 Pretty / Raw 间共享查询，实时高亮全部匹配并支持上下循环定位，打开后自动聚焦，`Esc` 可关闭并清空查询。复制将完整响应正文写入系统剪贴板并显示“已复制响应正文”Toast；下载根据 Content-Type 使用 json、xml、html、css、js、yaml、csv 或 txt 后缀拉起系统文件选择器。图片、视频与其他二进制响应继续提供原始字节下载，不显示无意义的正文搜索或复制。已在 MateBook Pro 模拟器用 `https://httpbin.org/json` 验证 3 处匹配导航、Pretty / Raw 查看、Esc 关闭、复制 Toast 和 `nimbo-response.json` 下载文件名。

PC 发布素材回归：当前发布清单收口为 `2in1`，平板与手机响应式实现继续保留但不进入本次分发。首次安装的中文演示集合扩展为“用户服务 / 内容服务 / 媒体资源 / 响应示例 / 身份认证”，新增的请求均可打开真实示例 URL。`release/appgallery/` 提供 216×216 PNG 图标、五张真实模拟器 1920×1080 PNG 截图、中文商店文案、可导入 Postman 示例集合及 Release 构建产物。已确认 Release HAP 为 `debug: false` 且仅声明 `2in1`；本机现有 Profile 仍为设备绑定的 debug 类型，因此已签名包仅供模拟器测试，正式上架必须使用发布证书/Profile 或 AppGallery Connect 云管理签名。

### Milestone 11 — API Schema & Response Workflows

Milestone 11 将后续候选能力收敛为不依赖账号、云端或 Runner 的本地请求串联闭环。任意 JavaScript 执行不与声明式规则混在同一阶段，避免在缺少沙箱、超时和权限边界时引入脚本风险。

分三批完成：

1. OpenAPI 3.0 / 3.1 与 Swagger 2.0 导入：先支持本地 JSON 文件，按首个 Tag 生成文件夹，导入 Server、Path、Method、Query、Header、示例 Body 和 Basic / Bearer / API Key；导入前展示请求数、文件夹数和未支持项，失败不得污染现有集合
2. Response JSONPath 与变量提取：支持预览匹配结果，将提取规则保存到请求，并在响应成功后写入明确选择的环境；缺失路径、类型不匹配和敏感值必须有可见结果，不允许静默覆盖
3. 声明式 Tests：支持状态码、响应时间、Header 存在/相等、JSONPath 存在/相等等规则，在单次响应中展示逐项通过或失败；规则与结果分离，结果不进入长期持久化

验收要求：常见 OpenAPI / Swagger JSON 能原子导入为可立即发送和保存的集合；导入引用 Schema 时能生成稳定 JSON 示例；JSONPath 提取不会跨请求或跨环境意外写值；Tests 不执行任意代码且每条规则都有确定结果；中英文、深浅主题、本地恢复和既有 Postman/cURL 导入不退化；构建无新增 warning。

第一批进度（2026-09-11）：已实现 OpenAPI 3.0 / 3.1 与 Swagger 2.0 JSON 本地导入。新增独立解析服务和四步导入预览，支持首个 Server、Server Variable 默认值、Tag 文件夹、Path/Query/Header 参数、JSON 示例、表单/Multipart、Basic/Bearer/API Key，并对未赋值 Path 参数、Cookie 参数和不支持的认证给出警告。入口已加入新建 Split Button 与全局搜索，导入结果复用现有 Collection / Request 持久化路径。仓库质量检查和签名 HAP 构建通过；仍只有 Milestone 5 已知的两条 Redirect Interceptor 兼容提示。YAML、远程 URL 和外部 `$ref` 暂不在第一批支持范围。

第一批 UI 收口（2026-09-11）：导入从新建 Split Button 移至 Title Bar 独立 Icon，左侧新建恢复为单一按钮，不再存在下拉菜单影响侧栏或 Workspace Tab 布局。统一导入弹窗采用 760px PC 横向布局，以 cURL / API 文件 Tab 承载两类入口并压缩不必要的纵向留白；cURL 输入区升级为支持命令、参数、Method、URL 与字符串着色的 RichEditor；API 文件可点击选择或拖入 Drop Zone，自动识别 Postman Collection/Environment、OpenAPI 3.x 与 Swagger 2.0，并进入同一预览/原子导入流程。全局搜索同步合并为单一“导入”命令。

Title Bar 视觉回归（2026-09-11）：右侧操作固定为“环境选择 → 导入 → 设置 → 原生窗口控制”，避免环境切换器被两个操作按钮夹在中间。导入与设置复用同一 32px 圆形 Icon Button 的颜色、Hover、Pressed 和无障碍行为；HarmonyOS 原生窗口按钮同步调整为 18px 图标、32px Hover 背景、统一圆角与间距，继续保留系统最小化、最大化和关闭语义。

第二批进度（2026-09-11）：请求配置新增“提取”页，可保存多条 JSONPath → 环境变量规则并基于当前响应只读预览。发送得到 2xx/3xx JSON 响应后才执行规则，每条规则必须明确目标环境；同名变量默认报告冲突，只有开启“允许覆盖”才会更新，敏感值可写入 Secret 变量。成功、路径未匹配、JSON/JSONPath 无效、目标环境缺失和覆盖冲突均显示逐条结果，执行结果仅保留在当前响应、不进入长期持久化。JSONPath 当前支持根 `$`、点属性、引号属性、数组索引和属性/数组通配符；过滤器、递归下降和脚本表达式暂缓。持久化 schema 升级至 v6，旧请求自动补齐空规则且不丢数据。仓库质量检查和签名 HAP 构建通过；仍只有 Milestone 5 已知的两条 Redirect Interceptor 兼容提示。

第三批进度（2026-09-11）：请求配置新增“测试”页，支持状态码等于、响应耗时小于、Header 存在/等于、JSONPath 存在/等于六类声明式规则。启用规则在每次真实 HTTP 响应返回后基于同一响应快照执行；网络错误明确显示未执行，配置无效、Header 缺失、JSON/JSONPath 无效、路径未匹配和值不相等均显示本地化失败原因、期望值和实际值。响应区新增“测试”页及通过数 Badge，规则随请求持久化，执行结果只存在于当前 ResponseModel，不写入本地数据。持久化 schema 升级至 v7，schema v1–v6 自动迁移并补齐空测试规则。MateBook Pro 模拟器已验证状态码失败→通过的即时刷新、重启后规则恢复、JSONPath 连续字段编辑和 `$.id = 101` 通过结果；验收过程中修复了 ArkUI ForEach 复用导致的旧结果卡与字段互相覆盖。仓库质量检查和签名 HAP 构建通过，仍只有 Milestone 5 已知的两条 Redirect Interceptor 兼容提示。至此 Milestone 11 三批全部完成。

继续暂缓：WebSocket、SSE、GraphQL、gRPC、Runner、任意 JavaScript Scripts、AI、Cloud、Login，以及 PRD 归入 1.1/1.2 的其他能力。

### Milestone 12 — Sandboxed Request Scripts

Milestone 12 只实现单请求级 Pre-request / Post-response JavaScript，不同时引入 Collection Runner、集合级脚本、第三方包、远程模块或完整 Postman `pm.*` 兼容层。脚本必须在独立原生运行时中执行，默认 500ms、最长 5s，默认 8MB、最大 64MB，并限制原生栈与日志总量；不得暴露文件、进程、系统、动态模块加载或额外网络 API。任何异常、超时或内存限制必须成为可见结果，不允许卡住 UI 线程或让失败脚本污染请求与环境状态。

计划分三批：第一批完成可中断的原生 JavaScript 沙箱、异步桥接和边界自测，不展示尚不可用的 UI；第二批加入 Pre-request 编辑器与最小 `nimbo.request` / `nimbo.environment` API，只有脚本成功后才原子应用请求修改；第三批加入只读 `nimbo.response`、Post-response 环境写入、控制台与运行结果 UI。执行顺序明确为 Pre-request → 原子应用环境写入 → 变量替换 → HTTP → Post-response → 声明式提取 → 声明式 Tests，使脚本刚写入的 Token 可以用于同一次请求，同时保持声明式后处理顺序稳定。

第一批进度（2026-09-11）：拒绝直接使用系统 JSVM 作为脚本沙箱。当前兼容 SDK 的公开 JSVM API 虽提供 VM 内存上限，但没有可用于终止死循环的公开执行中断接口。已改用固定版本 QuickJS-NG v0.16.2，以 MIT 许可证保留最小源码集；不编译 QuickJS libc/CLI，仅通过 N-API 暴露异步 `run`，并设置内存、栈、源码大小、执行时限、并发数以及日志数量/总量上限。MateBook Pro 模拟器已验证普通脚本及 console 日志正常返回、`while (true)` 在 20ms 边界被中断、持续分配在 2MB 边界被归类为 `memoryLimit`，三类任务均未阻塞 UI 线程。当前运行时尚未接入请求生命周期或产品 UI，第二批开发前仍保持功能不可见。

第二批进度（2026-09-11）：请求配置新增“前置脚本”页及独立启用开关，使用带行号、自动配对、缩进和 JavaScript 语法高亮的编辑表面。最小全局 API 包含可读写的 `nimbo.request.method/url/body/bodyType`、大小写不敏感的 `nimbo.request.headers.get/set/remove`、`nimbo.environment.get/set` 及受限 `console`；不提供文件、系统、模块加载或额外网络能力。每次执行使用全新 VM，用户代码通过独立 Function 运行，不能直接捕获桥接层内部状态。只有成功结果才会把请求修改应用到本次发送，并将环境写入一次性落盘；异常、超时、内存限制与取消均不会应用迟到或部分修改，请求编辑器原值也不会被脚本反向覆盖。持久化 schema 升级至 v8，旧请求自动补齐关闭状态的空脚本。MateBook Pro 模拟器已验证 Method、URL、Header、Body、环境写入和 console 日志能够从原生沙箱完整返回；签名 HAP 构建和安装启动通过，仍只保留 Milestone 5 已知的两条 Redirect Interceptor 兼容提示。脚本日志与成功结果 UI、Post-response API 留到第三批，不提前展示未完成入口。

第三批进度（2026-09-11）：请求配置新增“后置脚本”页，提供只读 `nimbo.response.statusCode/statusText/body/contentType/size/duration/protocol`、大小写不敏感的 `nimbo.response.headers.get`、`nimbo.environment.get/set` 与受限 `console`。后置脚本只在收到 HTTP 响应后执行；失败保留原始响应并继续执行声明式提取和 Tests，但不会应用任何环境写入。响应区新增“脚本”页，按阶段展示成功、异常、超时或内存限制、耗时、错误堆栈及逐行控制台；错误、Large 与 Binary 响应也统一保留响应 Tab，使脚本结果始终可达。执行链已固定为 Pre-request → 原子应用环境写入 → 变量替换 → HTTP → Post-response → 原子应用环境写入 → 声明式提取 → 声明式 Tests。请求与响应 Tab 在内容增多后改用不压缩文字的横向滚动布局。持久化 schema 升级至 v9，schema v1–v8 自动补齐关闭状态的后置脚本。MateBook Pro 模拟器通过真实 `GET /posts/1` 验证 `200 OK`、`nimbo.response.statusCode`、脚本成功结果、耗时和 console 输出；独立原生探针验证环境写入 `responseId=42` 仅在成功时返回，桥接内部状态不可捕获。仓库质量检查、签名 HAP 构建与安装启动通过，仍只保留 Milestone 5 已知的两条 Redirect Interceptor 兼容提示。至此 Milestone 12 三批全部完成。

继续暂缓：Collection Runner、集合级脚本、第三方脚本包、远程模块、完整 Postman `pm.*` 兼容层，以及 WebSocket、SSE、GraphQL、gRPC、AI、Cloud、Login 等既定后续范围。

### Milestone 13 — Release Hardening & Script UX

Milestone 13 不扩展协议、账号、云端或 Runner 范围，只针对 Milestone 12 新增脚本能力和当前公开 Alpha 的交付质量做收口。禁止借机引入 Collection Runner、集合级脚本、第三方包、远程模块或完整 Postman `pm.*` 兼容层。

分三批完成：

1. 完善脚本编辑体验：在已有 JavaScript 语法高亮、括号配对、智能换行和缩进基础上，增加与执行阶段一致的上下文 API 补全与键盘接受；前置脚本不得提示只读响应 API，后置脚本不得提示可写请求 API
2. 加固运行时边界：覆盖异常响应、大响应、Binary、取消、脚本与声明式提取/Tests 组合等边界，并确保 Secret、Authorization 与敏感日志不会进入非必要结果或导出路径
3. 完成发布回归：覆盖旧 schema 升级、本地恢复、中英文、Light/Dark、桌面不同窗口宽度、真实网络请求和 Release 构建，修复阻断发布的问题并整理验收记录

验收要求：编辑器提示的 API 必须与对应阶段实际可用 API 一致；补全不能破坏 Tab/Shift+Tab 缩进、括号配对或 Ctrl+Enter 发送；脚本失败和限制状态不得污染请求、环境、响应及声明式后处理；敏感数据不得因新增结果展示或导出而扩大暴露面；既有导入、集合、请求、响应与持久化路径不退化；构建无新增 warning。

第一批进度（2026-09-12）：Pre-request / Post-response 共用的 JavaScript RichEditor 新增上下文候选浮层。输入 `nimbo.*`、`console.*` 或 `JSON.*` 前缀后展示最多六项候选，上下方向键可循环选择，Enter / Tab 接受当前项，函数补全后光标落在参数括号内，Esc 关闭候选且鼠标可直接选择或悬停切换。前置候选仅包含可写 `nimbo.request`、环境、控制台和 JSON API；后置候选仅包含只读 `nimbo.response`、环境、控制台和 JSON API。无候选时 Enter 与 Tab / Shift+Tab 继续保持原有换行和缩进语义。MateBook Pro 模拟器已验证后置脚本输入 `nimbo.res` 只展示 response 候选，向下选择第二项后可分别通过 Enter 和 Tab 补全为 `nimbo.response.statusText`；仓库质量检查和签名 HAP 构建通过，仍只保留 Milestone 5 已知的两条 Redirect Interceptor 兼容提示。第二、三批尚未开始。

同批既有能力补完（2026-09-12）：响应区“时间线”移除不可用占位内容，接入 HarmonyOS HTTP `performanceTiming` 的真实阶段数据。网络层将累计时间点转换为 DNS、建立连接、TLS 握手、发送请求、等待响应首字节（TTFB）、下载响应和总耗时，响应模型在媒体预览、Large Preview、脚本、提取与 Tests 状态转换中完整保留计时快照。时间线使用主题 Token 展示各阶段时长和相对占比，并说明连接复用时 0 ms 的含义，不伪造底层未提供的数据。MateBook Pro 模拟器真实 HTTPS POST 验证总耗时 684 ms，阶段数据为 DNS 2 ms、连接 4 ms、TLS 368 ms、发送 <1 ms、TTFB 278 ms、下载 <1 ms，内容可完整纵向滚动。

同批 Tests 与 Tab 操作回归（2026-09-12）：修复“响应时间小于”将带 `ms` 单位的展示字符串直接传入 `Number()` 而恒定得到 `NaN` 的问题；规则现在优先读取时间线的数值型总耗时，并兼容解析旧响应展示值。MateBook Pro 模拟器真实图片请求以 5000 ms 为上限执行，实际 1479.555 ms 并正确显示通过，不再报告“无法获取响应耗时”，验收规则随后已清理。桌面请求 Tab 新增鼠标右键菜单，菜单以指针位置为锚点，提供关闭当前、关闭全部和新建请求；关闭操作会取消对应的在途请求并持久化剩余标签状态，中英文资源已补齐。

环境操作区回归（2026-09-12）：桌面与窄窗口环境页将删除、保存按钮收敛到带 8vp 间距的独立操作组，危险操作与主操作不再粘连；环境名称与说明列显式使用左对齐，不再受 Column 默认居中行为影响。MateBook Pro 模拟器实际显示两个按钮间保留约 8vp 间距，名称与说明的左边界一致，系统环境继续只显示保存按钮。

环境变量编辑回归（2026-09-12）：键、值、说明、启用状态、类型和文件选择改为基于当前数组的字段级不可变更新，避免某个输入框携带旧行快照覆盖其他字段；环境行仅在 Secret 显示模式实际变化时用稳定的 `id + 显示模式` Key 重建值编辑器，使开启/取消 Secret 立即在 RichEditor 与密码输入之间切换，同时新节点始终接收当前值与说明。密码输入的列宽、左右内边距、字号和背景与普通变量输入统一，遮罩圆点不再产生额外左侧空白。MateBook Pro 模拟器按“填写值 → 填写说明 → 开启 Secret”的原问题路径验证值与说明保留，并再次验证 `task_id` 开启后立即遮罩、关闭后立即恢复原值且两种状态均与值列表头对齐；验收后恢复了原 Secret 状态。

请求保存与 URL 变量回归（2026-09-12）：请求工具栏移除独立保存按钮，`Ctrl+S` 成为统一保存入口；已在集合中的请求直接更新，新请求弹出集合/文件夹选择，不再默认写入不明确的位置。URL 输入升级为单行 RichEditor，当前环境中已启用的变量会在输入 `{{` 后按前缀提示，支持上下键选择、主键盘/数字键盘 Enter 或 Tab 接受，并对有效、未闭合和未定义引用分别高亮；接受候选后会恢复 URL 编辑器焦点和光标，避免 Tab 继续跳到发送按钮并显示系统蓝色焦点框。发送前仍由 RequestController 在完整 URL（含 Path）中执行 `{{name}}` 替换。环境变量开启 Secret 后值输入框立即使用密码遮罩，切换前后的真实值保持不变。MateBook Pro 模拟器已验证 Ctrl+S 文件夹弹窗、变量候选/Enter 接受、候选补全后的焦点行为及 Secret 遮罩与值恢复，验收临时变量和请求随后已删除。

环境变量输入面扩展（2026-09-12）：`{{name}}` 的当前环境候选、上下键选择、Enter/Tab 接受、有效/未定义引用高亮已从 URL 扩展到 Params、Headers、Basic/Bearer/API Key 认证、JSON/纯文本正文、Form 与 Multipart 的可发送键和值；说明、文件路径和不会参与 HTTP 构建的配置字段不提供误导性提示。认证密码、Token 和 API Key 的字面值默认继续遮罩，输入变量引用或主动点击显示后才进入带高亮的变量编辑状态。RequestController 原有替换顺序保持不变，发送时会在 URL/Path、参数、标头、认证和各正文类型中统一解析当前环境的已启用变量。MateBook Pro 模拟器已验证 Bearer 与 JSON 正文的候选显示、Enter 补全和高亮，表格类字段共享同一已编译组件；验收请求随后已关闭。

代码编辑与生成回归（2026-09-12）：JSON / JavaScript RichEditor 增加独立于样式重建的最多 100 步撤销栈，支持 `Ctrl+Z` 撤销、`Ctrl+Shift+Z` / `Ctrl+Y` 重做和 `Ctrl+A` 全选，自动括号、缩进、冒号空格和候选补全同样进入历史。请求配置在“测试”与“请求设置”之间新增“生成”页，可根据当前草稿生成 cURL、JavaScript Fetch、Python Requests 和 Go net/http 示例并复制；JavaScript、Python 与 Go 均按各自关键字、注释、字符串、数字和标点高亮，语言切换时会立即重建正确样式。URL 参数、Headers、认证和常见正文类型会进入代码，`{{环境变量}}` 原样保留，不在代码预览或剪贴板中展开 Secret。Multipart 在各语言能力不一致时只生成明确可表达的部分并保留提示，不引入第三方模板或 Runner。MateBook Pro 模拟器已验证 JSON 输入后的撤销/重做、`Ctrl+A → Delete`、Go 高亮、Go → JavaScript 高亮恢复、生成页语言切换、只读代码预览、复制 Toast，以及现有请求中的 `{{host}}` / `{{key}}` 在 cURL 中保持未展开；验收临时请求随后已关闭。

请求名称编辑回归（2026-09-12）：桌面请求 Tab 支持双击名称进入原位编辑，进入时自动聚焦并全选当前名称；Enter 或失焦确认，Esc 取消，空名称不会覆盖原值。集合内请求重命名会同步更新集合树、持久化请求元数据和对应的所有打开 Tab；未保存请求只更新当前工作区名称，后续 `Ctrl+S` 仍以新名称打开保存位置选择。MateBook Pro 模拟器已验证双击、自动全选、Enter 保存、集合树同步和 Esc 取消，并在验收后恢复原请求名。

脚本候选键盘回归（2026-09-12）：候选打开时的上/下方向键、Esc、Enter 和 Tab 改在 RichEditor 按键分发阶段优先处理，防止系统编辑器先执行光标移动、换行或焦点跳转；无候选时仍保留正常的换行、Tab 缩进和 Shift+Tab 反缩进。MateBook Pro 模拟器已分别验证前置脚本 `nimbo.req` 下移后 Enter 补全为 `nimbo.request.url`、继续下移后 Tab 补全为 `nimbo.request.body`，以及后置脚本 `nimbo.res` 下移后 Enter 补全为 `nimbo.response.statusText`；验收临时请求随后已关闭。

认证敏感输入回归（2026-09-12）：Bearer Token、Basic Password 与 API Key Value 统一改为按内容选择显示方式：空值和包含 `{{` 的环境变量表达式默认使用可见的变量编辑器，保留候选与高亮；只有非空且不含变量引用的字面敏感值才在失焦后自动遮罩。编辑字面值时保持当前输入可见，避免首字符后切换组件造成焦点或光标位置丢失；字面值仍可通过“显示/隐藏”主动切换，变量表达式不提供误导性的隐藏操作。MateBook Pro 模拟器已验证 Bearer 空值可见、字面 Token 失焦后遮罩、变量输入保持可见，以及 Basic 空密码使用相同默认行为；验收临时请求随后已关闭。

脚本候选可见性回归（2026-09-12）：受 Request / Response 分割高度限制时，候选浮层固定为两行的紧凑可滚动列表；键盘移动选中项会使用 `ScrollAlign.AUTO` 平滑滚动到可见区域，新一轮候选则重置到首项。MateBook Pro 模拟器已验证 `nimbo.req` 六项候选从第 1 项连续向下滚动至第 6 项、再连续向上返回第 1 项，当前选中项始终可见；验收临时请求随后已关闭。

紧凑侧栏新建按钮回归（2026-09-12）：非最大化窗口继续按响应式设计只显示新建图标，但不再使用受字体字形与缩放影响的 `+` 字符；紧凑按钮与完整“新建”按钮统一复用固定 viewBox、圆角端点的 SVG 加号，避免横线右端被裁切或视觉偏心。MateBook Pro 模拟器重新安装签名 HAP 后，在非最大化窗口验证加号完整且水平、垂直居中；仓库质量检查和签名构建通过，仍只保留 Milestone 5 已知的两条 Redirect Interceptor 兼容提示。

品牌与导航图标回归（2026-09-12）：桌面侧栏和移动端底栏不再依赖系统字体中的主页、方框、圆环、时钟和齿轮字符，统一改用 20 × 20 viewBox、圆角端点和约 2px 描边的 SVG 图标；工作区、集合、环境、历史和设置均提供独立选中态，选中态使用品牌色并略微加粗。App Icon 参考灵题已确认的立体品牌语言，从通用云朵改为珍珠质感的立体流动 `N`，两端节点表达 Request / Response；最终配色受现有 Design Token 约束，背景以 `#5B68F6` / `#4D59E5` 柔和蓝紫为主，白色丝带呼应 Workspace，节点使用接近 Success / GET 的克制薄荷绿，禁止高饱和紫红、电光蓝和大面积霓虹光晕。系统负责最终圆角蒙版。AppScope 与 Entry Ability 使用符合平台规范的 1024px 前景、背景分层资源，前景保留真实 Alpha，背景完全不透明；标题栏和 AppGallery 1024px / 216px 上传图由同一组分层母版合成，确保软件包图标与商店图标一致。MateBook Pro 模拟器在非最大化窗口重新安装验收，导航图标线宽、视觉中心和选中态一致，新 App Icon 在 28px 标题栏与系统 Dock 均可辨识且与新建、发送、选中态处于同一色相体系。

标题栏焦点状态回归（2026-09-12）：EntryAbility 监听原生 `windowEvent`，将 WINDOW_ACTIVE / WINDOW_SHOWN 与 WINDOW_INACTIVE / WINDOW_HIDDEN 映射到共享窗口焦点状态，并在销毁时解除监听。导入、设置以及窄窗口搜索按钮通过同一 ToolbarIconButton 在失焦时同步降低不透明度，聚焦后恢复 Hover / Pressed 反馈，从而与系统最小化、最大化、关闭按钮保持一致。MateBook Pro 模拟器分别截取聚焦与点击窗口外桌面后的状态，确认自定义操作和原生窗口按钮同步变淡、恢复；签名构建通过且无新增 warning。

AppGallery 海报素材回归（2026-09-12）：卸载旧版并重新安装当前签名 HAP 后，在 MateBook Pro 模拟器最大化窗口采集请求与响应、JSON 正文编辑、环境变量、历史记录和设置五个真实页面。原始 3120 × 2080 图像只裁掉系统 Dock 和底部区域，使用精确 16:9 的 3120 × 1755 应用画面，并等比缩放为 1504 × 846 嵌入 1920 × 1080 海报，禁止非等比拉伸。海报采用无文字的柔和品牌背景，标题与说明由脚本使用 HarmonyOS Sans SC 确定性排版，避免生成式文字错误。五张 PNG 均小于 1 MB；原始截图、背景和可重复生成脚本保留在 `release/appgallery/posters/` 与 `scripts/generate-appgallery-posters.sh`。

1.0 发布包（2026-09-12）：正式版本名称更新为 `1.0`，内部 `versionCode` 从 Alpha 的 `1000000` 递增为 `1000001`。使用共享发布证书与 Nimbo 独立发布 Profile 清理构建后生成 `release/appgallery/package/Nimbo-1.0-PC-release-signed.app`；包内元数据确认 `com.nimbo.app`、`2in1`、compatible API 20、target API 24 和 Release 类型。应用图标升级为 1024px 前景、背景分层资源后重新构建，`hap-sign-tool verify-app` 的摘要验证成功，提取 Profile 与 `/Users/lake/app/profile/Nimbo-发布ProfileRelease.p7b` 完全一致；最终包约 3.6 MB，SHA-256 为 `70458cca01b0c717e6f101e91539c8a0d06e52dca9d6bd4163e50826d60c9e2f`。

继续暂缓：Milestone 12 末尾列出的所有能力，以及未在本里程碑明确列出的新协议与在线能力。

### Milestone 14 — Collection Runner

Milestone 14 在已有单请求执行链之上增加本地集合运行器，目标是让集合、文件夹和单个已保存请求能够按树中顺序批量执行，并复用同一套前置脚本、环境变量替换、HTTP、后置脚本、JSONPath 提取和 Tests 行为。不得为 Runner 复制一套语义不同的网络或脚本流程；后一个请求必须能读取前一个请求成功写入或提取的环境变量。

分三批完成：

1. 顺序运行闭环：从集合树菜单选择运行范围，配置迭代次数与请求间隔，支持开始、停止、实时进度、HTTP 状态、耗时及断言通过/失败数量
2. 结果复盘：增加单次运行摘要、失败定位、结果筛选及本地报告导出，不把每个 Runner 请求写入普通历史造成噪声
3. 数据驱动：在明确数据映射与 Secret 边界后支持本地 CSV / JSON 迭代数据；导入失败必须可见且不得部分执行

第一批进度（2026-09-24）：集合、文件夹和单个请求的三点菜单已增加“运行”，集合运行器支持 1–100 次迭代、0–60000 ms 请求间隔、开始、停止、实时队列状态、HTTP 状态、耗时和 Tests 通过/失败计数。当前实现范围仅为单环境、严格顺序执行；开始运行时快照当前环境选择，每个请求复用已有的 Pre-request → 环境写入 → 变量替换 → HTTP → Post-response → 环境写入 → JSONPath 提取 → Tests 管线，因此后一个请求可以读取前一个请求产生的变量。停止操作会取消当前网络任务并把当前及尚未执行的项目标记为已停止，Runner 结果不写入普通历史。仓库质量检查和签名 HAP 构建通过，无新增 warning，仍只保留 Milestone 5 已知的两条 Redirect Interceptor 兼容提示。并发运行、集合级脚本、云端报告和 Postman Runner 完整兼容层不在本批范围内。

第二批进度（2026-09-24）：运行结果新增全部、通过、失败和已停止筛选；失败项可原位展开，定位到网络错误类型、前置/后置脚本阶段、提取规则或 Test 类型，不显示可能携带敏感信息的实际值。完成或停止后可通过系统文件选择器导出 `nimbo.runner.v1` JSON 报告，包含范围、环境名称、时间、汇总、Method、状态码、耗时、断言计数和脱敏失败分类；明确不导出 URL、请求/响应正文、Headers、环境变量值、提取值或脚本日志。报告仅按用户操作导出，不新增持久化 schema，也不写入普通历史。仓库质量检查和签名 HAP 构建通过，无新增 warning。

第三批进度（2026-09-24）：集合运行器支持选择本地 CSV 或 JSON 迭代数据。CSV 第一行为唯一且非空的变量名，支持引号、转义引号和字段内换行；JSON 必须为非空对象数组，字段值仅接受字符串、数字、布尔值或 null。文件上限 2 MB、1000 行、100 列，空文件、重复/空列名、CSV 列数不一致、未闭合引号、嵌套 JSON 值等错误会显示具体位置并禁用运行，不允许部分导入或部分执行。每行数据对应一次完整集合迭代，行字段作为临时变量层通过现有 `{{name}}` 替换、脚本环境读取、认证和正文链路生效，优先级高于所选环境；临时数据不写回环境，脚本显式写入和声明式提取仍保持原有持久化语义。运行报告只记录数据文件名与行数，不记录任何行内容。至此 Milestone 14 三批功能开发完成，实体机交互与真实集合回归按统一安装验收计划执行。

深色视觉回归（2026-09-28）：Dark Mode 从偏蓝灰的单一表面调整为中性炭黑体系，窗口、导航栏、集合侧栏、工作区、控件表面和代码区使用递进明度，边框、正文、次要文字与悬停/选中状态同步提高对比；品牌紫收敛到主要操作、焦点和选中反馈。导航、搜索、设置、导入、响应操作、文件夹与 Runner 运行图标增加深色资源，不再直接沿用浅色硬编码颜色。Light Mode 令牌保持不变；仓库质量检查、资源编译、签名 HAP 构建和实体 HarmonyOS PC 安装启动均通过，无新增 ArkTS warning，仍只保留 Milestone 5 已知的两条 Redirect Interceptor 兼容提示。

标题栏最大化回归（2026-09-28）：自定义标题栏会监听窗口状态并同步右侧系统按钮安全区；最大化或全屏且系统窗口按钮隐藏时释放固定占位，只保留窗口边缘间距，恢复浮动窗口后重新读取系统标题按钮矩形并恢复避让。实体 HarmonyOS PC 已通过“普通窗口 → 双击标题栏最大化 → 双击恢复”往返验证，导入和设置按钮在最大化时靠右排列，在普通窗口时不会与最大化、最小化和关闭按钮重叠。

响应错误诊断回归（2026-09-28）：请求失败不再只显示底层的一行错误文本，而是按 URL 校验、缺失变量、DNS、建立连接、TLS、发送、接收、代理、文件和前置脚本阶段展示本地化摘要、可能原因、建议检查、Method、脱敏 Host、耗时、超时及系统错误码；技术详情按需展开，并可复制诊断信息。HTTP 引擎保留系统 `BusinessError` 的错误码和消息，不再把非标准 `Error` 统一丢失为未知错误；HarmonyOS HTTP 常见错误码会映射到对应诊断类型。发送前会检查 URL、Params、Headers、认证和可发送正文中的 `{{变量}}`，缺少启用值时直接列出变量而不发起网络请求。复制内容不包含 URL Path、Query、Headers、请求/响应正文、环境变量值或脚本详情，系统消息中的完整 URL 也只保留 Origin。中英文资源、仓库质量检查和 HAP 构建通过；实体 HarmonyOS PC 已验证 `https://localhost:8080` 返回的 `2300007` 被识别为“连接失败 / 建立连接”，重试、复制诊断 Toast、暗色布局与滚动容器均正常，无新增 ArkTS warning。

响应媒体操作回归（2026-09-28）：图片与视频预览的下载操作改为与 JSON 响应工具栏一致的紧凑图标按钮，并保留无障碍文本，避免同一响应区同时出现文字按钮和图标按钮两套视觉语言。

继续暂缓：并发 Runner、集合级脚本、第三方脚本包、远程模块、完整 Postman `pm.*` 兼容层，以及 WebSocket、SSE、GraphQL、gRPC、AI、Cloud、Login 等既定后续范围。

### Milestone 15 — WebSocket & SSE

Milestone 15 在现有本地请求工作区内增加实时协议调试能力，仍坚持无需账号、无需云端和本地优先。WebSocket 与 SSE 必须复用现有 Tab、环境和错误反馈语言；连接元数据进入统一历史，消息内容与流式事件默认只保留在内存中，也不得让 Collection Runner 把长连接当作普通请求执行。

分三批完成：

1. WebSocket 最小闭环：新建 WebSocket 请求、`ws://` / `wss://` 连接与断开、文本消息收发、连接状态和消息时间线
2. 工作流整合：环境变量、Headers、认证、连接历史，以及消息搜索、复制和显式导出
3. SSE：连接与停止、流式事件展示、错误诊断和实体机稳定性验收

第一批进度（2026-09-28）：WebSocket 已作为请求 Tab 的协议类型接入工作区，新建菜单可区分 HTTP 与 WebSocket；工作区支持地址输入、连接、断开、文本消息发送、接收/发送/系统消息时间线、状态与错误码、单条复制和清空消息。URL 随 schema v10 本地状态恢复，实时连接和消息不持久化；保存到集合的节点显示 `WS`，Collection Runner 会跳过 WebSocket 请求。仓库质量检查和 HAP 构建通过，实体 HarmonyOS PC 使用同一局域网内的本地 Echo Server 完成“连接 → 发送文本 → 接收同文 → 主动断开”的真实网络往返，并验证无效地址只进入错误状态而不再导致进程退出；无新增 ArkTS warning。当前批次未提前实现环境变量、Headers、认证、搜索、导出或 SSE。

第二批进度（2026-09-28）：WebSocket 工作区增加消息、标头、认证和连接记录四个页签；连接地址、自定义 Headers、Bearer / Basic / API Key 认证及文本消息均支持当前环境变量，建立连接前会阻止缺失变量并给出明确提示。连接参数会解析为原生 WebSocket 握手 URL 与 Header，API Key 可按配置进入 Header 或 Query。消息时间线支持即时检索、整批复制和显式导出文本文件；每次连接尝试会在当前 Tab 的内存会话中记录连接中、已连接、已关闭或失败状态及错误码。实时消息和连接记录仍不持久化，关闭 Tab 或重启应用即清除；请求地址、Headers 与认证配置仍随请求本地保存。仓库质量检查和 HAP 构建通过，无新增 ArkTS warning。

第三批进度（2026-09-28）：SSE 已作为独立请求协议接入新建菜单、请求 Tab、集合保存和恢复流程；工作区支持 `http://` / `https://` 地址、连接、主动停止、流状态、HTTP 状态码、Content-Type 与网络错误码。原生 HTTP 流通过 `requestInStream` 按块接收并使用增量 UTF-8 解码，SSE 解析器支持 CRLF、跨块事件、注释、默认 `message`、自定义 `event`、多行 `data`、`id` 与 `retry`。事件时间线支持搜索、单条选择复制、整批复制、清空和显式导出；地址、Headers、Bearer / Basic / API Key 认证支持当前环境变量及缺失变量校验。事件只保留在 Tab 内存会话中，不进入普通 HTTP 历史；Collection Runner 会跳过 SSE，并且集合中的 WS / SSE 请求不再显示运行菜单。仓库质量检查和 HAP 构建通过，实体 HarmonyOS PC 使用局域网 SSE Server 验证有限流“连接 → 分块接收三类事件 → 正常结束”，以及持续流“连续接收 → 主动停止 → 服务端连接重置”的完整链路，无新增 ArkTS warning。Milestone 15 三批完成。

体验完善批次（2026-09-28）：WS / SSE 请求工具栏已与普通 HTTP 请求统一字体、尺寸、垂直对齐和分段边框；WS 左侧可切换 `WS` / `WSS` 并同步改写 URL，SSE 左侧可选择 HTTP Method，原生流式请求会按所选 Method 发出。消息与事件页签沿用普通请求配置页签的字号和高度，搜索框正文及 placeholder 与右侧清空操作统一字号并修复文字裁切。集合文件夹菜单可直接新建 HTTP、WS 或 SSE 请求，新建菜单统一使用紧凑的“WS 请求”文案，文件夹菜单的三类新建动作使用同尺寸的网络、双向通信和事件流 SVG 图标。全局历史开始记录 WS 连接和 SSE 流请求，使用协议标签区分，并可从历史恢复对应请求类型；实时消息和事件正文仍只保留在当前内存会话中。窄窗口菜单的 `HTTP` / `WS` / `SSE` 标识获得固定宽度，不再发生字母换行；三类请求共用的 URL 富文本输入区根据实体机截图重新校准了文本基线和 placeholder 字体，以保持视觉垂直居中。

示例目录完善（2026-09-28）：新建菜单统一采用“新建 HTTP 请求 / 新建 WS 请求 / 新建 SSE 请求”的动作式文案。`Nimbo 示例接口` 新增“实时连接”目录，内置 WebSocket.org 官方公开回声服务 `wss://echo.websocket.org` 和 SSE 测试流 `https://echo.websocket.org/.sse`，无需密钥即可验证实时协议。另新增 `OpenAI API 示例` 与 `DeepSeek API 示例` 两个顶层集合，分别提供模型列表和文本生成请求；认证值使用 `{{OPENAI_API_KEY}}` / `{{DEEPSEEK_API_KEY}}` 环境变量占位符，不保存真实密钥。持久化 schema 升级到 v11，对已有 v10 数据执行一次非破坏性示例目录合并，保留用户原有集合与同 ID 项目。

集合作用域变量（2026-09-28）：顶层集合和任意层级文件夹的行级菜单新增“变量”编辑器，复用环境变量表格的启用、Secret、说明、批量编辑和本地持久化能力。有效变量按 `Runner 数据行 > 最近文件夹 > 上级文件夹 > 集合 > 当前环境` 合并；禁用的作用域变量不会遮蔽下层可用值。合并结果统一供 HTTP、WS、SSE、请求 URL / Params / Headers / Auth / Body 补全、前置与后置脚本、以及 Collection Runner 使用；脚本 `environment.set` 和响应提取仍只写入明确的环境，不会隐式改写集合或文件夹。无密钥导出会递归脱敏集合变量。Postman Collection 根级 `variable` 会直接导入为集合变量。OpenAI / DeepSeek 示例集合开始用集合变量保存 Base URL 与默认模型，API Key 继续只通过环境变量占位符提供。持久化 schema 升级到 v12，对已有数据补齐变量数组并非破坏性合并新增示例默认值。

继续暂缓：二进制 WebSocket 发送、自动重连、Socket.IO、GraphQL Subscription、gRPC、并发 Runner、集合级脚本、第三方脚本包、远程模块、完整 Postman `pm.*` 兼容层，以及 AI、Cloud、Login 等既定后续范围。

### Milestone 16 — 变量可观测性与诊断

Milestone 16 在 v12 集合/文件夹变量作用域之上补齐“最终值从哪里来、为什么缺失、去哪里修改”的完整工作流，避免多层覆盖后只能靠猜测排查。

第一批进度（2026-09-28）：HTTP 请求设置页新增“有效变量”区域，WS 与 SSE 工作区新增变量页签。每个最终变量显示键、脱敏后的值、来源类型、来源名称和覆盖链；Secret 始终只显示掩码。环境、集合、上级文件夹和最近文件夹使用同一解析结果，输入提示与实际执行不再维护两套优先级逻辑。

第二批进度（2026-09-28）：请求编辑阶段会扫描 URL、Params、Headers、认证、JSON / 文本正文、表单、多部分文本字段以及 WebSocket 消息，提前列出没有最终启用值的 `{{变量}}`。HTTP 错误面板、WS 错误条和 SSE 错误条均提供“配置变量”动作：已解析变量可直接跳到其环境、集合或文件夹来源，缺失变量则优先打开离请求最近的可编辑作用域，没有集合归属时进入当前环境。错误文案不再把所有作用域统称为环境变量，HTTP 校验诊断中的 Host 会使用已完成的非缺失变量替换结果。

第三批进度（2026-09-28）：Runner 数据行进入统一解析器并作为最高优先级来源，顺序固定为 `Runner 数据行 > 最近文件夹 > 上级文件夹 > 集合 > 当前环境`。Nimbo HTTP、WebSocket、SSE 示例开始使用集合变量地址，OpenAI / DeepSeek 示例继续使用集合 Base URL 与模型变量；持久化 schema 升级到 v13，对 v12 及更早数据非破坏性补齐示例变量并只迁移仍保持旧默认值的内置请求。Postman 根变量导入、无密钥递归脱敏、HTTP / WS / SSE / 脚本 / Runner 执行链继续共用最终变量数组。仓库质量检查、签名 HAP 构建和实体 HarmonyOS PC 回归通过：内置 HTTP 示例经 `{{DEMO_HTTP_BASE_URL}}` 解析后返回 `200 OK`，WebSocket 示例经 `{{DEMO_WEBSOCKET_URL}}` 进入“已连接”，SSE 示例经 `{{DEMO_SSE_URL}}` 进入“接收中”并收到真实事件；三种请求均显示同一组集合变量来源，Secret 与敏感键值保持遮罩，来源“编辑”可准确跳转到对应集合变量弹窗。未新增 ArkTS warning，仍只有 Milestone 5 已知的两条 Redirect Interceptor 兼容提示。至此 Milestone 16 三批完成。

第四批进度（2026-09-28）：新增离线应用内帮助中心，桌面侧栏底部使用与现有导航一致的书本 SVG 入口，紧凑侧栏仅显示图标；手机端不增加底部导航项，从“设置 → 关于”进入。帮助中心按任务拆分为快速开始、集合与环境、导入、请求与响应、变量、脚本、提取与测试、Collection Runner、WebSocket/SSE、快捷键和故障排查 11 个章节，提供入口路径、分步操作、代码/数据示例、执行顺序、限制、持久化语义与失败处理；中英文切换时内容同步更新，全局搜索可通过“帮助”命令打开。仓库新增完整中英文用户手册与独立变量指南，并从两份 README 提供入口；变量指南明确作用域优先级、全部可用输入面、有效变量诊断、Secret 与导出规则及常见问题，README 的已实现/暂缓能力说明同步到当前版本。实体 HarmonyOS PC 已验收紧凑侧栏、11 项目录、长内容滚动、Runner 数据约束和故障排查章节。至此 Milestone 16 的配置、观察、诊断和学习闭环完成。

帮助与流式 AI 完善（2026-09-29）：应用内“脚本”章节补充标准 JavaScript 语法、Pre-request `nimbo.request`、Post-response `nimbo.response`、环境 API、控制台、高亮与键盘补全、执行结果和精确沙箱限制，并新增中英文独立脚本指南，包含 API 表、常见范例与故障排查。SSE 请求新增 None / JSON / Text 正文编辑，POST 流式接口的正文会参与变量缺失检查与替换后交给原生流式 HTTP；OpenAI 示例集合新增 Responses API 流式文本请求，DeepSeek 示例集合新增 Chat Completions 流式请求。持久化 schema 升级到 v14，并将示例目录合并改为递归非破坏性合并，使已有安装保留自定义内容的同时补入新增请求。

实时 JSON 可读性（2026-09-29）：WebSocket 收发消息和 SSE 单条事件的 `data` 会逐条尝试解析 JSON；合法 JSON 使用与 HTTP 响应一致的 Pretty 格式、行号、浅色/深色语法色和只读选择复制，单卡高度按格式化行数自适应并限制最大值，超长内容在卡内查看。无法解析的普通文本与 `[DONE]` 等协议标记继续按原始等宽文本显示，不改变搜索、整批复制和导出所使用的原始数据。

窗口恢复布局修复（2026-09-29）：正常窗口的原生标题按钮安全区改为与固定 DecorButtonStyle 对应的稳定 132vp，不再采用全屏恢复瞬间可能带有不同密度的矩形值。桌面搜索框继续在空间充足时保持窗口水平居中；窄窗口或恢复窗口空间不足时只向左避让，并根据实测窗口宽度为环境、导入、设置和系统按钮预留空间，避免右侧操作越过或覆盖搜索框。

WebSocket 输入器优化（2026-09-29）：移除与 76vp 多行输入框高度不一致的独立文字发送按钮，改为输入框右下角内嵌纸飞机 Icon；有内容且已连接时高亮，否则置灰。Enter 与 Ctrl+Enter 直接发送，Shift+Enter 保留换行，右侧内边距防止正文进入按钮区域，键盘与鼠标操作共用原有发送链路。

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
