# Nimbo 全量规格汇总

> 本文件由 PRD、UI/UX Spec、Design System 自动汇总。若与单独文档发生冲突，以 README 中的优先级为准。

---

# Nimbo 产品需求文档 PRD

> **产品名称：** Nimbo  
> **产品定位：** HarmonyOS 原生 API 调试工具  
> **产品形态：** HarmonyOS PC 优先，兼容平板与手机  
> **商业模式：** 永久免费  
> **核心理念：** Local First / No Login / Fast / Native  
> **版本：** v0.1

---

# 1. 产品概述

Nimbo 是一款专门面向 HarmonyOS 开发者的原生 API 调试工具。

主要用于开发、调试和验证：

- HTTP / HTTPS API
- REST API
- WebSocket（P1）
- SSE（P1）
- GraphQL（P1/P2）
- gRPC（P2）

Nimbo 不追求第一阶段复制 Postman 的全部能力，而是优先解决开发者最高频的 API 调试需求：

> 打开应用 → 粘贴 URL / cURL → Send → 看结果。

同时提供 Collection、Environment、History 等项目管理能力，使其成为开发者日常长期使用的工具，而不是 HTTP 请求 Demo。

---

# 2. 产品定位

## 2.1 一句话定位

> **Nimbo — HarmonyOS 原生 API 调试工具。**

## 2.2 核心差异化

Nimbo 不与 Postman 在跨平台、团队协作、云服务层面竞争。

| 能力 | Nimbo |
|---|---|
| HarmonyOS 原生 | ✅ |
| HarmonyOS PC 优化 | ✅ |
| 无需登录 | ✅ |
| 完全本地 | ✅ |
| 永久免费 | ✅ |
| 无广告 | ✅ |
| REST API | ✅ |
| cURL 导入 | ✅ |
| Postman Collection 导入 | ✅ |
| WebSocket | P1 |
| SSE | P1 |
| GraphQL | P1/P2 |
| gRPC | P2 |
| 云同步 | ❌ |
| 团队协作 | 暂不考虑 |

用户核心感知：

> **比 Postman 更轻。**  
> **比网页 API 工具更原生。**  
> **在鸿蒙设备上开箱即用。**

---

# 3. 产品目标

## 3.1 覆盖日常 HTTP API 调试

```text
创建请求
    ↓
填写 URL
    ↓
设置 Params / Headers / Auth / Body
    ↓
发送请求
    ↓
查看 Response
```

## 3.2 打开就能用

用户安装后：

- 不需要注册账号
- 不需要登录
- 不需要配置 Workspace
- 不需要创建项目
- 不需要连接云服务

进入首页即可发送请求。

## 3.3 降低迁移成本

支持：

- 粘贴 cURL
- Postman Collection 导入
- Postman Environment 导入

## 3.4 成为鸿蒙开发者常驻工具

目标工作流：

```text
DevEco Studio
+
Terminal
+
Nimbo
```

---

# 4. 非目标

第一阶段不做：

- 团队协作
- 云 Workspace
- 在线账号体系
- 在线 Collection 分享
- SaaS
- AI API 生成
- Mock Server
- API Documentation Hosting
- 企业权限管理
- CI/CD
- 团队审批
- 在线同步
- API Marketplace
- 完整脚本系统
- 插件系统

这些能力会显著增加复杂度，但不是个人开发者日常 API Client 的核心需求。

---

# 5. 目标用户

## 5.1 后端开发者

- 调试 REST API
- 测试 Authorization
- 调整 JSON 参数
- 测试不同环境
- 查看 Response
- 后续 WebSocket / SSE / gRPC 调试

这是 Nimbo 核心用户。

## 5.2 HarmonyOS 开发者

用于确认：

- API 是否正常
- Token 是否正确
- Header 是否正确
- JSON 是否符合预期
- 是客户端问题还是服务端问题

## 5.3 前端开发者

- 联调 API
- 测试 Mock API
- 查看 JSON
- 调整 Query
- 获取请求示例

## 5.4 QA / 测试人员

- 保存接口
- 修改参数
- 切换环境
- 重复执行
- 验证状态码
- 对比 Response

## 5.5 学习者

用于学习 HTTP、REST、JSON、WebSocket 与 API。

---

# 6. 产品设计原则

## 6.1 Local First

默认只存在本地：

- Collection
- Request
- Environment
- Token
- History
- Cookie

默认不上传服务器。

## 6.2 No Login

```text
下载安装
↓
打开
↓
Send Request
```

## 6.3 Fast

不应该出现：

```text
Loading Workspace...
Synchronizing...
Connecting...
```

## 6.4 Native

遵循 HarmonyOS 原生体验，重点适配：

- HarmonyOS PC
- 大屏
- 键鼠
- 多窗口
- 平板

手机是辅助场景。

## 6.5 Developer Friendly

减少操作步骤。例如 Paste cURL 应该直接识别，而不是多级导入向导。

---

# 7. 信息架构

PC 主界面采用双 Sidebar + Workspace：

```text
┌──────────────────────────────────────────────────────────────┐
│ Global Toolbar                                               │
├──────────┬──────────────┬────────────────────────────────────┤
│ Primary  │ Collections  │ Request Tabs                       │
│ Sidebar  │ Sidebar      ├────────────────────────────────────┤
│          │              │ Request                            │
│          │              ├────────────────────────────────────┤
│          │              │ Response                           │
└──────────┴──────────────┴────────────────────────────────────┘
```

---

# 8. 首页 / 空状态

首次启动提供：

- New Request
- Import cURL
- Import Collection
- Recent Requests

不显示复杂 Dashboard、营销 Banner、登录引导、会员卡片。

---

# 9. Request Tab

支持：

- 创建
- 关闭
- 固定
- Duplicate
- 左右切换
- 未保存状态
- Overflow
- 右键菜单

未保存显示：

```text
POST Login ●
```

---

# 10. HTTP Method

首版支持：

- GET
- POST
- PUT
- PATCH
- DELETE
- HEAD
- OPTIONS

允许 Custom Method，例如 `PROPFIND`。

---

# 11. URL 输入

形式：

```text
GET | https://api.example.com/users/{{user_id}} | Send
```

支持变量：

```text
{{base_url}}/users/{{user_id}}
```

URL Query 与 Params 双向同步。

---

# 12. Send / Cancel

点击 Send 发送请求，PC 快捷键：

```text
Ctrl + Enter
```

发送期间按钮切换为 Cancel。

发送中不锁死整个页面，用户可以查看旧 Response 或切换其他 Tab。

---

# 13. Params

Key / Value 表格：

| Enable | Key | Value | Description |
|---|---|---|---|
| ☑ | page | 1 | Page index |
| ☑ | limit | 20 | Page size |
| ☐ | debug | true | Debug |

支持：

- Enable / Disable
- Add Row
- Delete
- Duplicate
- Bulk Edit
- Keyboard Navigation

---

# 14. Headers

字段与 Params 共享 KeyValueEditor。

常用 Header 自动补全：

- Authorization
- Content-Type
- Accept
- User-Agent
- Cookie
- Cache-Control
- Origin
- Referer

---

# 15. Authorization

首版支持：

## No Auth

不添加认证。

## Bearer Token

自动生成：

```http
Authorization: Bearer {{access_token}}
```

## Basic Auth

- Username
- Password

## API Key

- Key
- Value
- Add To: Header / Query

---

# 16. Body

支持：

## None

无 Body。

## JSON

要求：

- Syntax Highlight
- 自动缩进
- Format
- Minify
- JSON 校验
- 行号
- 错误位置

## Text

纯文本。

## x-www-form-urlencoded

Key / Value 表格。

## multipart/form-data

支持 Text 与 File。

## Binary

选择本地文件作为 Body。

---

# 17. Request Settings

单 Request 配置：

- Timeout，默认 30 秒
- Follow Redirect，默认开启
- SSL Verification，默认开启
- Cookie Jar 开关

关闭 SSL Verification 时必须明确提示风险。

---

# 18. Response Viewer

顶部固定展示：

```text
200 OK · 182 ms · 12.4 KB · HTTP/2
```

支持：

- Body
- Headers
- Cookies
- Timeline（P1）

---

# 19. Response Body

模式：

- Pretty
- Raw
- Preview

Pretty 根据 Content-Type 自动处理 JSON / XML / HTML。

JSON 支持：

- Syntax Highlight
- Collapse / Expand
- Copy
- Search
- Copy Value
- Copy JSON Path

---

# 20. Response Headers

支持：

- Copy Value
- Copy Header
- Copy All

---

# 21. Response Cookies

展示：

- Name
- Value
- Domain
- Path
- Expires
- Secure
- HttpOnly
- SameSite

---

# 22. 大 Response

避免几十 MB Response 卡死 UI。

建议：

```text
< 10 MB → 正常渲染
> 10 MB → Large Response 模式
```

提供：

- Preview first N MB
- Save to File

---

# 23. Binary Response

针对：

- image/*
- video/*
- application/octet-stream
- application/zip

图片可以 Preview，其他提供 Save Response。

---

# 24. Collection

结构示例：

```text
Vozo API
├── Auth
│   ├── Login
│   └── Refresh Token
├── User
│   ├── Get User
│   └── Update User
└── Project
    ├── Create Project
    └── Delete Project
```

支持：

- Create
- Rename
- Delete
- Duplicate
- Export
- Drag & Drop

---

# 25. Folder

支持嵌套 Folder。

首版可限制最多 10 层，防止极端情况。

---

# 26. Save Request

保存内容：

- Method
- URL
- Params
- Headers
- Auth
- Body
- Settings

已保存到 Collection 的 Request 建议自动保存修改；Untitled Request 不自动创建 Collection 项。

---

# 27. Collection 搜索

搜索：

- Request Name
- URL
- Folder
- Collection

---

# 28. History

每次发送自动记录：

- Time
- Method
- URL
- Status
- Duration

点击可重新打开请求。

默认保留 30 天，可设置：

- 7 days
- 30 days
- 90 days
- Forever
- Disabled

---

# 29. Environment

支持：

- Development
- Staging
- Production

变量示例：

```text
base_url = https://api.example.com
token = abc
```

请求中：

```text
{{base_url}}/users
```

---

# 30. Variable 类型

## Normal

普通变量。

## Secret

如：

- token
- password
- api_key

UI 默认掩码，临时查看后窗口失焦自动隐藏。

---

# 31. Variable 使用位置

以下均支持 `{{variable}}`：

- URL
- Params
- Headers
- Authorization
- JSON Body
- Form
- WebSocket URL（P1）
- GraphQL Variables（P1/P2）

---

# 32. Variable 优先级

```text
Request Variable
       ↓
Environment Variable
       ↓
Global Variable
```

高优先级覆盖低优先级。

---

# 33. Undefined Variable

Send 前提示：

```text
Variable "token" is not defined.
```

允许：

- Cancel
- Send Anyway

---

# 34. cURL Import

P0 核心功能。

自动解析：

- Method
- URL
- Query
- Headers
- Body

支持 Clipboard Detection：若焦点不在编辑器/URL Input，且剪贴板以 `curl` 开头，可提示 Import Request。

不要未经确认直接覆盖当前 Request。

---

# 35. cURL Export

支持：

```text
Copy as cURL
```

生成可执行命令。

---

# 36. Postman Import

首版支持：

- Postman Collection v2
- Postman Collection v2.1
- Postman Environment JSON

导入：

- Collection
- Folder
- Request
- URL
- Params
- Headers
- Body
- Auth

不能支持的高级能力必须显式列出，例如：

- Scripts
- Tests
- Unsupported Auth

不能静默丢失。

---

# 37. Nimbo Export

建议格式：

```text
*.nimbo.json
```

用于：

- 备份
- 分享
- Git 管理
- 设备迁移

Secret 默认不导出真实值。

---

# 38. WebSocket（P1）

创建：

```text
New → WebSocket
```

状态：

- Disconnected
- Connecting
- Connected
- Reconnecting
- Error

消息支持：

- Text
- JSON
- Binary

消息列表清晰区分 Sent / Received。

---

# 39. SSE（P1）

支持：

- URL
- Headers
- Authorization
- Query
- Environment

实时展示：

- event
- id
- data
- retry

---

# 40. GraphQL（P1/P2）

独立模式：

- Query
- Variables
- Headers

后续支持 Schema / Auto Complete。

---

# 41. gRPC（P2）

目标：

- .proto import
- Unary
- Server Streaming
- Client Streaming
- Bidirectional Streaming
- Metadata
- TLS

不进入 MVP。

---

# 42. Code Generation（P1）

至少：

- cURL
- JavaScript Fetch
- Go net/http
- Python requests

后续：Axios / Java / Kotlin / Swift / Dart。

---

# 43. 快捷键

| 快捷键 | 功能 |
|---|---|
| Ctrl + Enter | Send |
| Ctrl + N | New Request |
| Ctrl + S | Save |
| Ctrl + W | Close Tab |
| Ctrl + L | Focus URL |
| Ctrl + K | Quick Search |
| Ctrl + Shift + P | Command Palette |
| Ctrl + F | Search Response |

---

# 44. Command Palette（P1）

例如：

- New HTTP Request
- Import cURL
- Switch Environment
- Format JSON
- Clear Response

---

# 45. JSON Viewer

必须重点打磨：

- Syntax Highlight
- Tree / Collapse / Expand
- Search
- Copy
- Copy Value
- Copy JSON Path
- Format
- Raw

---

# 46. Cookie Jar（P1）

按 Domain / Path 自动携带 Cookie。

用户可关闭 `Use Cookie Jar`。

---

# 47. Proxy（P1）

支持：

- No Proxy
- HTTP
- SOCKS5

方便配合 Clash / Charles / Fiddler / mitmproxy。

---

# 48. TLS / Certificate（P1/P2）

支持：

- CA Certificate
- Client Certificate
- Client Private Key

用于企业内部 API 和 mTLS。

---

# 49. 错误展示

不能只显示 `Request Failed`。

需要明确区分：

- DNS resolution failed
- Connection refused
- Connection timeout
- TLS handshake failed
- Certificate expired
- Connection reset
- Invalid URL
- Proxy Error

底层错误放 `Show Details`。

---

# 50. Timing（P1）

目标：

- DNS
- Connect
- TLS
- TTFB
- Download
- Total

用于定位 API 慢在哪里。

---

# 51. 多窗口（后续）

PC 可支持 `Open Request in New Window`，但不阻塞 1.0。

---

# 52. PC / Tablet / Phone

## PC

主战场：

- Sidebar
- Tabs
- Split View
- Keyboard Shortcuts
- Right Click
- Drag & Drop

## Tablet

横屏采用 Sidebar + Content。

## Phone

不复刻 PC 三栏，Request / Response 页面化，Collection 使用 Drawer / 独立页面。

---

# 53. Settings

## General

- Language
- Theme
- Default Timeout
- History Retention

## Appearance

- System
- Light
- Dark

## Network

- Proxy
- SSL Verification
- Redirect

## Data

- Export All Data
- Import Data
- Clear History
- Reset App

## Privacy

明确：

> Nimbo does not upload your API requests or credentials.

---

# 54. 数据安全

Token、Password、API Key 等敏感字段尽量进入系统安全存储。

普通 Collection 使用本地数据库/文件。

Debug Log 不得无意记录：

- Authorization
- Cookie
- Password
- Secret Variable

---

# 55. Analytics

首版可以完全不做业务 Analytics。

如未来采集：

- 不采集 Request URL
- 不采集 Request Body
- 不采集 Response
- 不采集 Header
- 不采集 Token

---

# 56. Nimbo 1.0 必须完成

## Request

- HTTP / HTTPS
- GET / POST / PUT / PATCH / DELETE / HEAD / OPTIONS

## Request Editor

- URL
- Params
- Headers
- Auth
- Body
- Settings

## Body

- JSON
- Text
- Form URL Encoded
- Multipart
- Binary

## Response

- Status
- Duration
- Size
- Headers
- Pretty JSON
- Raw
- Search
- Copy
- Save Binary

## Management

- Tabs
- Collection
- Folder
- History
- Environment
- Variables
- Secret Variables

## Import / Export

- cURL Import
- cURL Export
- Postman Collection Import
- Postman Environment Import
- Nimbo Export

## App

- Light Mode
- Dark Mode
- HarmonyOS PC 适配
- Tablet 适配基础
- Phone 基础适配
- Local First
- No Login

---

# 57. Nimbo 1.1

重点：

- WebSocket
- SSE
- Cookie Jar
- Response Timing
- Proxy
- Code Generation
- Quick Search

---

# 58. Nimbo 1.2

重点：

- GraphQL
- Schema
- Auto Complete

---

# 59. Nimbo 2.0

重点：

- gRPC
- Unary
- Server Streaming
- Client Streaming
- Bidirectional Streaming

---

# 60. 后续候选

- OpenAPI Import
- Collection Runner
- Assertions
- Pre-request Script
- Test Script
- Mock
- Git Integration
- Request Diff
- Response Diff
- Performance Test
- DNS Tools
- TCP Tools
- Certificate Viewer
- HAR Import / Export

这些不阻塞 Nimbo 1.0。

---

# 61. 首次使用流程

```text
下载安装 Nimbo
      ↓
打开
      ↓
自动出现 Empty Request
      ↓
输入 URL
      ↓
Ctrl + Enter
      ↓
看到 Response
```

整个过程不出现必须配置项。

---

# 62. Postman 迁移流程

```text
打开 Nimbo
     ↓
Import
     ↓
Postman Collection
     ↓
选择 JSON
     ↓
导入预览
     ↓
Import
     ↓
Send
```

导入失败必须可解释。

---

# 63. 品牌语气

应该：

- 简单
- 安静
- 专业
- 快速
- 本地
- 可信

避免：

- 企业 SaaS 感
- 强制登录
- Banner
- 积分
- 会员
- 广告

---

# 64. 建议 Slogan

> **Nimbo — API testing, made native.**

或：

> **Nimbo — A lightweight API client for HarmonyOS.**

中文：

> **鸿蒙原生 API 调试工具**

---

# 65. 成功指标

## 使用指标

- 安装量
- DAU
- 7 日留存
- 30 日留存
- 单用户每日 Request 数
- Collection 创建率
- Environment 使用率
- cURL Import 使用率

## 产品质量

- Crash Free Rate
- 请求成功率
- 平均启动时间
- 大型 JSON 渲染稳定性
- Postman Import 成功率

核心判断：

> 安装 Nimbo 的开发者，一周以后还会不会继续打开。

---

# 66. P0 开发顺序

```text
1. HTTP Engine（在 UI Gate 后）
2. Request Editor
3. Response Viewer
4. Tab
5. History
6. Collection
7. Environment
8. Variables
9. cURL Import / Export
10. Postman Import
11. Multipart / File
12. Settings
13. PC UI 打磨
14. Tablet / Phone 适配
```

工程实施时请遵循 `CODEX_HANDOFF.md`：**先 Mock UI，再真实 HTTP**。

---

# 67. Nimbo 最重要的五个功能

如果必须继续砍范围，只保留：

1. HTTP Request
2. Response Viewer
3. Collection
4. Environment
5. cURL / Postman Import

它们决定 Nimbo 是玩具还是日常开发工具。

---

# 68. 产品护城河

```text
HarmonyOS 原生体验
        +
极低启动和操作成本
        +
完全本地
        +
优秀 JSON Viewer
        +
强大的导入兼容
        +
WebSocket / SSE / gRPC
        +
长期永久免费
```

最终用户认知：

> **鸿蒙调 API，用 Nimbo。**

---

# 69. 长期产品形态

```text
                    Nimbo
                      │
      ┌───────────────┼───────────────┐
      │               │               │
     HTTP         WebSocket          SSE
      │               │               │
   GraphQL           gRPC          Streaming
      │
Collections
      │
Environment
      │
Local Workspace
```

从 API Client 逐步升级为：

> **HarmonyOS Developer Network Toolkit**

但核心原则始终不变：

```text
Free
Local
Fast
Native
No Login
```

---

# Nimbo UI/UX Design Spec

> **产品：** Nimbo  
> **平台：** HarmonyOS  
> **优先级：** HarmonyOS PC > Tablet > Phone  
> **设计方向：** Soft Developer Tool  
> **关键词：** Native / Calm / Dense / Fast / Local  
> **版本：** v0.1

---

# 1. 设计目标

Nimbo 不应该看起来像传统企业软件，也不应该像一个被放大的手机 App。

目标：

> **HarmonyOS 的柔和感 + 桌面开发工具的信息密度。**

需要同时满足：

- 专业
- 清爽
- 低视觉噪声
- 高信息密度
- 长时间使用不疲劳
- 具备 HarmonyOS 原生感
- Light / Dark Mode 都适合长期使用

---

# 2. 视觉方向

整体组合：

```text
Linear 的克制
+
Raycast 的精致
+
HarmonyOS 的圆润
+
Postman 的 API 信息结构
+
IDE 的桌面工作区布局
```

避免：

- 赛博朋克
- 黑底荧光绿
- 大量渐变
- 大量阴影
- 卡片套卡片
- 所有东西都有边框
- 过度拟物
- 过度动画

---

# 3. 品牌视觉

Nimbo 气质：

```text
轻
稳
安静
聪明
现代
可信
```

主品牌建议：Cloud Indigo / 雾蓝紫。

主色只用于：

- Send
- 当前选中项
- Focus Ring
- Primary Button
- Logo
- 关键操作

不要大面积铺色。

---

# 4. Light Mode

层级：

```text
App Background
↓
Sidebar Background
↓
Workspace Background
↓
Editor Surface
↓
Floating Surface
```

原则：

- 整体背景偏冷白
- Sidebar 比主区稍灰
- Workspace 接近白色
- Code Editor 独立一层
- Popup 层级更明显

不要靠大量 Border 分区域，优先使用背景色差、留白和极细 Divider。

---

# 5. Dark Mode

Dark Mode 是一级设计目标。

不要纯黑，建议深灰蓝层级：

```text
App       #181A1F 附近
Sidebar   #1D1F25 附近
Workspace #202228 附近
Surface   #25272D 附近
Editor    #17191E 附近
```

Code Editor 可以比页面更深，形成自然视觉中心。

---

# 6. 圆角

圆润，但不要手机化。

建议：

| 元素 | Radius |
|---|---:|
| Small Button | 6 |
| Input | 8 |
| Primary Button | 8 |
| Segment | 8 |
| Dropdown | 10–12 |
| Context Menu | 12 |
| Dialog | 16 |
| Empty State Card | 16 |

不要给 Sidebar、Workspace、大型列表、Request/Response 区域套大圆角卡片。

---

# 7. 间距与字体

采用 4px Grid：

```text
4 / 8 / 12 / 16 / 20 / 24 / 32 / 40
```

字体建议：

- Page Title：18–20
- Section Title：14–16
- UI Text：13–14
- Secondary：12–13
- Code：12–14 等宽

---

# 8. PC 主窗口

默认参考窗口：

```text
1440 × 900
```

最小参考：

```text
1024 × 700
```

整体采用：

> **双 Sidebar + Workspace**

```text
┌──────────────────────────────────────────────────────────────┐
│ Global Toolbar                                               │
├───────────┬───────────────┬──────────────────────────────────┤
│ Primary   │ Collection    │ Request Tabs                     │
│ Sidebar   │ Sidebar       ├──────────────────────────────────┤
│           │               │ Request                          │
│           │               ├──────────────────────────────────┤
│           │               │ Response                         │
└───────────┴───────────────┴──────────────────────────────────┘
```

---

# 9. Primary Sidebar

默认文字模式宽约 176–180。

结构：

```text
Nimbo Logo

+ New

Workspace
Collections
Environments
History

────────
Settings
```

Active 状态：

- 淡品牌背景
- 品牌色 Icon
- 稍重文字

Hover：浅灰背景。

---

# 10. New Button

顶部主按钮：

```text
+ New ▾
```

首版菜单：

- New HTTP Request
- Import cURL
- Import Collection

未实现协议不要显示 Disabled Item，直接不出现。

---

# 11. Secondary Sidebar / Collection

默认宽 240–280。

结构：

```text
Collections          +   ⋯
Search requests...
──────────────────────────
⌄ Demo API
   ⌄ Auth
      POST Login
      POST Refresh Token
   ⌄ User
      GET Get User
      PUT Update User
```

Collection Header 菜单：

- Import Collection
- Expand All
- Collapse All
- Sort by Name
- Sort Manually

---

# 12. Collection Tree

HTTP Method 使用低饱和文字/小 Badge：

- GET：Green
- POST：Orange
- PUT：Blue
- PATCH：Purple
- DELETE：Red
- HEAD / OPTIONS：Gray

颜色只作用于 Method，不染整行。

Request Node Hover 右侧出现 `⋯`。

右键菜单：

- Open
- Open in New Tab
- Duplicate
- Rename
- Copy URL
- Copy as cURL
- Move
- Delete

---

# 13. Drag & Drop

支持：

- Request → Folder
- Folder → Another Folder

DragOver Folder 使用品牌色 Highlight。

禁止将 Folder 拖到自己的子目录，显示禁止 Cursor。

---

# 14. Request Tabs

形式：

```text
GET Get Users ×
POST Login ● ×
+
```

未保存使用 `●`，不用 `*`。

Active Tab：

- Workspace Surface
- 顶部 2px 品牌色或轻微品牌底色

右键：

- Close
- Close Others
- Close Tabs to the Right
- Duplicate
- Pin Tab
- Copy Request URL

大量 Tab 使用 Overflow 菜单。

---

# 15. Request Toolbar

最重要的输入区：

```text
┌──────┬─────────────────────────────────────────────┬────────┐
│ GET ▾│ https://api.example.com/users/{{user_id}} │ Send ▾ │
└──────┴─────────────────────────────────────────────┴────────┘
```

高度约 44–48。

URL Input 必须宽、清晰、低噪声。

---

# 16. Method Selector

菜单：

- GET
- POST
- PUT
- PATCH
- DELETE
- HEAD
- OPTIONS
- Custom Method

支持键盘输入搜索。

---

# 17. URL Input

支持变量高亮：

```text
{{base_url}}
```

变量建议淡紫色。

Hover Variable 显示：

```text
base_url
https://api.example.com
Source: Development
```

Secret 不显示真实值。

Undefined Variable：轻红色下划线，Hover 显示错误。

---

# 18. Send Button

页面最明显 Action。

Idle：

```text
Send
```

Sending：

```text
Cancel
```

快捷键 `Ctrl + Enter`。

推荐 Split Button：

```text
Send ▾
```

首版最多：

- Send
- Send and Download

不要一开始堆很多低频动作。

---

# 19. Sending 状态

- Button 切 Cancel
- 顶部轻量 `Sending...`
- 不全屏 Loading
- 不锁死 Request
- 保留旧 Response
- 用户可切其他 Tab

---

# 20. Request Config Tabs

```text
Params
Headers 3
Auth
Body •
Settings
```

Active：2px 品牌色下划线。

Headers Badge 表示启用数量，Body 有内容使用小点，不要全部 Tab 都带数字。

---

# 21. Key-Value Editor

Params / Headers / Form 共用：

```text
✓ | Key | Value | Description | ⋯
```

表格不要像 Excel：

- 极浅横 Divider
- 无明显纵 Border
- Hover Row
- Focus Cell
- 只保留一行 Add parameter

支持：

- Tab / Shift+Tab
- Enter
- Arrow
- Enable Checkbox
- Duplicate
- Delete
- Bulk Edit

---

# 22. Bulk Edit

Params：

```text
page:1
limit:10
debug:true
```

Headers：

```text
Authorization: Bearer xxx
Content-Type: application/json
```

解析失败时显示错误行，不覆盖原数据。

---

# 23. Auth UI

左侧 Type，右侧配置：

```text
No Auth
Bearer Token
Basic Auth
API Key
```

Secret 默认掩码，窗口失焦自动隐藏。

---

# 24. Body UI

顶部 Segment / Tabs：

```text
None
JSON
Text
Form
Multipart
Binary
```

JSON 是主要模式。

---

# 25. JSON Editor

必须具备桌面工具感：

- Line Number
- Syntax Highlight
- Bracket Matching
- Indent
- Format
- Minify
- Search
- Word Wrap

顶部工具：

```text
JSON   Format   Minify   Wrap
```

错误不要弹 Dialog，行内 Marker + 底部错误文案。

---

# 26. Request / Response Splitter

PC 默认上下分割。

建议初始：

```text
Request 48%
Response 52%
```

支持拖动并记忆比例。

双击恢复默认。

右键可后续支持：

- Reset Split
- Request Only
- Response Only

---

# 27. Response Header

左：

```text
Body
Headers 25
Cookies 3
Timeline
```

右：

```text
● 200 OK   183 ms   12.4 KB   HTTP/2
```

状态不要用大 Badge。

颜色：

- 2xx Green
- 3xx Blue
- 4xx Orange
- 5xx Red

---

# 28. Response Timing / Size

Duration Hover 后续可显示：

```text
DNS       10 ms
Connect   21 ms
TLS       42 ms
TTFB      106 ms
Download   4 ms
```

Size 后续可显示 Transfer / Decoded Size。

首版 Timing 未完成时不要伪造详情。

---

# 29. Response Body Toolbar

```text
Pretty
Raw
Preview

JSON ▾

Format / Copy / Search / ⋯
```

低频动作收到 `⋯`，避免 Icon 过多。

---

# 30. Pretty JSON

支持：

- Collapse
- Expand
- Copy Value
- Copy Key
- Copy JSON Path
- Search

大型数组折叠显示：

```text
users: Array(128) […]
```

---

# 31. Search Response

`Ctrl + F`。

右上：

```text
user      3 / 12     ↑ ↓ ×
```

匹配项高亮。

---

# 32. Empty Response

```text
No response yet

Send the request to see the response here.

Ctrl + Enter
```

不要使用大插画。

---

# 33. Loading Response

有旧 Response：保留，Header 显示 `Sending…`。

无旧 Response：中央轻量 `Waiting for response…`。

---

# 34. Request Success

完成后只更新状态区域。

不要：

- Toast “Success”
- 弹窗
- 强烈动画

HTTP 状态本身就是反馈。

---

# 35. Network Error

示例：

```text
Connection failed

Connection refused
api.example.com:443

Retry
Details
```

Details：底层错误码、IP、端口等。

---

# 36. TLS Error

```text
TLS certificate verification failed

Certificate: api.example.com
Reason: Certificate has expired
```

动作：

- View Certificate
- Request Settings

不要直接诱导用户关闭 SSL。

---

# 37. Timeout

```text
Request timed out

The request exceeded the 30 second timeout.

Retry
Change Timeout
```

---

# 38. Large Response

```text
Large response
42.8 MB

Rendering the entire response may affect performance.

Preview first 1 MB
Save to File
```

---

# 39. Binary Response

图片直接 Preview。

ZIP 等：

```text
Binary response
application/zip
6.2 MB

Save File
```

---

# 40. Global Toolbar

左：Nimbo 品牌。

中：

```text
Search or run command...   Ctrl K
```

右：

- Environment
- Settings
- Window Controls

---

# 41. Environment Switcher

```text
Development ▾
```

菜单：

- Development ✓
- Staging
- Production
- Manage Environments

Production 使用小红点 / PROD / Protected Badge，不要整个 UI 变红。

默认 Send 不弹生产确认，但可在设置中允许 `Confirm requests in protected environments`。

---

# 42. Home / Workspace

无 Request：

```text
Nimbo

What do you want to test?

New Request
Import cURL

Recent Requests
```

不要：Welcome Banner、新闻、教程轮播、登录、会员、统计 Dashboard。

---

# 43. Import cURL

Dialog：

```text
Import cURL

[ multiline editor ]

Cancel   Import
```

解析失败不关闭 Dialog，显示明确行号/原因。

Clipboard Detection：

当 URL / Editor 无 Focus 且剪贴板以 `curl` 开头，显示轻量 Banner：

```text
cURL request detected
Import Request   Dismiss
```

---

# 44. Postman Import

流程：

```text
Select File
↓
Analyzing
↓
Import Preview
↓
Import Result
```

Preview：

- Collection Name
- Request Count
- Folder Count
- Environment Count
- Unsupported Feature Count

Partial Failure 示例：

```text
17 / 18 requests imported
1 request contains unsupported OAuth configuration.
View Details
```

---

# 45. History

侧栏按：

- Today
- Yesterday
- Previous 7 Days
- Older

列表：

```text
12:31 GET  /users   200  183ms
12:29 POST /login   200   91ms
12:22 POST /login   401   88ms
```

点击重新打开。

---

# 46. Environment Page

布局：

```text
Environment List
+
Variable Editor
```

变量字段：

- Variable
- Value
- Secret
- Description

---

# 47. Settings Page

PC 使用独立页面，不做小弹窗。

左：

- General
- Appearance
- Network
- Data
- Privacy
- About

右：具体设置。

---

# 48. Context Menu

风格：

- 12px Radius
- 微阴影
- Icon + Text
- 危险操作最后
- 少量 Divider

Delete 使用红色。

---

# 49. Tooltip

主要用于 Icon Button、截断文本、变量、状态信息。

建议 Hover 约 500ms 后出现。

---

# 50. Toast

只用于：

- Copied
- Saved
- Imported
- Deleted — Undo

不用于 Request Success。

持续约 1.5–2 秒。

---

# 51. Dialog

只用于高风险/必须决策：

- Delete Collection
- Clear History
- Reset App
- Export Secrets

Request 删除建议直接删除 + Undo Toast，Collection 删除才确认。

---

# 52. Keyboard First

PC 必须完整支持：

```text
Ctrl + Enter  Send
Ctrl + N      New Request
Ctrl + S      Save
Ctrl + W      Close Tab
Ctrl + L      Focus URL
Ctrl + K      Quick Search
Ctrl+Shift+P  Command Palette
Ctrl + F      Search Response
```

---

# 53. Command Palette

后续可作为高级效率入口：

```text
> New HTTP Request
> Import cURL
> Switch Environment
> Format JSON
> Clear Response
```

---

# 54. Mouse / Right Click

桌面内容都需要考虑：

- Right Click
- Double Click
- Drag
- Hover

不能只按触屏设计。

---

# 55. Window Resize

建议：

```text
>= 1280   Full Layout
1024–1279 Compact Layout
< 1024    Collapse Secondary Sidebar
```

1440 是主视觉基准。

Compact 下：

- Primary Sidebar 176 → 60 Icon Rail
- Secondary Sidebar 约 220
- Workspace 优先

---

# 56. Tablet

横屏：Icon Rail + Secondary Sidebar + Workspace。

触控目标尺寸增加。

---

# 57. Phone

不用 Tab-heavy PC UI。

Request / Response 页面化，Collection 使用 Drawer / 独立页面。

手机不阻塞 PC 首版。

---

# 58. Focus

统一 2px Brand Focus Ring。

Request Toolbar Focus 顺序：

```text
Method → URL → Send → Params → Headers → Auth → Body
```

---

# 59. Motion

建议：

```text
120ms / 180ms / 240ms
```

只用于：

- Menu
- Dialog
- Sidebar Expand
- Selection
- Hover

不要给 Response / JSON 加花哨动效。

---

# 60. Empty State

保持简单。

Collection：

```text
No collections yet
Create a collection to organize requests.
Create Collection
```

History：

```text
No request history yet.
```

Environment：

```text
No environments yet.
Create one to reuse variables across requests.
```

---

# 61. Error 文案原则

所有错误都遵循：

```text
What happened
+
Why
+
What user can do
```

底层 Error Code 放 Details。

---

# 62. Logo 方向

不要直接使用：

- `{}`
- `</>`
- API
- HTTP
- Terminal

建议抽象：

> 云 / 网络节点 / 请求流

要求 16px 可识别，128px 有品牌感。

---

# 63. 首批设计页面

进入正式 UI 开发前，视觉语言覆盖：

1. Main / Empty
2. Main / Request
3. Main / Sending
4. Main / Success
5. Main / Network Error
6. Main / Large Response
7. Params
8. Headers
9. Auth
10. JSON Body
11. Multipart Body
12. Collection Empty
13. Collection Tree
14. Environment List
15. Environment Editor
16. History
17. Import cURL
18. Import Postman
19. Settings
20. Dark Mode Main

当前 `assets/` 中已经包含主界面视觉稿与六状态视觉稿。

---

# 64. 第一阶段不设计/不开发

暂缓：

- WebSocket
- SSE
- GraphQL
- gRPC
- Mock
- Runner
- Scripts
- AI
- Cloud
- Login

这些等 HTTP 核心体验稳定后再做。

---

# 65. UI 状态模型

Request 生命周期：

```text
Idle
 ↓ Send
Sending
 ├ Success → Completed
 └ Error   → Failed
```

Tab：

- Saved：无标记
- Dirty：`●`

关闭 Dirty Untitled Tab：

```text
Save changes to "Login"?
Don't Save   Cancel   Save
```

已保存到 Collection 的 Request 建议自动保存。

---

# 66. UI Skeleton 验收

完成即认为第一阶段 UI 可交付：

- Light Mode 主界面完整
- Sidebar 可切换
- Collection Tree 可展开
- Request Tab 可新增、关闭、切换
- Params / Headers / Auth / Body 可切换
- URL 可编辑
- Send 有 Idle / Sending
- Request / Response 可拖动分割
- Response 可展示 Mock JSON
- Error State 可切换
- Environment Switcher 可打开
- 1024px 宽度不崩布局

---

# 67. 最终视觉原则

整个产品必须做到：

### 一眼知道怎么 Send

URL + Send 最突出。

### 一眼看懂 Request

Params / Header / Auth / Body 清晰。

### Response 永远是视觉中心

用户最终目标是看 Response。

### Sidebar 只负责组织

不要抢视觉。

### UI 不妨碍代码

JSON / Header / URL 才是主角。

用户第一次打开应该觉得：

> **“这个东西很轻。”**

用十分钟后觉得：

> **“该有的都有。”**

长期目标：

> **“我不想换回 Postman 了。”**

---

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
