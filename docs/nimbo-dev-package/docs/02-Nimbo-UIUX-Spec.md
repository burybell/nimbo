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
