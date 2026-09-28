# Nimbo 脚本指南

[English](scripts.en.md) · 简体中文

Nimbo 提供 Pre-request 和 Post-response 两个 JavaScript 阶段。脚本在本地受限沙箱中运行，适合按请求动态调整数据、读取响应、记录诊断和向当前环境写入值。

## 1. 在哪里编写

打开一个 HTTP 请求，在请求配置区选择“前置脚本”或“后置脚本”，启用后输入代码。编辑器支持 JavaScript 高亮和 API 补全：输入 `nimbo.`、`nimbo.request.` 或 `nimbo.response.`，用方向键选择，按 Enter 或 Tab 补全，Esc 关闭候选。

脚本支持常用 JavaScript 语法，包括 `const`、`let`、字符串、数字、布尔值、数组、对象、条件、循环、函数、模板字符串、`JSON.parse`、`JSON.stringify` 和 `throw`。

## 2. 执行顺序

```text
Pre-request → 应用环境写入 → 解析有效变量 → HTTP 请求
            → Post-response → 应用环境写入 → JSONPath 提取 → Tests
```

- 前置脚本失败会阻止网络请求。
- 后置脚本失败不会丢弃已经收到的响应，提取和 Tests 仍继续执行。
- 单次脚本的环境写入是原子的：脚本最终失败时，本次写入全部不生效。
- 对 `nimbo.request` 的修改只影响本次发送，不会暗中覆盖集合中已保存的请求。

## 3. Pre-request API

前置脚本可读写：

| API | 类型 | 说明 |
| --- | --- | --- |
| `nimbo.request.method` | string | HTTP Method，写入值会转成大写，必须是受支持的方法 |
| `nimbo.request.url` | string | 本次请求 URL |
| `nimbo.request.body` | string | 请求正文；从 `none` 状态写入时会自动切到 `text` |
| `nimbo.request.bodyType` | string | 正文类型 |
| `nimbo.request.headers.get(name)` | function | 按名称读取标头，不区分大小写；缺失返回 `undefined` |
| `nimbo.request.headers.set(name, value)` | function | 新增或覆盖标头，值会转成字符串 |
| `nimbo.request.headers.remove(name)` | function | 删除标头，不区分大小写 |

示例：加入认证和追踪标头。

```javascript
const token = nimbo.environment.get('ACCESS_TOKEN');
if (!token) throw new Error('ACCESS_TOKEN is required');

nimbo.request.headers.set('Authorization', 'Bearer ' + token);
nimbo.request.headers.set('X-Trace-Id', 'nimbo-' + Date.now());
```

示例：修改 JSON 正文。

```javascript
const payload = JSON.parse(nimbo.request.body);
payload.source = 'nimbo';
payload.sentAt = new Date().toISOString();
nimbo.request.bodyType = 'json';
nimbo.request.body = JSON.stringify(payload);
```

## 4. Post-response API

后置脚本中的响应对象只读：

| API | 类型 | 说明 |
| --- | --- | --- |
| `nimbo.response.statusCode` | number | HTTP 状态码 |
| `nimbo.response.statusText` | string | 状态文本 |
| `nimbo.response.body` | string | 原始文本正文；JSON 仍需 `JSON.parse` |
| `nimbo.response.contentType` | string | Content-Type |
| `nimbo.response.size` | string | 展示用响应大小 |
| `nimbo.response.duration` | string | 展示用总耗时 |
| `nimbo.response.protocol` | string | HTTP 协议版本 |
| `nimbo.response.headers.get(name)` | function | 不区分大小写读取标头 |

示例：成功时保存响应 ID。

```javascript
if (nimbo.response.statusCode >= 200 && nimbo.response.statusCode < 300) {
  const payload = JSON.parse(nimbo.response.body);
  nimbo.environment.set('LAST_RESPONSE_ID', payload.id);
}
```

示例：读取响应标头并输出诊断。

```javascript
const requestId = nimbo.response.headers.get('x-request-id');
console.log('status', nimbo.response.statusCode);
console.log('request-id', requestId);
```

## 5. 环境变量 API

两个阶段都支持：

- `nimbo.environment.get(name)`：读取当前选中环境，缺失时返回 `undefined`。
- `nimbo.environment.set(name, value)`：向当前选中环境写入字符串。

`set` 需要先选择环境，且变量名不能为空。脚本不能直接修改集合、文件夹或 Runner 数据变量。若同名集合/文件夹变量优先级更高，写入环境后当前请求看到的最终值仍可能被覆盖，可在“有效变量”中检查来源链。

## 6. 控制台与结果

支持 `console.log`、`console.info`、`console.warn` 和 `console.error`。多个参数会用空格连接，按调用顺序显示在响应“脚本”页。日志只用于诊断，不改变脚本成功状态。不要打印 Token、密码、Cookie 或完整 Authorization 标头。

响应“脚本”页还会显示阶段、耗时、成功、异常、超时或内存限制，以及错误堆栈。

## 7. 限制与不支持项

- 默认执行超时：500 ms
- 默认内存：8 MB
- 栈：512 KB
- 源码：1 MB
- 同时运行：最多 2 个脚本
- 控制台：最多 200 行或 64 KB
- 每次执行使用新上下文，不能依赖上次留下的全局变量
- 不提供文件、额外网络请求、远程模块和第三方包
- 不支持完整 Postman `pm.*` API；请使用 `nimbo.*`

若只是从 JSON 响应提取字段，优先使用声明式 JSONPath；若只是验证状态码、耗时、Header 或 JSON 值，优先使用 Tests。脚本更适合需要条件、组合或动态改写的场景。

## 8. 常见问题

### `environment.set` 报错

确认已经在标题栏选择环境，变量名非空。脚本失败时写入不会保留。

### JSON 解析失败

`body` 始终是字符串。先确认 Content-Type 和响应内容确实是 JSON，再调用 `JSON.parse`；必要时使用 `try/catch` 输出诊断。

### 修改了请求但保存内容没变

这是设计行为。前置脚本只生成本次发送快照。如需永久修改，请回到请求编辑器修改并按 `Ctrl+S`。

### 写入环境后变量值没有变化

打开“有效变量”检查是否存在优先级更高的 Runner、文件夹或集合变量覆盖了同名环境变量。
