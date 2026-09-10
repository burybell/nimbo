# Nimbo AppGallery PC 发布素材

## 应用信息

- 应用名称：Nimbo
- APP ID：6917615930484878194
- 包名：`com.nimbo.app`
- 发布设备：HarmonyOS PC（`2in1`）
- 版本名称：`0.1.0`
- 版本号：`1000000`
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

- `app-icon-216.png`：216 × 216 px 应用图标
- `screenshots/01-request-response.png`：请求与 JSON 响应
- `screenshots/02-collections.png`：中文集合与文件夹操作
- `screenshots/03-environments.png`：环境变量管理
- `screenshots/04-image-preview.png`：图片响应预览
- `screenshots/05-settings.png`：外观与字体设置
- `Nimbo-示例集合.postman_collection.json`：截图与体验用中文示例集合
- `package/Nimbo-0.1.0-PC-release-unsigned.hap`：PC 专用 Release 未签名包，可用于 AppGallery Connect 云管理签名流程
- `package/Nimbo-0.1.0-PC-release-debug-profile-signed.hap`：使用现有设备调试 Profile 签名的模拟器测试包，不可提交商店
- `package/SHA256SUMS.txt`：安装包完整性校验值

所有商店截图均为真实 HarmonyOS PC 模拟器界面，尺寸为 1920 × 1080 px、PNG 格式且小于 5 MB。

## 上架备注

- 应用仅声明 `2in1` 设备类型。
- 应用需要网络权限，用途仅为执行用户主动配置的 HTTP 请求。
- 应用不要求账号登录；工作区数据默认存储在本机。
- 提交前请在 AppGallery Connect 中确认正式签名证书、隐私政策 URL、支持邮箱和版权信息均为最终发布值。

## 安装包签名状态

当前代码产物已经是 `release` 模式、`debug: false`，模块只声明 `2in1`。但本机现有签名 Profile 为 `type: debug` 且绑定模拟器设备，因此目录中的已签名 HAP 只能用于测试，不能直接上传应用市场。

正式提交可选择以下一种方式：

1. 通过 DevEco Studio 上传 `Nimbo-0.1.0-PC-release-unsigned.hap`，在 AppGallery Connect 使用云管理签名。
2. 在 AppGallery Connect 申请发布证书与发布 Profile，然后在本机配置相应 `.p12`、`.cer`、`.p7b`，重新构建正式签名 HAP。

不要将 `Nimbo-0.1.0-PC-release-debug-profile-signed.hap` 上传到应用市场。
