# Nimbo Design System & Component Spec

> **产品：** Nimbo  
> **平台：** HarmonyOS  
> **优先平台：** HarmonyOS PC  
> **设计体系：** Soft Developer Tool  
> **版本：** v0.1  
> **目标：** 将 UI 设计转换为可直接实施的 Token、组件和状态体系

---

# 1. 核心目标

解决：

1. 颜色不能散落在业务代码。
2. 页面不能各自定义圆角和间距。
3. 相同功能必须使用相同组件。
4. Light / Dark Mode 统一 Token 驱动。
5. PC / Tablet / Phone 共用设计体系。
6. Hover / Focus / Disabled / Loading 状态统一。
7. 后续 WebSocket / SSE / GraphQL 扩展不推翻现有组件。

原则：

> **页面由组件构成，组件由 Token 驱动。**

---

# 2. Token 总体结构

```text
tokens
├── color
├── typography
├── spacing
├── radius
├── size
├── border
├── shadow
├── motion
└── breakpoint
```

业务组件禁止散落硬编码视觉值。

---

# 3. Color Architecture

分三层：

```text
Primitive Color
      ↓
Semantic Color
      ↓
Component Color
```

业务页面只使用 Semantic / Component Token。

---

# 4. Brand Color

主品牌：Cloud Indigo。

建议色阶：

```text
brand.50
brand.100
brand.200
brand.300
brand.400
brand.500  ← main
brand.600
brand.700
brand.800
brand.900
```

主要用途：Primary Button、Focus Ring、Active Tab、Selected Nav、Link、Logo。

---

# 5. Semantic Color Tokens

```text
color.bg.app
color.bg.sidebar
color.bg.workspace
color.bg.surface
color.bg.surfaceHover
color.bg.surfaceActive
color.bg.editor
color.bg.overlay

color.text.primary
color.text.secondary
color.text.tertiary
color.text.disabled

color.border.default
color.border.subtle
color.border.focus
color.border.error

color.icon.primary
color.icon.secondary

color.success
color.warning
color.error
color.info
```

---

# 6. Dark Mode

Dark Mode 独立 Token，不简单反色。

参考：

```text
bg.app       #181A1F 附近
bg.sidebar   #1D1F25 附近
bg.workspace #202228 附近
bg.surface   #25272D 附近
bg.editor    #17191E 附近
```

具体值允许在真机上视觉微调，但组件禁止自行判断 Dark Mode 后写颜色。

---

# 7. HTTP Colors

```text
http.get
http.post
http.put
http.patch
http.delete
http.head
http.options

http.status.success
http.status.redirect
http.status.clientError
http.status.serverError
```

2xx / 3xx / 4xx / 5xx 按语义状态映射。

---

# 8. Typography

```text
font.family.ui
font.family.code
```

建议字号：

```text
font.size.xs   = 11
font.size.sm   = 12
font.size.md   = 13
font.size.base = 14
font.size.lg   = 16
font.size.xl   = 18
font.size.2xl  = 20
```

Weight：

```text
regular
medium
semibold
```

不要 everywhere bold。

---

# 9. Spacing

4px Base Grid：

```text
spacing.0  = 0
spacing.1  = 4
spacing.2  = 8
spacing.3  = 12
spacing.4  = 16
spacing.5  = 20
spacing.6  = 24
spacing.8  = 32
spacing.10 = 40
```

避免随机 13 / 17 / 19 / 27。

---

# 10. Radius

```text
radius.none = 0
radius.sm   = 6
radius.md   = 8
radius.lg   = 12
radius.xl   = 16
radius.full = 999
```

建议：

- Button / Input：md
- Dropdown / Context Menu：lg
- Dialog：xl
- Badge：sm / full

---

# 11. Border / Shadow / Motion

Border：

```text
border.width.default = 1
border.width.active  = 2
```

Shadow：

```text
shadow.none
shadow.popup
shadow.dialog
```

普通 Input/Table/Editor/Sidebar 不用阴影。

Motion：

```text
motion.fast   = 120ms
motion.normal = 180ms
motion.slow   = 240ms
```

---

# 12. Breakpoints

```text
breakpoint.desktopLarge >= 1440
breakpoint.desktop      >= 1280
breakpoint.compact      >= 1024
breakpoint.tablet       >= 720
breakpoint.phone         < 720
```

当前开发重点：Desktop Large / Desktop / Compact。

---

# 13. Size Tokens

```text
control.height.sm = 28
control.height.md = 32
control.height.lg = 40
control.height.xl = 44

icon.sm = 14
icon.md = 16
icon.lg = 20
icon.xl = 24
```

桌面布局参考：

```text
sidebar.primary.width   = 176
sidebar.secondary.width = 260
toolbar.global.height   = 52
tabbar.height           = 38
```

---

# 14. 顶层组件树

```text
NimboApp
└── NimboWindow
    ├── GlobalToolbar
    └── MainLayout
        ├── PrimarySidebar
        ├── SecondarySidebar
        └── Workspace
```

`NimboWindow` 负责 Theme、Window Size、Breakpoint、Global Dialog/Toast、Shortcut，不负责 HTTP 业务。

---

# 15. GlobalToolbar

```text
GlobalToolbar
├── Brand
├── GlobalSearch
├── EnvironmentSwitcher
├── SettingsButton
└── WindowControls
```

### GlobalSearch Props

```text
placeholder
value
shortcutHint
onOpen
```

状态：default / hover / focus / disabled。

### EnvironmentSwitcher Props

```text
currentEnvironment
environments
onSelect
onManage
```

状态：normal / production / empty。

---

# 16. PrimarySidebar

```text
PrimarySidebar
├── Brand
├── NewRequestButton
├── NavigationList
└── BottomNavigation
```

Navigation：

- Workspace
- Collections
- Environments
- History
- Settings

### NavItem Props

```text
icon
label
active
badge
disabled
onClick
```

---

# 17. NewRequestButton

Split Button：

```text
+ New | ▼
```

首版：

- HTTP Request
- Import cURL
- Import Collection

---

# 18. Collection Components

```text
CollectionSidebar
├── CollectionHeader
├── CollectionSearch
└── CollectionTree
```

节点类型：

```text
Collection
Folder
Request
```

基础 Node Model：

```text
id
type
name
parentId
children
expanded
```

Request 追加：

```text
method
dirty?
```

节点支持：click / doubleClick / rightClick / drag / drop / hover / keyboardSelect。

---

# 19. Collection Drag State

```text
idle
dragging
dragOver
forbidden
```

禁止 Folder → 自己的子树。

---

# 20. Workspace

```text
Workspace
├── RequestTabBar
└── RequestWorkspace
```

无 Tab 时显示 `WorkspaceEmptyState`。

---

# 21. RequestTabBar

Props：

```text
tabs
activeTabId
onSelect
onClose
onCreate
onContextMenu
```

支持 overflow / scroll / keyboard navigation。

### RequestTab Model

```text
id
name
method
dirty
pinned
loading
```

状态：default / hover / active / dirty / loading / pinned。

---

# 22. RequestWorkspace

```text
RequestWorkspace
├── RequestPanel
├── NimboSplitter
└── ResponsePanel
```

---

# 23. RequestPanel

```text
RequestPanel
├── RequestToolbar
├── RequestConfigTabs
└── RequestEditorArea
```

---

# 24. RequestToolbar

```text
RequestToolbar
├── MethodSelector
├── UrlInput
└── SendButton
```

### MethodSelector Props

```text
value
methods
onChange
allowCustom
```

### UrlInput Props

```text
value
variables
errors
onChange
onSubmit
```

UrlInput 要预留 RichText / 自定义高亮能力，避免未来变量语法被普通 TextInput 限制。

### SendButton Props

```text
state
onSend
onCancel
```

`state = idle | sending`。

---

# 25. RequestConfigTabs

数据：

```text
Params
Headers
Auth
Body
Settings
```

Props：

```text
activeTab
badges
indicators
onChange
```

建议抽象 `NimboTabs`：

```text
variant = underline | segment
```

---

# 26. KeyValueEditor

Params / Headers / Form / Environment 共用。

```text
KeyValueEditor
├── KeyValueToolbar
├── KeyValueHeader
└── KeyValueRow[]
```

Props：

```text
items
mode
showDescription
showType
allowFile
onChange
```

Mode：

```text
params
headers
form
multipart
environment
```

统一 Item：

```text
id
enabled
key
value
description
type
secret
```

Multipart `type = text | file`。

支持：Checkbox、文本编辑、变量自动补全、Keyboard Navigation、Row Menu、Bulk Mode。

---

# 27. AuthEditor

```text
AuthEditor
├── AuthTypeSelector
└── AuthConfigPanel
```

Type：none / bearer / basic / apiKey。

---

# 28. SecretInput

通用：

```text
SecretInput
```

Props：

```text
value
revealed
onChange
onToggleReveal
```

窗口失焦强制 `revealed = false`。

---

# 29. BodyEditor

```text
BodyEditor
├── BodyTypeSelector
└── BodyContent
```

Type：none / json / text / form / multipart / binary。

---

# 30. JsonEditor

核心组件，接口先稳定，能力可分阶段实现。

Props：

```text
value
readOnly
language
wrap
showLineNumbers
validation
onChange
onFormat
```

状态：normal / focus / error / readonly / largeFile。

工具：Format / Minify / Wrap / Copy / Search。

---

# 31. Splitter

```text
NimboSplitter
```

Props：

```text
direction
ratio
min
max
onResize
```

PC 默认上下分割，初始 Request 48% / Response 52%。

持久化：

```text
workspace.splitRatio
```

---

# 32. ResponsePanel

```text
ResponsePanel
├── ResponseHeader
└── ResponseContent
```

ResponseState：

```text
empty
sending
success
error
large
binary
cancelled
```

不要使用多个 Boolean 组合状态。

---

# 33. ResponseHeader / Summary

左：Body / Headers / Cookies / Timeline。

右：Status / Duration / Size / Protocol / Actions。

ResponseSummary Props：

```text
statusCode
statusText
duration
size
protocol
```

---

# 34. Response Body Viewers

根据 Content Type：

```text
JsonViewer
TextViewer
HtmlPreview
ImagePreview
BinaryViewer
LargeResponseViewer
```

`JsonViewer` 可以与 JsonEditor 共享核心，但 `readOnly = true`，额外支持 Collapse / Expand / Copy Path / Copy Value。

---

# 35. ErrorPanel

统一错误组件：

```text
ErrorPanel
```

Props：

```text
title
message
code
details
actions
```

Error Types：

```text
dns
connectionRefused
timeout
tls
connectionReset
invalidUrl
proxy
cancelled
unknown
```

UI 显示友好文案，底层错误放 Details。

---

# 36. LargeResponseViewer

Props：

```text
size
contentType
previewAvailable
```

Actions：Preview first N MB / Save to File。

---

# 37. Common Components

建议统一：

```text
NimboButton
NimboIconButton
NimboInput
NimboTabs
NimboDropdown
NimboContextMenu
NimboDialog
NimboToast
NimboTooltip
NimboCheckbox
NimboSwitch
NimboBadge
NimboEmptyState
NimboSplitter
```

---

# 38. Button System

`NimboButton`：

```text
variant = primary | secondary | ghost | danger
size    = sm | md | lg
```

一个区域只保留一个主要 Primary Action。

`NimboIconButton` 必须有 Tooltip，点击区域桌面 >= 28×28。

---

# 39. Input System

`NimboInput` 状态：

```text
default
hover
focus
error
disabled
readonly
```

Props：

```text
label?
placeholder?
helperText?
error?
prefix?
suffix?
```

---

# 40. Checkbox / Switch

Checkbox：Params / Headers Enable。

Switch：Settings，如 Follow Redirect / SSL Verification / Cookie Jar。

不要混用。

---

# 41. Toast / Dialog / Menu

Toast：Copied / Saved / Imported / Delete + Undo。

Dialog：Delete Collection / Clear History / Reset App / Export Secret。

ContextMenu Item：

```text
icon?
label
shortcut?
danger?
disabled?
separator?
```

---

# 42. EmptyState

统一 Props：

```text
icon?
title
description
primaryAction?
secondaryAction?
```

默认不使用大插画。

---

# 43. Environment Page

```text
EnvironmentPage
├── EnvironmentSidebar
└── EnvironmentEditor
```

EnvironmentEditor 复用 KeyValueEditor，`mode = environment`。

字段：Variable / Value / Secret / Description。

---

# 44. History Page

```text
HistoryPage
├── HistorySidebar
└── HistoryList
```

HistoryRow：

```text
time
method
url
status
duration
```

支持 open / copy URL / copy cURL / delete。

---

# 45. Import Components

### ImportCurlDialog

状态：idle / valid / invalid / importing。

解析失败保持 Dialog 打开。

### PostmanImportFlow

```text
File Selection
Analyze
Preview
Import Result
```

Result：success / partial / failed。

---

# 46. Settings

```text
SettingsPage
├── SettingsSidebar
└── SettingsContent
```

Section：General / Appearance / Network / Data / Privacy / About。

统一 `SettingRow`：title / description / control。

---

# 47. Responsive

## Desktop Large

Primary + Secondary + Workspace 全部显示。

## Desktop 1280

Secondary 260 → 220，Workspace 优先。

## Compact 1024

Primary 176 → 60 Icon Rail，Secondary 220。

更窄时自动隐藏 Secondary，并提供 Toggle。

Request Toolbar 最少保证：

```text
Method 80
URL >= 360
Send 100
```

---

# 48. Focus / Keyboard

Focus Ring 统一 2px Brand。

Collection Tree 后续支持：

```text
↑ ↓
← collapse
→ expand
Enter open
F2 rename
Delete remove
```

快捷键统一由 `ShortcutManager` 管理，不在每个页面重复监听。

---

# 49. Theme Architecture

所有组件引用：

```text
theme.color.bg.workspace
```

不要在组件内部散落：

```text
if darkMode { ... }
```

---

# 50. State Model

建议拆分：

```text
RequestDraftState
ResponseState
TabState
```

避免巨型 Page State。

### RequestDraftState

```text
id
name
method
url
params
headers
auth
body
settings
dirty
savedId?
```

### ResponseState / Model

```text
status
startedAt?
finishedAt?
statusCode?
statusText?
headers
cookies
body
contentType
size
duration
protocol
error?
timing?
```

---

# 51. Boolean Explosion Rule

若组件出现：

```text
isLoading
isSuccess
isError
isEmpty
isCancelled
```

改成 enum / union State。

---

# 52. 命名规范

Common：

```text
NimboButton
NimboInput
NimboDialog
```

Domain：

```text
RequestToolbar
ResponsePanel
CollectionTree
```

不要混用 MyButton / CommonBtn / BaseButton / CustomButton。

---

# 53. 推荐目录

```text
ui/
├── tokens/
├── theme/
├── components/
│   ├── common/
│   ├── request/
│   ├── response/
│   ├── collection/
│   ├── environment/
│   └── history/
└── pages/
```

Common：

```text
NimboButton
NimboIconButton
NimboInput
NimboTabs
NimboDropdown
NimboMenu
NimboDialog
NimboToast
NimboTooltip
NimboCheckbox
NimboSwitch
NimboBadge
NimboEmptyState
NimboSplitter
```

Request：

```text
RequestTabBar
RequestTab
RequestToolbar
MethodSelector
UrlInput
SendButton
RequestConfigTabs
KeyValueEditor
AuthEditor
BodyEditor
JsonEditor
MultipartEditor
RequestSettings
```

Response：

```text
ResponsePanel
ResponseHeader
ResponseSummary
ResponseTabs
JsonViewer
RawViewer
HtmlPreview
BinaryViewer
LargeResponseViewer
ErrorPanel
TimingViewer
```

---

# 54. Page 层职责

Page 只负责：

```text
组合组件
+
绑定状态
```

禁止 Page 自己发明 Button、ContextMenu、Error UI、颜色、复杂 JSON 渲染。

---

# 55. UI 与 HTTP Engine 边界

禁止：

```text
UI → HTTP Library
```

应该：

```text
Request UI
   ↓
RequestController / Service
   ↓
HTTP Engine
   ↓
ResponseModel
   ↓
UI
```

---

# 56. Mock First

UI 第一阶段必须支持：

- Mock Request
- Mock Response
- Mock Error
- Mock Large Response
- Mock Binary Response

建议：

```text
mock/success
mock/error-connection-refused
mock/error-timeout
mock/large
mock/binary
```

---

# 57. UI 开发阶段

## Stage 1 — Shell

```text
NimboWindow
GlobalToolbar
PrimarySidebar
CollectionSidebar
Workspace
RequestTabBar
```

## Stage 2 — Request

```text
RequestToolbar
Params
Headers
Auth
Body
```

## Stage 3 — Response

```text
Success
Error
Empty
Large
Binary
```

## Stage 4 — Supporting

```text
Collection
Environment
History
Import
Settings
```

## Stage 5 — HTTP

UI Gate 之后才接真实网络。

---

# 58. HTTP 接入顺序

第一条链：GET。

第二阶段：

- POST
- PUT
- PATCH
- DELETE
- Params
- Headers
- JSON Body

第三阶段：

- Form
- Multipart
- Binary
- Auth
- Redirect
- Timeout
- Cookie

---

# 59. Accessibility

必须考虑：

- 键盘
- Focus
- Contrast
- Screen Reader Label
- Tooltip
- Icon 不单独传达关键语义

错误不能只有颜色，还要有 Icon + Text。

点击目标：

```text
Desktop >= 28×28
Touch   >= 40×40
```

---

# 60. Text Overflow

Request Name：ellipsis + Tooltip。

编辑状态 URL 不省略，只读列表可省略。

---

# 61. Data Density

默认 Comfortable。

未来可扩展 Compact，但 1.0 不开放设置。

组件设计时保留可能性。

---

# 62. 1.0 必需组件

至少实现：

```text
NimboButton
NimboIconButton
NimboInput
NimboTabs
NimboDropdown
NimboDialog
NimboToast
NimboTooltip
NimboCheckbox
NimboSwitch
NimboBadge
NimboSplitter

PrimarySidebar
CollectionSidebar
CollectionTree

RequestTabBar
RequestToolbar
MethodSelector
UrlInput
SendButton
RequestConfigTabs
KeyValueEditor
AuthEditor
BodyEditor
JsonEditor

ResponsePanel
ResponseHeader
ResponseSummary
JsonViewer
RawViewer
ErrorPanel
ResponseEmptyState
```

---

# 63. 不提前抽象

暂不设计：

- Plugin System
- GraphQL 通用框架
- gRPC 通用框架
- WebSocket Message Framework
- SSE Viewer
- AI Components
- Cloud Components
- Team Components

真正开发时再抽象。

---

# 64. ArkUI 首屏组件树

```text
NimboWindow
│
├── GlobalToolbar
│   ├── Brand
│   ├── GlobalSearch
│   ├── EnvironmentSwitcher
│   └── SettingsButton
│
└── MainLayout
    │
    ├── PrimarySidebar
    │   ├── NewRequestButton
    │   └── NavigationList
    │
    ├── CollectionSidebar
    │   ├── CollectionHeader
    │   ├── CollectionSearch
    │   └── CollectionTree
    │
    └── Workspace
        │
        ├── RequestTabBar
        │
        └── RequestWorkspace
            │
            ├── RequestPanel
            │   ├── RequestToolbar
            │   │   ├── MethodSelector
            │   │   ├── UrlInput
            │   │   └── SendButton
            │   ├── RequestConfigTabs
            │   └── RequestEditor
            │       └── KeyValueEditor
            │
            ├── NimboSplitter
            │
            └── ResponsePanel
                ├── ResponseHeader
                │   ├── ResponseTabs
                │   └── ResponseSummary
                └── JsonViewer
```

---

# 65. 首屏 Mock

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

---

# 66. UI Skeleton Done

达到：

- Light Mode 主界面完整
- Sidebar 可切换
- Collection Tree 可展开
- Request Tab 可新增/关闭/切换
- Params / Headers / Auth / Body 可切换
- URL 可编辑
- Send Idle / Sending
- Splitter 可拖动
- Mock JSON Response
- Mock Error State
- Environment Switcher
- 1024px 不崩布局

---

# 67. HTTP Engine Gate

真实网络接入前必须保证：

```text
GET UI
POST UI
Params UI
Headers UI
Auth UI
Body UI
Response UI
Error UI
```

全部由 Mock State 驱动。

目标：

> **切换 Mock State 就能模拟完整 Nimbo。**

---

# 68. Design System 最终原则

1. 优先复用，不新建类似组件。
2. 优先 Token，不硬编码。
3. 优先信息密度，不 Card 化。
4. 优先桌面效率，不手机思维。
5. 优先局部反馈，不全屏 Loading。
6. 优先键鼠，同时兼容触控。
7. Response 是视觉核心。

最终结构：

```text
Design Tokens
      ↓
Common Components
      ↓
Domain Components
      ↓
Pages
      ↓
Nimbo
```
