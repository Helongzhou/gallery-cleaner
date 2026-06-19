# v1.1 主题与设计 Token 规格

**状态：已决策，待实现**

## 决策汇总

| # | 议题 | 决策 |
|---|------|------|
| 1 | 主题模式 | 跟随系统（默认）+ 我的 Tab 手动三选一 |
| 2 | 落地范围 | 仅全局 Token 替换，不逐页改布局 |
| 3 | 深色强调 | 白底黑字 CTA + 白/浅灰强调色 |
| 4 | 我的 Tab | 极简：外观 SegmentedButton，其余占位 |
| 5 | 深色背景 | 全局统一 `#131313` |

---

## 主题模式

```dart
enum ThemePreference { system, light, dark }
```

- 默认：`system`（`ThemeMode.system`）
- 持久化：`SettingsRepository` → `theme_preference`
- `MaterialApp.themeMode` 由 Riverpod `themeModeProvider` 驱动

---

## 色板（来自设计稿）

### 浅色 Light

| Token | 值 |
|-------|-----|
| background / surface | `#FAF9FE` |
| on-surface | `#1A1B1F` |
| on-surface-variant | `#414755` |
| primary | `#0058BC` |
| on-primary | `#FFFFFF` |
| surface-container-low | `#F4F3F8` |
| surface-container-high | `#E9E7ED` |
| surface-container-highest | `#E3E2E7` |
| outline-variant | `#C1C6D7` |
| system-red / green / orange | `#FF3B30` / `#34C759` / `#FF9500` |

### 深色 Dark

| Token | 值 |
|-------|-----|
| background / surface | `#131313` |
| on-surface | `#FFFFFF` |
| on-surface-variant | `#A1A1A1` |
| primary（CTA 背景） | `#FFFFFF` |
| on-primary（CTA 文字） | `#000000` |
| surface-container-low | `#1C1B1B` |
| surface-container | `#212121` |
| surface-container-high | `#2B2B2B` |
| surface-container-highest | `#363636` |
| outline / outline-variant | `#393939` / `#2A2A2A` |
| 强调色（链接、选中 Tab） | `#FFFFFF` 或 `#E5E2E1` |

---

## 实现清单

1. `lib/shared/theme/app_colors.dart` — 对齐上表
2. `lib/shared/theme/app_theme.dart` — ColorScheme + 组件主题（NavigationBar、FilledButton）
3. `lib/models/theme_preference.dart` + `SettingsRepository` 读写
4. `lib/providers/theme_provider.dart` — `themeModeProvider`
5. `lib/app.dart` — 监听 `themeModeProvider`
6. `lib/features/profile/profile_screen.dart` — 替换占位，外观 SegmentedButton
7. `lib/router/app_router.dart` — profile 路由指向新页面

---

## 不在范围

- 逐页玻璃卡片 / Bento 布局重做
- 智能 Tab 设计稿全量 UI（相似图、大文件卡片等）
- 滑动页纯黑 `#000000` 分场景背景
