# Nimbo

简体中文 · [English](README.md)

Nimbo 是一款为 HarmonyOS 打造的快速、原生、本地优先 API 调试工具。它为开发者提供专注的 HTTP 请求工作区，可用于编写请求、查看响应、管理集合和切换环境，无需登录，也不依赖云服务。

![Nimbo 界面](docs/nimbo-dev-package/assets/nimbo-main-ui.png)

## 核心特性

- HarmonyOS 原生应用，PC 优先设计，并适配平板和手机
- 支持 GET、POST、PUT、PATCH、DELETE、HEAD 和 OPTIONS 请求
- 支持查询参数、请求头、Bearer/Basic/API Key 认证和多种正文类型
- 支持 Pretty/Raw 响应、响应头、Cookie、错误状态和二进制保存
- 支持嵌套集合与文件夹，请求保存后可持续编辑和本地恢复
- 本地环境变量与请求变量解析
- 本地请求历史和工作区恢复
- cURL 导入/导出，以及 Postman Collection/Environment 导入
- Nimbo 本地备份导出，默认对密钥信息脱敏
- Light、Dark 和跟随系统主题
- 简体中文和英文界面

## 项目状态

Nimbo 1.0 的核心工作流已经实现，可在 HarmonyOS PC 目标上运行：

```text
创建或导入请求
      ↓
配置并发送请求
      ↓
查看响应
      ↓
保存到集合
      ↓
通过环境与历史记录重复调试
```

WebSocket、SSE、GraphQL、gRPC、Collection Runner、脚本、AI、云同步和账号系统目前尚未实现。界面不会提前展示不可用的功能入口。

## 环境要求

- macOS
- 已安装 HarmonyOS SDK 的 DevEco Studio
- 编译/目标 SDK：HarmonyOS 6.1.1（API 24）
- 最低兼容 SDK：HarmonyOS 6.0.0（API 20）
- HarmonyOS 真机或模拟器

## 开始开发

克隆仓库：

```shell
git clone git@github.com:burybell/nimbo.git
cd nimbo
```

创建本机构建配置：

```shell
cp build-profile.example.json5 build-profile.json5
```

使用 DevEco Studio 打开项目，为自己的应用配置签名，然后运行 `entry` 模块。

如果 DevEco Studio 安装在 macOS 默认路径，也可以通过命令行构建：

```shell
./build_hap.sh
```

同时执行仓库检查与本地 HarmonyOS 构建：

```shell
./scripts/quality-check.sh --build
```

HAP 输出目录：

```text
entry/build/default/outputs/default/
```

`build-profile.json5` 已被刻意忽略，因为 DevEco Studio 可能在其中保存本机签名路径和凭据。请勿提交本地签名 Profile、证书、密钥库或密码。

## 项目结构

```text
AppScope/                         应用资源与标识
entry/src/main/ets/
├── app/                          应用组合与根状态
├── controller/                   请求流程编排
├── models/                       UI 与持久化模型
├── network/                      HTTP 引擎
├── services/                     导入、导出与本地存储
├── state/                        默认值与初始状态
└── ui/                           组件、页面与设计 Token
docs/nimbo-dev-package/           PRD、UI/UX 规范与开发交接文档
```

当前交付范围和工程约束以 [`CODEX_HANDOFF.md`](docs/nimbo-dev-package/CODEX_HANDOFF.md) 为准。

## 本地优先与隐私

集合、请求、环境、历史记录、偏好设置和恢复的标签页都保存在本地设备。当前版本无需账号，也不提供云同步。导出包含密钥的备份时，请妥善保管导出文件。

## 参与贡献

欢迎提交 Issue 和 Pull Request。较大的改动请先通过 Issue 讨论范围。开发过程中请始终保持项目可构建，不要展示尚未完成的控件，也不要在未讨论的情况下实现交接文档中明确暂缓的能力。

提交改动前请阅读 [`CONTRIBUTING.md`](CONTRIBUTING.md)。所有贡献都需要接受 [Nimbo 贡献者许可协议](CLA.md)。

## 开源许可

Nimbo 采用 [GNU Affero General Public License v3.0 only](LICENSE) 许可。版权所有者未来可能另行提供商业许可。

## 应用标识

- 包名：`com.nimbo.app`
- 华为 APP ID：`6917615930484878194`

该 APP ID 用于标识官方 Nimbo 应用。贡献者本地开发时应使用自己的应用标识与签名配置。
