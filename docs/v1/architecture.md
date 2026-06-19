# 技术架构 — v1

## 技术栈

| 层 | 选型 |
|----|------|
| 框架 | Flutter 3.x |
| 平台 | iOS only（`platform: ios`） |
| 相册读写 | `photo_manager` |
| 权限 | `permission_handler` |
| 本地存储 | `sqflite`（或 `drift`） |
| 路由 | `go_router` |
| 状态管理 | `flutter_riverpod` |
| 滑动卡片 | `flutter_card_swiper` 或 `appinio_swiper` |

---

## 页面结构

```
/                     首页（选来源/目标）
/onboarding           首次引导
/swipe                滑动整理
/summary              整理完成摘要
/pending-delete       待删除确认
/permission-denied    权限被拒说明
```

---

## 数据模型

### ProcessedRecord

```dart
class ProcessedRecord {
  String assetId;        // PHAsset localIdentifier
  String sourceAlbumId;
  String? targetAlbumId; // 右滑时有值
  ProcessAction action;  // organized | pendingDelete
  DateTime processedAt;
  String? sessionId;
}

enum ProcessAction { organized, pendingDelete }
```

### PendingDeleteItem

```dart
class PendingDeleteItem {
  String assetId;
  String sourceAlbumId;
  DateTime markedAt;
}
```

### ActiveSession

```dart
class ActiveSession {
  String sessionId;
  String sourceAlbumId;
  String targetAlbumId;
  DateTime startedAt;
  bool isCompleted;
}
```

### AppSettings

```dart
class AppSettings {
  bool hasSeenOnboarding;
}
```

---

## 核心服务边界

### PhotoLibraryService

| 方法 | 说明 |
|------|------|
| `requestPermission()` | 请求相册权限 |
| `getPermissionStatus()` | 完全 / 有限 / 拒绝 |
| `listAlbums()` | 系统相册列表 + 数量 |
| `createAlbum(name)` | 新建系统相册 |
| `getAssets(albumId, {excludeProcessed})` | 获取待整理照片 |
| `addToAlbum(assetId, albumId)` | 右滑：加入目标相册 |
| `deleteAssets(assetIds)` | 确认删除：移入系统最近删除 |
| `getThumbnail(assetId, size)` | 滑动页缩略图 |
| `presentLimitedLibraryPicker()` | iOS 有限访问扩展选图 |

### OrganizeRepository

| 方法 | 说明 |
|------|------|
| `markOrganized(assetId, source, target, sessionId)` | 右滑落库 |
| `markPendingDelete(assetId, source, sessionId)` | 左滑落库 |
| `undoLastAction(sessionId)` | 撤销最近 1 次 |
| `getProcessedIds(sourceAlbumId)` | 过滤已处理 |
| `clearProcessed(sourceAlbumId)` | 重新整理 |
| `getPendingDelete()` | 待删除列表 |
| `removePendingDelete(assetIds)` | 恢复 / 删除后清理 |

### SessionService

| 方法 | 说明 |
|------|------|
| `startSession(source, target)` | 创建会话 |
| `getActiveSession()` | 断点续整理 |
| `completeSession(sessionId)` | 标记完成 |
| `getSessionStats(sessionId)` | 摘要页统计 |

---

## 滑动页数据流

```
加载来源相册 assets
  → 过滤 processedRecords
  → 按时间倒序排列
  → 预加载 index+1, index+2 缩略图

右滑:
  → PhotoLibraryService.addToAlbum()
  → OrganizeRepository.markOrganized()
  → 移除当前卡片，显示 Snackbar

左滑:
  → OrganizeRepository.markPendingDelete()
  → 移除当前卡片，显示 Snackbar

撤销:
  → OrganizeRepository.undoLastAction()
  → 若上次是右滑：不撤回系统相册（[HITL] 是否 v1 也从相册移除？建议 v1 不撤回系统操作，仅恢复队列位置并删除 processed 记录）
```

### [HITL] 撤销右滑是否撤回系统相册加入？

**v1 建议**：撤销仅恢复 App 内状态（processed 记录），**不**从目标系统相册移除已加入的照片。理由：iOS 移除需要额外 API 调用，且用户可能已继续滑了很多张。在引导中说明：「撤销仅恢复整理队列，已归入相册的照片请手动处理」。若你不同意，标记为 v1 必须实现。

---

## iOS 权限配置

`Info.plist`:
- `NSPhotoLibraryUsageDescription`
- `NSPhotoLibraryAddUsageDescription`

---

## 性能约束

- 滑动卡片：屏幕逻辑分辨率缩略图，不加载原图
- 预加载：当前 + 下 2 张
- 待删除网格：200×200 缩略图
- DB 写入：每次滑动同步写入（单条 INSERT，< 10ms）

---

## 项目目录建议

```
lib/
├── main.dart
├── app.dart
├── router/
├── features/
│   ├── onboarding/
│   ├── home/
│   ├── swipe/
│   ├── summary/
│   └── pending_delete/
├── services/
│   ├── photo_library_service.dart
│   ├── organize_repository.dart
│   └── session_service.dart
├── models/
└── shared/
    ├── theme/
    └── widgets/
```
