# Album Organizer (相册主理人) - Code Wiki

## 项目概述

**相册主理人** 是一款跨平台（iOS/Android）的相册管理应用，采用 Tinder 式滑动交互帮助用户快速整理照片。核心功能包括：

- **滑动整理**：左滑标记删除，右滑归入目标相册
- **足迹地图**：基于照片地理位置生成个人足迹地图
- **截图清理**：智能识别并清理过期屏幕截图
- **隐私优先**：所有数据处理均在本地完成

---

## 技术栈

| 类别 | 技术 |
|------|------|
| 框架 | Flutter 3.12+ |
| 状态管理 | Riverpod 2.6+ |
| 路由 | GoRouter 14.8+ |
| 数据库 | SQLite (sqflite) |
| 相册访问 | photo_manager 3.6+ |
| 权限处理 | permission_handler 11.4+ |
| 地图 | flutter_map 8.3 + flutter_map_marker_cluster |
| 卡片滑动 | flutter_card_swiper 7.0+ |
| 地理编码 | geocoding 4.0+ |
| 国际化 | intl 0.20+ |
| 图标 | flutter_lucide 1.11+ |

---

## 目录结构

```
lib/
├── main.dart                      # 应用入口
├── bootstrap.dart                 # ProviderScope 初始化
├── app.dart                       # AlbumOrganizerApp 主应用 widget
├── features/                      # 功能模块
│   ├── footprints/               # 足迹功能
│   ├── home/                    # 首页
│   ├── onboarding/              # 引导页
│   ├── pending_delete/          # 待删除管理
│   ├── permission_denied/       # 权限拒绝页
│   ├── placeholder/             # 占位页
│   ├── profile/                 # 个人中心
│   ├── smart/                   # 智能清理
│   ├── summary/                 # 整理摘要
│   └── swipe/                   # 滑动整理
├── models/                       # 数据模型
├── providers/                    # Riverpod 状态提供者
├── router/                       # 路由配置
├── services/                    # 业务服务层
│   └── database/                 # 数据库相关
└── shared/                      # 共享资源
    ├── constants/               # 常量定义
    ├── shell/                   # 页面壳
    ├── theme/                   # 主题配置
    ├── utils/                   # 工具函数
    └── widgets/                 # 通用组件
```

---

## 核心模块详解

### 1. 应用入口与引导

**文件**: [main.dart](file:///Users/zhoudaxia/Documents/album-organizer/lib/main.dart)

```dart
void main() => runAlbumOrganizerApp();
```

**文件**: [bootstrap.dart](file:///Users/zhoudaxia/Documents/album-organizer/lib/bootstrap.dart)

```dart
void runAlbumOrganizerApp({List<Override> overrides = const []}) {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(ProviderScope(overrides: overrides, child: const AlbumOrganizerApp()));
}
```

**文件**: [app.dart](file:///Users/zhoudaxia/Documents/album-organizer/lib/app.dart)

应用主组件，负责：
- 初始化路由 (`routerProvider`)
- 管理主题模式 (`themeModeProvider`)
- 配置 MaterialApp.router

---

### 2. 路由系统

**文件**: [router/app_router.dart](file:///Users/zhoudaxia/Documents/album-organizer/lib/router/app_router.dart)

采用 GoRouter 实现声明式路由：

| 路由路径 | 页面 | 说明 |
|---------|------|------|
| `/` | HomeScreen | 首页（整理入口） |
| `/smart` | SmartScreen | 智能清理 |
| `/smart/screenshots` | ScreenshotListScreen | 截图列表 |
| `/footprints` | FootprintsScreen | 足迹地图 |
| `/profile` | ProfileScreen | 个人中心 |
| `/swipe` | SwipeScreen | 滑动整理页面 |
| `/summary` | SummaryScreen | 整理摘要 |
| `/pending-delete` | PendingDeleteScreen | 待删除管理 |
| `/onboarding` | OnboardingScreen | 引导页 |
| `/permission-denied` | PermissionDeniedScreen | 权限拒绝页 |

**关键类型**:

```dart
class SwipeRouteArgs {
  final String sessionId;
  final String sourceAlbumId;
  final String sourceAlbumName;
  final String? targetAlbumId;
  final String? targetAlbumName;
  final int totalCount;
  final int initialIndex;
  final bool deleteOnly;
}

class SummaryRouteArgs {
  final String sessionId;
  final String? targetAlbumName;
  final String? targetAlbumId;
  final int totalProcessed;
  final int organizedCount;
  final int pendingDeleteCount;
  final bool deleteOnly;
}
```

---

### 3. 数据模型

**文件**: [models/](file:///Users/zhoudaxia/Documents/album-organizer/lib/models)

#### AlbumInfo
```dart
class AlbumInfo {
  final String id;
  final String name;
  final int assetCount;
  final bool isWritable;
}
```

#### PhotoAssetInfo
照片资产信息（不含图片数据，仅元数据）

#### ProcessAction
```dart
enum ProcessAction {
  organized,     // 已归入目标相册
  pendingDelete, // 待删除
}
```

#### ProcessedRecord
整理记录实体：
```dart
class ProcessedRecord {
  final int? id;
  final String assetId;
  final String sourceAlbumId;
  final String? targetAlbumId;
  final ProcessAction action;
  final DateTime processedAt;
  final String? sessionId;
}
```

#### ActiveSession
活跃整理会话

#### SessionStats
会话统计数据

#### ScreenshotBucket
截图时间分桶：`bucket30`、`bucket90`、`bucket365`

#### FootprintAsset
足迹资产（含经纬度信息）

#### CityFootprint
城市足迹聚合

---

### 4. 服务层

**文件**: [services/](file:///Users/zhoudaxia/Documents/album-organizer/lib/services)

#### PhotoLibraryService
负责与系统相册交互，是核心服务之一：

```dart
class PhotoLibraryService {
  // 权限管理
  Future<PhotoPermissionStatus> getPermissionStatus();
  Future<PhotoPermissionStatus> requestPermission();
  Future<void> ensureMediaLocationAccess();

  // 相册操作
  Future<AppResult<List<AlbumInfo>>> listAlbums({bool writableOnly = false});
  Future<AppResult<AlbumInfo>> createAlbum(String name);
  Future<bool> isAssetInAlbum(String assetId, String albumId);

  // 照片操作
  Future<AppResult<List<PhotoAssetInfo>>> getAssets({...});
  Future<AppResult<void>> addToAlbum({...});
  Future<AppResult<DeleteResult>> deleteAssets(List<String> assetIds);
  Future<AppResult<void>> removeFromAlbum({...});

  // 截图相关
  Future<AppResult<List<PhotoAssetInfo>>> getScreenshotAssetsOlderThan(DateTime cutoff);

  // 足迹扫描
  Future<({List<RawGeoAsset> geoTagged, int withoutGps})> scanGeoTaggedAssets({...});

  // 缩略图
  Future<Uint8List?> getThumbnail({required String assetId, ...});
}
```

#### OrganizeRepository
整理记录持久化，基于 SQLite：

```dart
class OrganizeRepository {
  // 标记操作
  Future<AppResult<void>> markOrganized({...});
  Future<AppResult<void>> markPendingDelete({...});

  // 撤销
  Future<AppResult<SwipeAction?>> undoLastAction(String sessionId);
  Future<AppResult<SwipeAction?>> undoByRecordId(int recordId);

  // 查询
  Future<Set<String>> getProcessedIds(String sourceAlbumId);
  Future<List<PendingDeleteItem>> getPendingDelete();
  Future<List<HistoryEntry>> getRecentHistory({...});
  Future<List<HistorySession>> getRecentHistorySessions({...});

  // 重置
  Future<void> clearProcessed(String sourceAlbumId);
  Future<void> resetAllOrganizeState();
}
```

#### SessionService
整理会话管理：

```dart
class SessionService {
  Future<ActiveSession> startSession({sourceAlbumId, targetAlbumId});
  Future<ActiveSession?> getActiveSession();
  Future<void> completeSession(String sessionId);
  Future<SessionStats> getSessionStats(String sessionId);
}
```

#### SettingsRepository
应用设置持久化：

```dart
class SettingsRepository {
  Future<String?> getLastTargetAlbumId();
  Future<void> setLastTargetAlbumId(String? albumId);
  Future<bool> hasSeenOnboarding();
  Future<void> setHasSeenOnboarding(bool value);
  Future<ThemePreference> getThemePreference();
  Future<void> setThemePreference(ThemePreference preference);
  Future<FootprintMapStyle> getFootprintMapStyle();
  Future<void> setFootprintMapStyle(FootprintMapStyle style);
}
```

#### ScreenshotScanService
截图扫描与缓存：

```dart
class ScreenshotScanService {
  Future<Map<ScreenshotBucket, int>> getCounts({bool forceRefresh = false});
  Future<List<PhotoAssetInfo>> getAssets(ScreenshotBucket bucket, {...});
}
```

#### FootprintScanService
足迹扫描服务：

```dart
class FootprintScanService {
  Future<FootprintScanResult> load({bool forceRefresh = false});
}
```

#### GeocodingService
地理编码服务（含内存缓存）：

```dart
class GeocodingService {
  Future<GeocodeResult> reverseGeocode(double lat, double lng);
  static String cellKey(double lat, double lng); // 缓存 key
}
```

#### CacheClearService
缓存清理服务

---

### 5. 数据库设计

**文件**: [services/database/app_database.dart](file:///Users/zhoudaxia/Documents/album-organizer/lib/services/database/app_database.dart)

数据库版本：3

| 表名 | 说明 |
|------|------|
| `processed_records` | 照片整理记录 |
| `pending_delete` | 待删除照片列表 |
| `sessions` | 整理会话 |
| `app_settings` | 应用设置 KV 存储 |
| `screenshot_scan_cache` | 截图扫描缓存 |
| `footprint_assets` | 足迹资产数据 |
| `footprint_scan_meta` | 足迹扫描元数据 |

---

### 6. 状态管理

**文件**: [providers/providers.dart](file:///Users/zhoudaxia/Documents/album-organizer/lib/providers/providers.dart)

核心 Provider：

```dart
final databaseProvider = Provider<AppDatabase>(...);
final photoLibraryServiceProvider = Provider<PhotoLibraryService>(...);
final organizeRepositoryProvider = Provider<OrganizeRepository>(...);
final sessionServiceProvider = Provider<SessionService>(...);
final settingsRepositoryProvider = Provider<SettingsRepository>(...);
final screenshotCacheRepositoryProvider = Provider<ScreenshotCacheRepository>(...);
final screenshotScanServiceProvider = Provider<ScreenshotScanService>(...);
final cacheClearServiceProvider = Provider<CacheClearService>(...);
```

#### HomeController / HomeState
首页状态管理：

```dart
class HomeState {
  final bool isInitialLoading;
  final bool isRefreshing;
  final String? error;
  final PhotoPermissionStatus? permission;
  final List<AlbumInfo> allAlbums;
  final List<AlbumInfo> writableAlbums;
  final AlbumInfo? source;
  final String targetSelectionId;
  final int pendingDeleteCount;
  final int pendingOrganizeCount;
  final String? activeSessionHint;
  final Uint8List? sourceCover;
  final Map<String, Uint8List?> targetCovers;
}

final homeControllerProvider = StateNotifierProvider<HomeController, HomeState>(...);
```

#### FootprintController / FootprintState
足迹功能状态管理

---

### 7. 主题系统

**文件**: [shared/theme/app_theme.dart](file:///Users/zhoudaxia/Documents/album-organizer/lib/shared/theme/app_theme.dart)

支持亮色/暗色模式，基于 Material 3：

```dart
class AppTheme {
  static ThemeData light();
  static ThemeData dark();
}

extension AppThemeExtension on BuildContext {
  bool get isDarkMode;
  Color get appBackground;
  Color get appSurfaceContainerHigh;
  Color get appPrimary;
  // ...
}
```

**颜色常量**: [shared/theme/app_colors.dart](file:///Users/zhoudaxia/Documents/album-organizer/lib/shared/theme/app_colors.dart)

---

### 8. 共享组件

**文件**: [shared/widgets/](file:///Users/zhoudaxia/Documents/album-organizer/lib/shared/widgets)

| 组件 | 说明 |
|------|------|
| `LargeTitleHeader` | 大标题头部 |
| `HeaderActionButton` | 头部操作按钮 |
| `AlbumSourceCard` | 来源相册卡片 |
| `AlbumTargetCarousel` | 目标相册轮播选择器 |
| `PendingDeleteEntry` | 待删除入口 |
| `LimitedAccessBanner` | 限权访问提示条 |
| `LoadingView` | 加载视图 |
| `ErrorView` | 错误视图 |
| `UniversalModal` | 通用模态框 |
| `WaterfallGrid` | 瀑布流网格 |
| `GlassContainer` | 毛玻璃容器 |
| `AppPressable` | 按压反馈组件 |

---

### 9. 功能模块详解

#### 首页 (HomeScreen)
[features/home/home_screen.dart](file:///Users/zhoudaxia/Documents/album-organizer/lib/features/home/home_screen.dart)

核心流程：
1. 检查相册权限
2. 加载相册列表
3. 选择来源相册和目标相册
4. 启动整理会话

#### 滑动整理 (SwipeScreen)
[features/swipe/swipe_screen.dart](file:///Users/zhoudaxia/Documents/album-organizer/lib/features/swipe/swipe_screen.dart)

基于 `flutter_card_swiper` 实现：
- 右滑 → 归入目标相册
- 左滑 → 标记删除
- 支持撤销操作
- 批量预加载缩略图

#### 足迹 (FootprintsScreen)
[features/footprints/footprints_screen.dart](file:///Users/zhoudaxia/Documents/album-organizer/lib/features/footprints/footprints_screen.dart)

功能：
- 扫描带 GPS 的照片
- 逆地理编码获取城市信息
- 在地图上显示足迹点
- 按城市分组展示
- 生成并分享足迹海报

#### 智能清理 (SmartScreen)
[features/smart/smart_screen.dart](file:///Users/zhoudaxia/Documents/album-organizer/lib/features/smart/smart_screen.dart)

截图清理功能：
- 按时间分桶（30天/90天/1年）
- 缓存扫描结果
- 批量删除截图

---

### 10. 常量定义

**文件**: [shared/constants/strings.dart](file:///Users/zhoudaxia/Documents/album-organizer/lib/shared/constants/strings.dart)

```dart
abstract final class AppStrings {
  static const appTitle = '相册主理人';
  static const sourceAlbum = '来源相册';
  static const targetAlbum = '目标相册';
  // ... 大量 UI 文本常量
}
```

**文件**: [shared/constants/organize_constants.dart](file:///Users/zhoudaxia/Documents/album-organizer/lib/shared/constants/organize_constants.dart)

整理相关常量，如 `maxUndoStepsPerSession`、`maxAlbumNameLength`

**文件**: [shared/constants/organize_mode.dart](file:///Users/zhoudaxia/Documents/album-organizer/lib/shared/constants/organize_mode.dart)

```dart
abstract final class OrganizeMode {
  static const deleteOnlyTargetId = '__delete_only__';
  static bool isDeleteOnly(String? id) => id == deleteOnlyTargetId;
}
```

---

### 11. Result 类型

**文件**: [shared/result.dart](file:///Users/zhoudaxia/Documents/album-organizer/lib/shared/result.dart)

类似 Rust 的 Result 模式：

```dart
sealed class AppResult<T> {}

final class AppSuccess<T> extends AppResult<T> {
  final T value;
}

final class AppFailure<T> extends AppResult<T> {
  final String message;
  final Object? cause;
}
```

---

## 项目运行

### 环境要求
- Flutter SDK 3.12+
- Dart SDK ^3.12.1
- iOS 12.0+ / Android API 21+

### 依赖安装
```bash
flutter pub get
```

### 运行应用
```bash
# 开发模式
flutter run

# iOS
flutter run -d ios

# Android
flutter run -d android
```

### 构建发布
```bash
# iOS
flutter build ios --release

# Android
flutter build apk --release
```

---

## 架构特点

1. **分层清晰**：UI → Controller/Provider → Service → Repository → Database
2. **状态管理**：Riverpod 实现响应式状态，StateNotifier 封装复杂状态
3. **路由分离**：路由配置与业务逻辑分离
4. **服务抽象**：PhotoLibraryService 封装平台差异
5. **本地优先**：所有数据处理在本地完成，保护用户隐私
6. **缓存策略**：多级缓存（内存 + SQLite）提升性能
