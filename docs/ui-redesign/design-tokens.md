# Design Tokens

## Colors

### Light

| Token | Hex | 用途 |
|-------|-----|------|
| `primary` | `#0058BC` | 主按钮、链接、选中态 |
| `onPrimary` | `#FFFFFF` | 主按钮文字 |
| `background` | `#FAF9FE` | 页面背景 |
| `surface` | `#FAF9FE` | 表面 |
| `surfaceContainerLowest` | `#FFFFFF` | 卡片背景 |
| `surfaceContainerLow` | `#F4F3F8` | 次级容器 |
| `surfaceContainerHigh` | `#E9E7ED` | 高亮容器、待删除入口 |
| `surfaceContainerHighest` | `#E3E2E7` | 撤销按钮背景 |
| `surfaceVariant` | `#E3E2E7` | 进度条轨道 |
| `onSurface` | `#1A1B1F` | 主文字 |
| `onSurfaceVariant` | `#414755` | 次级文字 |
| `outlineVariant` | `#C1C6D7` | 边框、分割线 |
| `systemRed` | `#FF3B30` | 删除 |
| `systemGreen` | `#34C759` | 归入/成功 |
| `systemOrange` | `#FF9500` | 待整理徽章 |
| `systemGray6` | `#F2F2F7` | 安全提示条背景 |

### Dark

| Token | Hex |
|-------|-----|
| `background` | `#1A1B1F` |
| `surface` | `#1A1B1F` |
| `surfaceContainerLowest` | `#2F3034` |
| `surfaceContainerHigh` | `#3A3B3F` |
| `onSurface` | `#F1F0F5` |
| `onSurfaceVariant` | `#C1C6D7` |
| `primary` | `#ADC6FF` |
| `systemRed/Green/Orange` | 与浅色相同 |

## Typography

使用系统字体，自定义 `TextTheme`：

| Token | Size | Line Height | Weight | Letter Spacing |
|-------|------|-------------|--------|----------------|
| `largeTitle` | 34 | 41 | 700 | 0.37 |
| `title1` | 28 | 34 | 700 | 0.36 |
| `headline` | 17 | 22 | 600 | -0.41 |
| `body` | 17 | 22 | 400 | -0.41 |
| `callout` | 16 | 21 | 400 | -0.32 |
| `subheadline` | 15 | 20 | 400 | -0.24 |
| `footnote` | 13 | 18 | 400 | -0.08 |
| `caption1` | 12 | 16 | 400 | 0 |

## Spacing

| Token | Value |
|-------|-------|
| `marginSide` | 16 |
| `stackTight` | 4 |
| `stackMedium` | 12 |
| `stackLoose` | 20 |
| `gutterDefault` | 8 |
| `gridUnit` | 8 |

## Border Radius

| Token | Value | 用途 |
|-------|-------|------|
| `radiusSm` | 8 | 小元素 |
| `radiusMd` | 12 | 卡片、输入框 |
| `radiusLg` | 16 | 主按钮、底栏按钮 |
| `radiusXl` | 24 | 滑动照片卡片 |
| `radiusFull` | 9999 | 圆形按钮、徽章 |

## Effects

| Token | 值 |
|-------|-----|
| `blurSigma` | 20 |
| `glassOpacity` | 0.8 |
| `activeScale` | 0.97 |
| `pressDuration` | 150ms |
| `selectedRingWidth` | 3px |
| `selectedRingColor` | `#0058BC` |
