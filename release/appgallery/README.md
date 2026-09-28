# Nimbo AppGallery PC 发布素材

## 应用信息

- 应用名称：Nimbo
- APP ID：6917615930484878194
- 包名：`com.nimbo.app`
- 发布设备：PC（`2in1`）
- 版本名称：`1.1`
- 版本号：`1000002`
- 分类建议：工具 / 开发者工具

## 一句话简介（小编推荐）

本地优先的桌面 API 开发工具，统一管理请求、实时连接与自动化流程。

## 应用介绍

Nimbo 是一款面向开发者的桌面 API 开发工具。它以清晰、紧凑的工作区组织请求、响应、集合和环境，帮助你完成接口开发、联调与问题定位。

你可以配置 HTTP、WebSocket 和 SSE 请求，编辑 URL、参数、标头、认证信息及多种请求体。响应区支持 JSON 高亮、正文检索、复制和下载，也可直接预览图片与视频。集合、文件夹和环境变量能够按作用域组织，变量来源与覆盖关系可随时查看。

Nimbo 支持 cURL、API 集合与 OpenAPI 定义文件导入，并提供请求前后脚本、JSONPath 变量提取、响应断言和 Collection Runner。WebSocket 消息与 SSE 事件支持检索、复制、导出和 JSON 格式化显示。

请求、集合、环境、历史和偏好设置默认保存在本机，无需注册账号。内置中英文界面、浅色与深色主题以及离线帮助中心，适合个人开发、接口联调和本地工作流管理。

## 核心功能

- 支持常用 HTTP Method、参数、标头和认证配置
- 支持 WebSocket 文本消息与 SSE 流式事件
- 支持 JSON、文本、表单、多部分和二进制请求体
- JSON 编辑、高亮、自动配对和智能缩进
- 响应正文高亮、搜索、复制和按类型下载
- 图片响应预览与视频响应播放
- 多层集合、文件夹、请求和作用域变量管理
- 请求前后脚本、JSONPath 提取与响应断言
- Collection Runner 顺序执行、迭代数据和脱敏报告
- cURL、API 集合与 OpenAPI 定义文件导入
- 请求历史、全局搜索和离线帮助中心
- 中英文界面、浅色/深色主题和界面字体切换
- 本地优先，无需登录

## 新版本特性

- 新增 WebSocket 与 SSE 工作区，支持认证、变量、消息检索和导出
- 新增 Collection Runner，可按集合或文件夹顺序运行请求并导出脱敏结果
- 新增集合与文件夹变量、变量来源查看和缺失变量定位
- 完善请求前后脚本、JSONPath 提取、响应断言和时间线
- 新增离线帮助中心，以及中英文变量与脚本使用指南
- 优化窗口缩放、标题栏、代码编辑器和实时消息 JSON 阅读体验

## 素材清单

- `app-icon-1024.png`：1024 × 1024 px 应用图标（AppGallery 首选上传文件，与包内分层图标同源合成）
- `app-icon-216.png`：216 × 216 px 应用图标（兼容上传尺寸）
- `screenshots/01-request-response.png`：请求与 JSON 响应
- `screenshots/02-collections.png`：JSON 请求正文编辑与语法高亮
- `screenshots/03-environments.png`：环境变量管理
- `screenshots/04-history.png`：请求历史与状态记录
- `screenshots/05-settings.png`：语言、外观、网络与数据偏好设置
- `Nimbo-Sample-Collection.postman_collection.json`：截图与体验用中文示例集合
- `package/Nimbo-1.1-PC-release-signed.app`：使用共享发布证书和 Nimbo 发布 Profile 构建的正式提审包
- `package/SHA256SUMS.txt`：安装包完整性校验值

所有商店截图均为真实 PC 界面与品牌背景合成的海报，尺寸为 1920 × 1080 px、PNG 格式且小于 5 MB。界面先从原始 3120 × 2080 捕获中等比裁出 3120 × 1755，再等比缩放为 1504 × 846，没有横向或纵向拉伸；海报文字使用系统圆体风格字体。

## 上架备注

- 应用仅声明 `2in1` 设备类型。
- 包内应用图标使用 1024 × 1024 px 的前景、背景分层资源；前景带透明通道，背景完全不透明，系统负责最终圆角蒙版。
- 应用需要网络权限，用途仅为执行用户主动配置的 HTTP 请求。
- 应用不要求账号登录；工作区数据默认存储在本机。
- 提交前请在 AppGallery Connect 中确认正式签名证书、隐私政策 URL、支持邮箱和版权信息均为最终发布值。

## 安装包签名状态

`Nimbo-1.1-PC-release-signed.app` 已使用 `/Users/lake/app` 中的共享发布密钥、发布证书及 Nimbo 独立发布 Profile 完成签名，可用于正式软件包上传。验收结果：

- 构建模式：Release
- 包名：`com.nimbo.app`
- APP ID：`6917615930484878194`
- Profile 类型：`release`
- 设备类型：`2in1`
- 版本：`1.1`（`1000002`）
- APP 签名：摘要与发布 Profile 验证通过
- SHA-256：`ec40185eab432317d3144a67262606a1c8407e89a92ccb44b16927e600f2dd08`

提审时请上传 `.app` 文件。不要上传目录中的调试 Profile 签名 HAP。
