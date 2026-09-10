# Nimbo 产品需求文档 PRD

> **产品名称：** Nimbo  
> **产品定位：** HarmonyOS 原生 API 调试工具  
> **产品形态：** HarmonyOS PC 优先，兼容平板与手机  
> **商业模式：** AGPL 开源社区版，保留商业授权可能
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
| 开源社区版 | ✅ |
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
开放源码与本地优先
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
Open Source
Local
Fast
Native
No Login
```
