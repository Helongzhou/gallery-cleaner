# UI 改版规格总览

> 基于设计稿 + [Apple HIG](https://developer.apple.com/cn/design/human-interface-guidelines/) + [HIG Layout](https://developer.apple.com/cn/design/human-interface-guidelines/layout)

## 一句话

将现有 v1 功能页重构为 iOS 原生感设计：设计 token 体系、Tab Shell 导航、5 页视觉升级。

## 核心决策摘要

| 维度 | 决策 |
|------|------|
| 设计体系 | 完整 color/typography/spacing token，浅/深两套 |
| 字体 | SF Pro / PingFang SC，字号层级对齐设计稿 |
| 首页来源 | 16:10 大卡片 + 底部 Sheet 选择 |
| 首页目标 | 横向滚动缩略图 + 选中蓝环 +「查看全部」Sheet |
| 首页结构 | Large Title + 固定底栏 CTA + Tab Bar |
| 导航 | ShellRoute，整理流程全屏覆盖 Tab Bar |
| Tab Bar | 4 Tab 壳，仅「相库」可用 |
| 滑动页 | 印章反馈 + 进度条 + 撤销，无分享/收藏 |
| 完成页 | Bento 双卡片 + 勾选动画，无 MB 估算 |
| 待删除页 | 无缝网格 + 红色选中态 + 固定底栏 |
| 引导页 | 同步换新设计体系，3 步不变 |
| 微交互 | 关键 Haptic + 按钮 scale(0.97) |
| 深色模式 | 推导深色 token，跟随系统 |

## 文档索引

| 文件 | 内容 |
|------|------|
| [design-tokens.md](./design-tokens.md) | 颜色、字体、间距、圆角 |
| [screen-specs.md](./screen-specs.md) | 5 页逐屏规格 |
| [architecture.md](./architecture.md) | 导航架构、共享组件 |
| [coverage-map.md](./coverage-map.md) | 元素 → 组件归属 |

## 本次不做

智能/共享/我的真实功能、分享收藏、MB 体积、地点信息、网格入场动画、Inter 字体、手动主题切换、Android
