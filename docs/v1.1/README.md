# PRD — 相册主理人 v1.1

**状态：已实现**（2026-06-19）

> v1 基线见 [../v1/README.md](../v1/README.md) · 变更摘要见 [../CHANGELOG.md](../CHANGELOG.md)

## 一句话

在 v1 滑动整理核心流之上，深化体验：多 Tab 工具、主题体系、足迹地图、整理历史与统一弹窗。

## 功能矩阵

| 模块 | 状态 | 说明 |
|------|------|------|
| 相库 · 滑动整理 | ✅ | v1 核心流 + 会话内 3 步撤销 |
| 相库 · 整理历史 | ✅ | 按会话时间线，抽屉内查看照片与反悔 |
| 待删除页 | ✅ | 瀑布流、体积摘要、双 CTA |
| 智能 · 截图清理 | ✅ | 三档时间 + 列表批量删除 |
| 智能 · 相似图/大视频 | ⏳ | 灰态占位卡 |
| 足迹 Tab | ✅ | 地图、城市列表、海报分享 |
| 我的 Tab | ✅ | 设置内嵌（主题、地图样式、缓存、关于） |
| AppBar Actions | ✅ | 历史 / 雷达扫描 |
| 主题系统 | ✅ | 跟随系统 + 浅/深手动切换 |
| UniversalModal | ✅ | 全局确认弹窗 |
| 启动图 / 图标 | ✅ | 浅/深启动图、应用图标 |

## Tab 结构

```
相库 (/home)     — 选相册、开始整理、整理历史
智能 (/smart)    — 截图清理、雷达刷新
足迹 (/footprints) — 地图 + 城市列表
我的 (/profile)  — 偏好设置与关于
```

整理流程（滑动、摘要、待删）为全屏路由，覆盖 Tab Bar。

## 模块文档

| 文档 | 内容 |
|------|------|
| [theme.md](./theme.md) | 设计 Token、主题切换 |
| [footprints.md](./footprints.md) | 足迹扫描、地图、隐私 |
| [app-bar-actions.md](./app-bar-actions.md) | 历史抽屉、雷达、我的 |
| [history-footprint-polish.md](./history-footprint-polish.md) | 历史时间线、海报地图截图 |
| [universal-modal.md](./universal-modal.md) | 确认弹窗规范 |
| [splash.md](./splash.md) | 启动图资源与更新方式 |

## 数据与版本

- SQLite **schema v3**：`footprint_assets`、`footprint_scan_meta` 等
- 设置键：`theme_preference`、`footprint_map_style`、`biometric_lock_enabled` 等（`app_settings` 表）
- 整理记录：`processed_records` + `sessions`（历史按 `session_id` 分组）

## 非功能需求

- **Local-First**：截图/足迹扫描、逆地理、整理记录均在设备本地
- **异步**：扫描走 Isolate；算体积不阻塞 UI
- **UI**：圆角 16、Large Title、玻璃 Tab Bar、`AppSpacing` / `AppRadius` token
- **平台**：iOS only

## 测试

```bash
flutter test                    # Widget / 单元（当前 22+ 项）
flutter test integration_test/  # 集成（需模拟器）
```

约定见 [../qa/README.md](../qa/README.md)。

## 显式不做（v1.1）

- 相似照片聚合、大视频清理、模糊检测（仅占位）
- 隐私保险箱 / 数据看板
- Android
- `local_auth` 实装（Face ID 为 UI 占位）

## 后续可扩展

- UniversalModal `input` 类型（替代新建相册 `AlertDialog`）
- 全局 `AppSpacing` 16/24 统一、图标 2px 描边
- Phase 2 智能能力实装
