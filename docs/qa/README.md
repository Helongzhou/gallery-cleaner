# QA 规格 — Bug 修复与自动化测试

## Bug 修复

| # | 问题 | 方案 |
|---|------|------|
| 1 | 滑动页标题不居中 | Stack 真居中 + 左右对称 72pt 占位 |
| 2 | 待删除取消无效 | `canPop()` → pop，否则 `go(home)` |

## 测试策略

| 层 | 工具 | 场景 |
|----|------|------|
| CI 回归 | `integration_test` | P0+P1 冒烟 |
| 开发探索 | Marionette MCP（Phase 2） | AI 交互式点按/截图 |

## 第一批测试（P0+P1）

- 首页加载、仅删除模式进入滑动
- 待删除页取消回首页
- 滑动页 header 存在
- 目标相册选中态

## Widget Keys

- `home_start_organize` — 底部开始整理（通过 libraryTabState 触发，首页用 `home_screen`）
- `target_delete_only` — 仅删除卡片
- `pending_delete_cancel` — 取消按钮
- `swipe_header_title` — 滑动页标题

## 怎么跑

### 终端回归（不打开模拟器）

```bash
flutter test
```

### 模拟器里「看得见」（按需）

```bash
open -a Simulator
flutter test integration_test -d "iPhone 17 Pro"
```

> 测试结束后若桌面图标点开白屏：用 `flutter run` 重新启动，不要用 `simctl launch`。

### 手动玩 App

```bash
flutter run -d "iPhone 17 Pro"
```

若白屏：删 App 重装一次

```bash
xcrun simctl uninstall booted com.albumorganizer.albumOrganizer
flutter run -d "iPhone 17 Pro"
```

## Phase 2（后续）

- 接入 `marionette_flutter` + Marionette MCP
- Cursor MCP 配置
- CI workflow
