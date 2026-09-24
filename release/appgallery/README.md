# Nimbo AppGallery PC 发布素材

## 应用信息

- 应用名称：Nimbo
- APP ID：6917615930484878194
- 包名：`com.nimbo.app`
- 发布设备：HarmonyOS PC（`2in1`）
- 版本名称：`1.0`
- 版本号：`1000001`
- 分类建议：工具 / 开发者工具

## 一句话简介（小编推荐）

本地优先的鸿蒙 API 调试工具，让请求、响应与环境管理更清晰。

## 应用介绍

Nimbo 是一款面向开发者的鸿蒙电脑原生 API 调试客户端。它以清晰、紧凑的桌面工作区组织请求、响应、集合和环境，帮助你快速验证 HTTP 接口。

你可以编辑 URL、参数、标头、认证信息，以及 JSON、文本、表单、多部分和二进制请求体；响应区支持 JSON 高亮、正文搜索、复制和下载，并可直接预览图片与视频。Nimbo 还提供多层集合、环境变量、请求历史、cURL 与 Postman 导入、浅色/深色主题和中英文界面。

请求、集合、环境和历史数据默认保存在本机，无需登录，适合个人开发、接口联调和本地调试。

## 核心功能

- 支持常用 HTTP Method、参数、标头和认证配置
- 支持 JSON、文本、表单、多部分和二进制请求体
- JSON 编辑、高亮、自动配对和智能缩进
- 响应正文高亮、搜索、复制和按类型下载
- 图片响应预览与视频响应播放
- 多层集合、文件夹和请求管理
- 开发、预发布、生产及自定义环境变量
- 请求历史、cURL 导入和 Postman Collection / Environment 导入
- 中英文界面、浅色/深色主题和界面字体切换
- 本地优先，无需登录

## 素材清单

- `app-icon-1024.png`：1024 × 1024 px 应用图标（AppGallery 首选上传文件，与包内分层图标同源合成）
- `app-icon-216.png`：216 × 216 px 应用图标（兼容上传尺寸）
- `screenshots/01-request-response.png`：请求与 JSON 响应
- `screenshots/02-collections.png`：JSON 请求正文编辑与语法高亮
- `screenshots/03-environments.png`：环境变量管理
- `screenshots/04-history.png`：请求历史与状态记录
- `screenshots/05-settings.png`：语言、外观、网络与数据偏好设置
- `Nimbo-Sample-Collection.postman_collection.json`：截图与体验用中文示例集合
- `package/Nimbo-1.0-PC-release-signed.app`：使用共享发布证书和 Nimbo 发布 Profile 构建的正式提审包
- `package/SHA256SUMS.txt`：安装包完整性校验值

所有商店截图均为真实 HarmonyOS PC 模拟器最大化界面与品牌背景合成的海报，尺寸为 1920 × 1080 px、PNG 格式且小于 5 MB。界面先从原始 3120 × 2080 捕获中等比裁出 3120 × 1755，再等比缩放为 1504 × 846，没有横向或纵向拉伸；海报文字使用 HarmonyOS Sans SC。

## 上架备注

- 应用仅声明 `2in1` 设备类型。
- 包内应用图标使用 1024 × 1024 px 的前景、背景分层资源；前景带透明通道，背景完全不透明，系统负责最终圆角蒙版。
- 应用需要网络权限，用途仅为执行用户主动配置的 HTTP 请求。
- 应用不要求账号登录；工作区数据默认存储在本机。
- 提交前请在 AppGallery Connect 中确认正式签名证书、隐私政策 URL、支持邮箱和版权信息均为最终发布值。

## 安装包签名状态

`Nimbo-1.0-PC-release-signed.app` 已使用 `/Users/lake/app` 中的共享发布密钥、发布证书及 Nimbo 独立发布 Profile 完成签名，可用于 AppGallery Connect 软件包上传。验收结果：

- 构建模式：Release
- 包名：`com.nimbo.app`
- APP ID：`6917615930484878194`
- Profile 类型：`release`
- 设备类型：`2in1`
- 版本：`1.0`（`1000001`）
- APP 签名：验证通过，签名证书与共享发布证书一致
- SHA-256：`70458cca01b0c717e6f101e91539c8a0d06e52dca9d6bd4163e50826d60c9e2f`

提审时请上传 `.app` 文件。不要上传目录中的调试 Profile 签名 HAP。
