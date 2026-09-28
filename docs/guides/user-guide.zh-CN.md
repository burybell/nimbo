# Nimbo 用户指南

[English](user-guide.en.md) · 简体中文

本指南对应当前仓库已经实现的功能。Nimbo 是本地优先的桌面 API 客户端，请求、集合、环境、历史和偏好默认保存在本机，无需账号。

## 1. 快速开始

1. 点击左上角“新建”，选择 HTTP、WS 或 SSE 请求。
2. 对 HTTP 请求选择 Method，输入 URL，并按需配置参数、标头、认证和正文。
3. 点击“发送”或按 `Ctrl+Enter`。
4. 在下半区查看正文、标头、Cookie、脚本、测试和时间线。
5. 按 `Ctrl+S`，选择集合或文件夹并保存。

也可以点击标题栏“导入”，从 cURL、Postman、OpenAPI 或 Swagger 开始。

## 2. 工作区与请求 Tab

- 新建或打开请求后会出现在顶部 Tab 栏；新 Tab 按创建顺序从左向右排列。
- 双击请求名称可以原位重命名；Enter 或失焦确认，Esc 取消。
- 右键请求 Tab 可以关闭当前、关闭全部或新建请求。
- 关闭正在发送或连接的 Tab 会尝试取消当前操作。
- 开启“恢复工作区”后，重启应用会恢复请求 Tab 和本地状态。

## 3. 集合、文件夹与环境

集合是顶层 API 分组，文件夹可以多层嵌套。集合或文件夹的三点菜单支持：

- 新建 HTTP、WS 或 SSE 请求
- 新建子文件夹
- 编辑作用域变量
- 运行当前集合或文件夹
- 重命名和删除

请求菜单支持重命名、创建副本和删除。破坏性操作需要确认。

标题栏环境选择器决定当前环境。开发、预发布、生产是不可删除的默认环境；可以在环境页面创建自定义环境。环境变量是变量解析链的基础层。

## 4. HTTP 请求

### URL 与参数

选择 GET、POST、PUT、PATCH、DELETE、HEAD 或 OPTIONS。Params 表格中只有启用的行会进入查询字符串。URL 输入 `h` 后按 Tab 可补全 `http://`，输入 `hs` 后按 Tab 可补全 `https://`。

### 标头与认证

Headers 支持变量和启用状态。认证支持：

- Bearer Token
- Basic 用户名与密码
- API Key，写入 Header 或 Query

字面凭据编辑结束后会遮罩；`{{变量}}` 表达式保持可见，便于检查名称和补全。

### 请求正文

- JSON：语法高亮、括号与引号配对、智能缩进、冒号空格、撤销/重做和变量补全。
- 文本：发送原始文本。
- 表单：发送 URL 编码键值对。
- Multipart：支持文本字段与本地文件。
- Binary：发送一个本地二进制文件。

### 请求设置

每个请求可以配置超时、跟随重定向、SSL 验证和 Cookie 容器。关闭 SSL 验证会降低安全性，只应用于明确需要的本地调试场景。

## 5. 查看响应

- Body：JSON Pretty/Raw、高亮、光标选择、搜索、复制和下载。
- Headers：查看响应标头。
- Cookies：查看响应 Cookie。
- Scripts：查看前置与后置脚本输出。
- Tests：查看每条声明式测试的期望值、实际值和结果。
- Timeline：查看 DNS、连接、TLS、发送、TTFB、下载和总耗时。

图片响应可直接预览，视频响应可以播放；其他二进制内容可以保存原始文件。大文本响应使用安全的预览方式，下载仍保留原始内容。

请求失败时，错误页会显示摘要、可能原因、建议检查项、失败阶段、主机、超时、TLS 和重定向设置、系统错误码及技术详情。可复制诊断信息用于排查。

## 6. 变量

变量引用格式：

```text
{{BASE_URL}}/users/{{USER_ID}}
```

优先级：

```text
Runner 数据行 > 最近文件夹 > 上级文件夹 > 集合 > 当前环境
```

HTTP 请求在“设置 → 有效变量”查看最终值；WS 和 SSE 在“变量”页签查看。每项都会显示来源、覆盖链和跳转编辑入口。缺失变量会在发送前显示，并可直接打开最近的配置作用域。

完整规则见[变量使用指南](variables.zh-CN.md)。

## 7. Pre-request 与 Post-response Script

前置脚本可以通过受限 API 修改本次发送：

```javascript
nimbo.request.headers.set('X-Trace-Id', nimbo.environment.get('traceId'));
nimbo.request.url = `${nimbo.request.url}?source=nimbo`;
```

后置脚本读取只读响应，并可显式写入当前环境：

```javascript
const payload = JSON.parse(nimbo.response.body);
nimbo.environment.set('responseId', payload.id);
console.log(nimbo.response.statusCode, payload.id);
```

执行顺序固定为：

```text
Pre-request → 有效变量解析 → HTTP → Post-response → JSONPath 提取 → Tests
```

前置脚本失败会阻止发送。脚本在全新的本地沙箱中执行，并限制时间、内存、栈、源码大小、并发数和控制台输出；不支持远程模块、第三方包和完整 Postman `pm.*` API。

完整 API、语法、示例和限制见[脚本使用指南](scripts.zh-CN.md)。

## 8. JSONPath 提取与 Tests

提取规则先对最新 JSON 响应预览路径，再选择明确的目标环境。可以标记 Secret，并决定是否允许覆盖已有变量。无效 JSON、无效路径、未匹配、目标缺失和冲突会分别报告。

声明式 Tests 支持：

- 状态码等于
- 响应耗时小于
- Header 存在或等于
- JSONPath 存在或等于

Tests 不执行任意代码，也不会修改请求或环境。

## 9. Collection Runner

点击集合或文件夹旁的运行图标：

1. 选择环境和迭代次数。
2. 可选本地 CSV 或 JSON 数据文件。
3. 检查请求数量后启动。
4. 查看每个请求迭代的状态、状态码、耗时和测试统计。
5. 按需筛选或导出报告。

CSV 第一行必须是唯一且非空的列名，支持引号字段、转义引号和字段内换行。JSON 必须是非空扁平对象数组，字段值只允许字符串、数字、布尔值或 null。

限制：文件不超过 2 MB、1000 行、100 列；请求顺序执行，不并发。WS 与 SSE 会被跳过。停止后不再启动新请求，并尽可能取消当前请求；报告不会记录数据行内容或密钥值。

## 10. WebSocket

1. 新建 WS 请求并选择 WS 或 WSS。
2. 输入地址，配置 Headers 和认证。
3. 点击“连接”，观察连接状态和连接记录。
4. 在“消息”页输入文本，按 Enter 或 Ctrl+Enter 发送，Shift+Enter 换行；也可以点击输入框右下角的发送图标。消息支持搜索、复制、清空和导出，合法 JSON 会自动格式化并高亮。
5. 点击“断开”结束连接。

地址、标头、认证和文本消息支持变量。当前版本不支持二进制消息、自动重连、Socket.IO 和 GraphQL Subscription。

## 11. Server-Sent Events

1. 新建 SSE 请求并选择 HTTP Method。
2. 输入 HTTP/HTTPS 地址，配置 Headers、认证，以及 POST 流式接口所需的 JSON 或文本 Body。
3. 点击“连接”，查看 HTTP 状态与 Content-Type。
4. 搜索、复制、清空或导出收到的事件；合法 JSON `data` 会自动格式化并高亮，普通文本保持原样。
5. 点击“停止”主动结束持续流。

解析器支持 CRLF、跨块事件、注释、默认 `message`、自定义 `event`、多行 `data`、`id` 和 `retry`。事件正文只保留在当前 Tab 内存中。

## 12. 导入与导出

### cURL

在标题栏打开“导入 → cURL”，粘贴命令并检查高亮内容。受支持的 Method、URL、Header、认证和正文会转换成新请求。

### API 文件

选择或拖入 JSON 文件。支持自动识别：

- Postman Collection
- Postman Environment
- OpenAPI 3.0 / 3.1 JSON
- Swagger 2.0 JSON

Postman 根变量会成为集合变量。OpenAPI Tag 会成为文件夹，并映射 Server、参数、安全方案和稳定的请求正文示例。OpenAPI YAML 当前不支持。

导入是原子操作：必需结构错误不会污染已有数据；被跳过的可选能力会显示警告。

### Nimbo 备份

设置页可以导出本地备份。普通导出递归清除 Secret 值；包含密钥的导出必须明确确认。不要将包含密钥的文件提交到 Git。

## 13. 搜索和快捷键

- `Ctrl+K`：全局搜索请求、集合、历史、环境和命令。
- `Ctrl+Enter`：发送当前 HTTP 请求。
- `Ctrl+S`：保存或更新当前请求。
- `Ctrl+A`：编辑器全选。
- `Ctrl+Z`：撤销。
- `Ctrl+Shift+Z` / `Ctrl+Y`：重做。
- `Tab` / `Shift+Tab`：缩进或反缩进；候选打开时 Tab 接受候选。
- 方向键：选择变量或脚本候选。
- `Enter`：接受候选。
- `Esc`：关闭搜索或候选等临时界面。

## 14. 常见问题

### 变量存在但提示缺失

检查名称大小写、启用状态和非空值，再查看“有效变量”的来源与覆盖链。Runner 数据可能只在当前迭代覆盖该值。

### DNS、连接、TLS 或超时失败

先复制诊断，再根据失败阶段检查协议、域名、端口、服务监听地址、VPN/代理、证书链、系统时间、SSL 设置、重定向和超时。

### 导入失败

确认输入是完整 cURL 或有效 JSON，并阅读预览警告。OpenAPI YAML 需要先转换为 JSON。

### 重启后没有恢复工作区或历史

检查设置中的“恢复工作区”“保存历史”和保留天数。WebSocket 消息、SSE 事件正文和连接记录按设计只保存在内存。

### 如何恢复默认状态

设置中的重置会清除本地应用数据并恢复安全默认值。重置前先导出不含密钥的备份。
