# 相册整理

Tinder 式滑动整理 iOS 系统相册的 Flutter App。

## 功能（v1）

- 选择来源相册 + 目标相册，逐张滑动整理
- 右滑归入目标系统相册
- 左滑标记待删除，统一确认后删除
- 撤销最近 1 次操作、断点续整理

## 规格文档

见 [docs/v1/README.md](docs/v1/README.md)

## 开发

```bash
# 安装依赖
flutter pub get

# iOS 运行（需连接真机或模拟器）
flutter run

# 静态分析
dart analyze lib

# 测试
flutter test
```

## 项目结构

```
lib/
├── main.dart / app.dart
├── router/           # go_router 路由
├── features/         # 页面（onboarding, home, swipe, summary, pending_delete）
├── services/         # 相册、数据库、会话服务
├── models/           # 数据模型
├── providers/        # Riverpod providers
└── shared/           # 主题、常量、通用组件
```

## 技术栈

- Flutter 3.x · iOS only
- Riverpod · go_router
- photo_manager · permission_handler · sqflite
- flutter_card_swiper
