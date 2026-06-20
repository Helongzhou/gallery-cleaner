# 相册主理人 — 文档索引

> 应用名称：**相册主理人**（包名 `album_organizer`）  
> 平台：**iOS 13+ · Android 10+（API 29）** · 当前版本 **v1.1.0+3**

## 从哪里读起

| 你想… | 去看 |
|--------|------|
| 了解当前版本有哪些功能 | [v1.1/README.md](./v1.1/README.md) |
| 查版本变更 | [CHANGELOG.md](./CHANGELOG.md) |
| 跑测试 / 排错 | [qa/README.md](./qa/README.md) |
| 追溯 v1 基线 PRD | [v1/README.md](./v1/README.md) |
| 查早期 UI 改版稿（历史） | [ui-redesign/README.md](./ui-redesign/README.md) |

## 目录结构

```
docs/
├── README.md           ← 本文件
├── CHANGELOG.md        ← 版本变更
├── qa/                 ← 测试与已知问题
├── v1/                 ← v1 基线 PRD（已实现）
├── v1.1/               ← 当前版本规格（主文档）
└── ui-redesign/        ← 历史设计稿（归档参考）
```

## v1.1 模块文档

| 文档 | 内容 |
|------|------|
| [v1.1/README.md](./v1.1/README.md) | 总览、功能矩阵、数据与路由 |
| [v1.1/theme.md](./v1.1/theme.md) | 深浅色 Token、主题切换 |
| [v1.1/footprints.md](./v1.1/footprints.md) | 足迹地图、扫描、海报 |
| [v1.1/app-bar-actions.md](./v1.1/app-bar-actions.md) | 相库历史 / 智能雷达 / 我的 |
| [v1.1/history-footprint-polish.md](./v1.1/history-footprint-polish.md) | 整理历史时间线、海报地图截图 |
| [v1.1/universal-modal.md](./v1.1/universal-modal.md) | 全局确认弹窗 |
| [v1.1/splash.md](./v1.1/splash.md) | 启动图（浅/深） |

## 架构速览

- **状态管理**：Riverpod（`providers/`）
- **路由**：`go_router` + `ShellRoute` 四 Tab（相库 / 智能 / 足迹 / 我的）
- **持久化**：SQLite（`AppDatabase`），设置项在 `app_settings` 表
- **相册**：`photo_manager` 读写系统相册；整理记录 `processed_records` + `sessions`
- **隐私**：截图/足迹扫描与逆地理均在本地；地图瓦片 HTTPS 联网

## 维护约定

1. **新功能**：在 `v1.1/` 增模块 md 或更新 README，并写入 `CHANGELOG.md`
2. **已实现**：文档标题注明 `状态：已实现`
3. **历史文档**：不删除，在 README 顶部标注归档；以 `v1.1/` 为现行准绳
