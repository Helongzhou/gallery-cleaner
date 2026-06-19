# 功能覆盖映射 — v1

| 功能 / 关注点 | 归属 |
|---------------|------|
| 来源相册选择 | `features/home/` + `PhotoLibraryService.listAlbums()` |
| 目标相册选择 / 新建 | `features/home/` + `PhotoLibraryService.createAlbum()` |
| 待整理数量计算 | `home` + `OrganizeRepository.getProcessedIds()` |
| 继续整理提示 | `features/home/` + `SessionService.getActiveSession()` |
| 待删除入口 | `features/home/` + `OrganizeRepository.getPendingDelete()` |
| Tinder 式滑动 | `features/swipe/` + swiper 组件 |
| 右滑加入相册 | `swipe` + `PhotoLibraryService.addToAlbum()` |
| 左滑标记删除 | `swipe` + `OrganizeRepository.markPendingDelete()` |
| 撤销 | `swipe` + `OrganizeRepository.undoLastAction()` |
| 滑动浮层 UI | `features/swipe/widgets/` |
| 缩略图加载 / 预加载 | `PhotoLibraryService.getThumbnail()` + swipe 预加载逻辑 |
| 整理完成摘要 | `features/summary/` + `SessionService.getSessionStats()` |
| 待删除网格预览 | `features/pending_delete/` |
| 批量确认删除 | `pending_delete` + `PhotoLibraryService.deleteAssets()` |
| 首次引导 | `features/onboarding/` + `AppSettings.hasSeenOnboarding` |
| 相册权限请求 | `PhotoLibraryService.requestPermission()` |
| 有限访问提示 | `shared/widgets/limited_access_banner.dart` |
| 权限被拒页 | `features/permission_denied/` |
| 已处理记录持久化 | `OrganizeRepository` + sqflite |
| 断点续整理 | `SessionService` + sqflite |
| 重新整理 | `home` + `OrganizeRepository.clearProcessed()` |
| 操作失败处理 | 各 service 统一 `Result<T, AppError>` 模式 |
| 简体中文文案 | `lib/l10n/` 或内联常量（v1 仅中文） |
| 深浅色主题 | `shared/theme/` + `ThemeMode.system` |

## 无归属项（v1 不做）

| 功能 | 状态 |
|------|------|
| Android 适配 | v1.1 |
| 视频整理 | v2 |
| AI 分类 | v2 |
| 云同步 | v2 |
| 照片编辑 | v2 |
| 搜索 / 筛选 | v2 |
| 多目标相册切换 | v2 |
| 系统级移出来源 | v2 |
| 撤销右滑时从系统相册移除 | [HITL] 待确认 |
