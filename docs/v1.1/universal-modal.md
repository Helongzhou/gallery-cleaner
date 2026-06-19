# Universal Modal（v1.1）

**状态：已实现（Phase 1）**

## 范围

- `UniversalModal.showInfo()` — 单按钮提示
- `UniversalModal.showAction()` — 主/次双按钮确认
- `AppText.formatMixed()` — Modal 文案中英混排插空格

## 视觉

- 遮罩：`#000` 50% + `blur(4px)`
- 容器：16px 圆角、24px 内边距、主题自适应背景
- 按钮：最小高度 44pt；`destructive: true` 主按钮红色

## 已迁移

| 页面 | 场景 |
|------|------|
| 我的 | Face ID 开启确认 |
| 截图清理 | 批量删除确认 |
| 待删除 | 彻底删除确认 |

## 暂未迁移

- 首页「新建相册」输入框 — 保留 `AlertDialog`（v2 扩展 `input` 类型）

## Phase 2（未做）

- 全局 `AppSpacing` 16/24 统一
- 图标 2px 描边 + 5% 圆形锚点
- StatusBar 逐屏梳理
- 全库 `AppText` Widget
