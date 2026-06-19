# UI 架构

## 导航结构

```
MaterialApp.router
└── ShellRoute (Tab Shell)
    ├── /library          → LibraryTab (首页)
    ├── /smart            → PlaceholderTab「智能」
    ├── /shared           → PlaceholderTab「共享」
    └── /profile          → PlaceholderTab「我的」

全屏路由（parentNavigatorKey: rootNavigatorKey）
├── /onboarding
├── /swipe
├── /summary
├── /pending-delete
└── /permission-denied
```

## 新增共享组件

```
lib/shared/
├── theme/
│   ├── app_colors.dart       # 浅/深 token
│   ├── app_typography.dart   # TextTheme 扩展
│   └── app_theme.dart        # 重构，引用 token
├── widgets/
│   ├── app_pressable.dart    # scale + haptic 封装
│   ├── glass_bottom_bar.dart # 毛玻璃底栏
│   ├── large_title_header.dart
│   ├── primary_button.dart   # 圆角 16 主按钮
│   ├── album_source_card.dart
│   ├── album_target_carousel.dart
│   ├── pending_delete_entry.dart
│   ├── swipe_stamp_overlay.dart
│   ├── bento_stat_card.dart
│   └── photo_grid.dart       # 2px 无缝网格
└── shell/
    └── main_shell.dart       # Tab Bar + 底栏 CTA
```

## 首页布局结构

```dart
Scaffold(
  body: CustomScrollView(
    slivers: [
      LargeTitleHeader(...),
      SliverToBoxAdapter(child: SourceAlbumCard(...)),
      SliverToBoxAdapter(child: TargetAlbumCarousel(...)),
      SliverToBoxAdapter(child: PendingDeleteEntry(...)),
      SliverPadding(bottom: bottomBarHeight), // 为固定底栏留空
    ],
  ),
  bottomNavigationBar: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      GlassBottomBar(child: PrimaryButton('开始整理')),
      AppTabBar(...),
    ],
  ),
)
```

## Haptic 映射

| 事件 | API |
|------|-----|
| 滑动触发 | `HapticFeedback.mediumImpact()` |
| 撤销 | `HapticFeedback.lightImpact()` |
| 确认删除 | `HapticFeedback.heavyImpact()` |
| 选中相册/Tab | `HapticFeedback.selectionClick()` |

## 实现顺序建议

1. **Token 层**：`AppColors` + `AppTypography` + `AppTheme` 重构
2. **基础组件**：`AppPressable`、`PrimaryButton`、`GlassBottomBar`
3. **Shell**：`MainShell` + Tab 占位 + 路由改造
4. **首页**：来源卡片 + 目标横滑 + 底栏 CTA
5. **滑动页**：进度条 + 印章 + 卡片样式
6. **完成页**：Bento + 动画
7. **待删除页**：网格 + 底栏
8. **引导页**：视觉升级
