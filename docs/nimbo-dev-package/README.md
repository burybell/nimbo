# Nimbo 开发资料包

Nimbo 是一个 **HarmonyOS 原生 API 调试工具**，产品策略为：

- HarmonyOS only
- HarmonyOS PC 优先，兼容平板与手机
- 开源社区版（AGPL-3.0-only），保留商业授权可能
- Local First
- No Login
- Fast / Native

## 目录

```text
nimbo-dev-package/
├── README.md
├── CODEX_HANDOFF.md
├── docs/
│   ├── 01-Nimbo-PRD.md
│   ├── 02-Nimbo-UIUX-Spec.md
│   └── 03-Nimbo-Design-System.md
└── assets/
    ├── nimbo-main-ui.png
    └── nimbo-ui-six-screens.png
```

## 文档优先级

开发中如出现冲突，按以下顺序作为 Source of Truth：

1. `CODEX_HANDOFF.md`：当前开发范围、阶段和约束
2. `docs/01-Nimbo-PRD.md`：产品功能、版本范围
3. `docs/02-Nimbo-UIUX-Spec.md`：页面布局、交互和状态
4. `docs/03-Nimbo-Design-System.md`：Token、组件、响应式和组件架构
5. `assets/`：视觉风格参考，不要求逐像素照抄

## 当前目标

**Milestone 0–9 已全部完成。** Nimbo 1.0 已具备真实 HTTP、本地数据、导入导出、二进制响应保存、Light / Dark / System 主题，以及 HarmonyOS PC、Tablet 和 Phone 响应式布局。Milestone 8 完成了已有功能的 UI 与交互收口；Milestone 9 完成了开源治理、仓库质量门禁、无签名清洁构建验收和首个公开 Alpha 发布。继续开发前必须先定义新的里程碑，不得自行进入 1.1/1.2 或明确暂缓的能力。

最初的 UI Skeleton 结构为：

```text
App Window
├── Global Toolbar
├── Primary Sidebar
├── Collection Sidebar
├── Request Tabs
├── Request Editor
└── Response Viewer
```

全部先由 Mock State 驱动，UI 稳定后再接 HTTP Engine。

## 产品核心原则

```text
Open Source
Local
Fast
Native
No Login
```

长期目标：

> 鸿蒙调 API，用 Nimbo。
