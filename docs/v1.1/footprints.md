# 足迹 Tab 规格（v1.1）

**状态：已实现**

## 决策汇总

| 议题 | 决策 |
|------|------|
| 地图 | `flutter_map` + Carto 暗色瓦片（瓦片联网，GPS 本地） |
| 扫描 | 照片+视频，增量 SQLite 缓存，24h 全量校验 |
| 逆地理 | iOS `CLGeocoder`（`geocoding` 包）+ 内存/SQLite 缓存 |
| 聚合粒度 | 城市级，`城市 · 区县` 副标题 |
| 布局 | 地图 60% + 下方城市列表 |
| 海报 | 固定昵称「相册主理人」+ `share_plus` |
| 路由 | `/footprints`，`/shared` 重定向 |

## 模块

- `FootprintScanService` — 批量读 GPS、逆地理、写缓存
- `FootprintCacheRepository` — `footprint_assets` / `footprint_scan_meta`（DB v3）
- `FootprintsScreen` — 地图、城市列表、分享海报
- `FootprintMap` — `flutter_map_marker_cluster` 点聚合
- `showFootprintPhotoSheet` — 毛玻璃半屏 + 照片网格

## 隐私

- 照片坐标与 EXIF 不上传
- 地图瓦片从 Carto CDN 加载（HTTPS）
- 逆地理由系统 API 完成，结果仅存本地 SQLite

## 测试

- `test/footprint_city_grouper_test.dart`
- 模拟器需 fake GPS 或真机验证地图打点
