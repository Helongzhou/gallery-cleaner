# 相册主理人

Tinder 式滑动整理 iOS 系统相册的 Flutter 应用。在设备本地完成整理、清理与足迹解析，不上传照片。

**当前版本：v1.1.0** · iOS only

## 功能概览

| Tab | 能力 |
|-----|------|
| **相库** | 选择来源/目标相册，滑动整理；会话内 3 步撤销；整理历史时间线 |
| **智能** | 截图清理（30/90/365 天档位）；相似图 / 大视频占位 |
| **足迹** | GPS 照片地图打点、城市列表、分享海报（含地图截图） |
| **我的** | 主题、足迹地图样式、缓存清理、关于与反馈 |

核心整理流：选相册 → 右滑归入目标 → 左滑标记待删 → 统一确认删除。

## 环境要求

| 工具 | 说明 |
|------|------|
| Flutter | 3.x，Dart SDK `^3.12`（见 `pubspec.yaml`） |
| Xcode | 含 iOS SDK 与 Command Line Tools |
| CocoaPods | `pod` 可用（首次 `flutter run` 时会自动处理） |
| 平台 | **仅 iOS**（`IPHONEOS_DEPLOYMENT_TARGET = 13.0`） |

检查环境：

```bash
flutter doctor -v
xcodebuild -version
```

## 安装依赖

```bash
cd /path/to/相册整理
flutter pub get
```

## 运行（开发调试）

### 查看可用设备

```bash
flutter devices
```

### 模拟器

```bash
# 启动指定模拟器（可选，flutter run 也会自动拉起）
open -a Simulator

# 调试运行（推荐指定设备名，避免多设备歧义）
flutter run -d "iPhone 17 Pro"
```

### 真机

1. 用数据线连接 iPhone，在设备上信任电脑  
2. Xcode → **Signing & Capabilities** 配置 Team（Bundle ID：`com.albumorganizer.albumOrganizer`）  
3. 运行：

```bash
flutter run -d <device_id>   # device_id 来自 flutter devices
```

### 常用运行参数

```bash
# 指定构建模式（默认 debug）
flutter run -d "iPhone 17 Pro" --debug
flutter run -d "iPhone 17 Pro" --profile    # 性能分析
flutter run -d "iPhone 17 Pro" --release    # 接近正式包体验

# 热重载 / 热重启：终端内按 r / R
```

### 完整重装（改图标、启动图、原生资源后建议）

模拟器可能缓存旧图标或启动图，可清构建后再装：

```bash
flutter clean
flutter pub get
flutter run -d "iPhone 17 Pro"
```

若启动图未更新：在模拟器删除应用后冷启动一次。

## 打包（Release）

版本号在 `pubspec.yaml` 中维护（如 `1.1.0+2`：前者为显示版本，后者为构建号）。

### 构建 iOS Release（不签名 IPA）

```bash
flutter build ios --release
```

产物在 `build/ios/iphoneos/Runner.app`，可用于 Xcode 进一步归档。

### 构建 IPA（TestFlight / 内测分发）

需已在 Xcode 配置签名与 Provisioning Profile：

```bash
flutter build ipa --release
```

默认输出：`build/ios/ipa/*.ipa`

指定导出方式（可选）：

```bash
flutter build ipa --release --export-method app-store      # App Store / TestFlight
flutter build ipa --release --export-method ad-hoc         # 指定设备 UDID
flutter build ipa --release --export-method development    # 开发证书
```

### 通过 Xcode 归档（上架 App Store）

```bash
open ios/Runner.xcworkspace
```

Xcode 菜单：**Product → Archive** → **Distribute App**。

### 仅编译检查（不安装到设备）

```bash
flutter build ios --release --no-codesign
dart analyze lib
flutter test
```

## 资源生成

应用图标与启动图源文件在 `assets/`，修改后需重新生成或替换原生资源：

```bash
# 应用图标（源图：assets/icon/app_icon.png）
dart run flutter_launcher_icons

# 启动图：替换 assets/splash/splash_light.png、splash_dark.png 后
# 按 docs/v1.1/splash.md 重新生成 LaunchImage.imageset 各尺寸
```

## 质量检查

```bash
dart analyze lib
flutter test
flutter test integration_test/   # 需模拟器或真机
```

首次运行需授予相册权限。足迹地图瓦片联网加载（Carto CDN），照片与坐标仅存本地。

## 项目结构

```
lib/
├── main.dart / bootstrap.dart / app.dart
├── router/              # go_router 路由与 Shell
├── features/
│   ├── home/            # 相库首页、整理历史抽屉
│   ├── swipe/           # 滑动整理
│   ├── smart/           # 智能 Tab、截图清理
│   ├── footprints/      # 足迹地图与海报
│   ├── profile/         # 我的（设置内嵌）
│   ├── pending_delete/  # 待删除确认
│   └── onboarding/      # 引导
├── services/            # 相册、数据库、扫描、会话
├── models/
├── providers/           # Riverpod
└── shared/              # 主题、UniversalModal、通用组件
```

## 技术栈

- Flutter 3.x · Dart 3.12+
- Riverpod · go_router
- photo_manager · sqflite · permission_handler
- flutter_map · geocoding · share_plus
- flutter_card_swiper · flutter_lucide

## 文档

完整规格与变更记录见 **[docs/README.md](docs/README.md)**。

- [v1.1 当前版本](docs/v1.1/README.md)
- [CHANGELOG](docs/CHANGELOG.md)
- [QA / 测试](docs/qa/README.md)
