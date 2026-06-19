# AppBar Actions 规格（v1.1）

**状态：已实现**

## 相库 · 整理历史

- 图标：`Icons.history`，有可撤销记录时显示红点
- 右侧 55% 抽屉，`easeOutCubic` 300ms
- **时间线**：最近 20 次整理会话（来源→目标 · 整理/待删统计）
- 点击会话 → 抽屉内二级展开该次照片列表
- 逐条「反悔」：`pending_delete` 删标记；`organized` 从目标相册移除 + 删记录
- 撤销后 `homeRefreshProvider` 刷新待整理/待删数字

## 智能 · 雷达扫描

- 图标：`Icons.radar`，点击 `forceRefresh` 截图扫描
- 按钮旋转动画 + 卡片骨架 + 完成 haptic
- 灰态占位卡：相似照片、超大视频

## 我的

- 无 AppBar 操作按钮；设置项直接内嵌在「我的」Tab 页
- 个性化：主题模式、足迹地图样式（跟随系统 / 浅 / 深）
- 隐私安全：Face ID 占位
- 缓存管理：清除扫描缓存
- 关于与反馈：版本 v1.1.0、意见反馈（复制邮箱）

## 工程

- `LargeTitleHeader.trailing` 可配置 Action
- `AppMotion` 动画常量
- 设置持久化：`SettingsRepository`（无 shared_preferences）
