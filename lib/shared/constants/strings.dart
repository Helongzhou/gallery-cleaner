abstract final class AppStrings {
  static const appTitle = '相册主理人';
  static const sourceAlbum = '来源相册';
  static const targetAlbum = '目标相册';
  static const pendingCount = '待整理';
  static const startOrganize = '开始整理';
  static const continueOrganize = '继续整理';
  static const reorganize = '重新整理';
  static const allOrganized = '已全部整理完毕';
  static const createAlbum = '新建相册';
  static const pendingDelete = '待删除';
  static const swipeLeftDelete = '左滑标记删除';
  static const swipeRightOrganize = '右滑归入';
  static const undo = '撤销';
  static String undoWithCount(int count) => '撤销 ($count)';
  static const removeFromPending = '移出待删';
  static const organizeTabLabel = '整理';
  static const smartCleanup = '智能清理';
  static const smartPrivacyNote = '所有分析均在本地完成，不会上传至服务器';
  static const profileTitle = '我的';
  static const profileComingSoon = '数据看板、隐私保险箱等功能即将推出';
  static const screenshotCleanup = '截图清理';
  static const screenshotCleanupHint = '清理失效的屏幕截图，释放空间';
  static const cleanSelected = '清理所选';
  static const screenshotBucket30 = '30 天前';
  static const screenshotBucket90 = '90 天前';
  static const screenshotBucket365 = '1 年前';
  static const organizeComplete = '整理完成';
  static const backHome = '返回首页';
  static const organizeOther = '整理其他相册';
  static const viewPendingDelete = '查看待删除';
  static const confirmDelete = '确认删除';
  static const restore = '恢复选中项';
  static const selectAll = '全选';
  static const deselectAll = '取消全选';
  static const deleteConfirmTitle = '确认删除照片？';
  static const deleteConfirmIosNote =
      '照片将移入系统「最近删除」，30 天内可在系统相册中恢复。';
  static const deleteConfirmAndroidNote =
      '照片将移入系统回收站，可在系统相册中恢复或清空。';
  static const deleteConfirmAndroidSystemHint =
      '随后将弹出系统确认，请点击「允许」完成删除。';
  static const deleteNothingMessage = '未删除任何照片，请在系统弹窗中点允许';
  static const deleteConfirmBody = deleteConfirmIosNote;

  static String deleteConfirmContent({bool android = false}) {
    final note = android ? deleteConfirmAndroidNote : deleteConfirmIosNote;
    if (android) {
      return '$note\n$deleteConfirmAndroidSystemHint';
    }
    return note;
  }

  static String deleteConfirmScreenshots(int count, {bool android = false}) {
    final destination = android ? '系统回收站' : '系统「最近删除」';
    final base = '将删除 $count 张截图，移入$destination。';
    if (android) {
      return '$base\n$deleteConfirmAndroidSystemHint';
    }
    return base;
  }

  static String pendingDeleteTrashHint({bool android = false}) {
    if (android) {
      return '确认删除后，照片将移入系统回收站，可在系统相册中恢复或清空。';
    }
    return '确认删除后，照片将移入系统「最近删除」，30 天内可恢复。';
  }

  static String deletePartialMessage(int successCount, int failedCount) =>
      '成功 $successCount 张，失败 $failedCount 张';

  static String deleteSuccessMessage(int count) => '已删除 $count 张';

  static String pendingDeleteStaleRemovedMessage(int count) =>
      '$count 张照片已不在相册，已从待删除列表移除';

  static String screenshotCleanSuccessMessage(int count) => '已清理 $count 张截图';
  static const resetOrganizeTitle = '重置整理记录？';
  static const resetOrganizeBody =
      '将清空所有整理进度、待删除列表和扫描缓存。\n'
      '手机相册里的照片不会被删除或移动，可重新开始整理。';
  static const resetOrganizeConfirm = '重置';
  static const resetOrganizeSuccess = '已重置，可重新开始整理';

  static String resetOrganizeSuccessDetail({
    required int processedCount,
    required int pendingDeleteCount,
  }) =>
      '已重置：整理记录 $processedCount 条，待删除 $pendingDeleteCount 条，扫描缓存已清空';
  static const clearScanCacheHint = '仅清除截图与足迹扫描缓存，不影响整理记录';
  static const clearScanCacheSuccess = '已清除扫描缓存';
  static const resetOrganizeLabel = '重置整理记录';
  static const clearScanCacheLabel = '清除扫描缓存';
  static const dataManagementSection = '数据管理';
  static const limitedAccessHint = '当前仅可访问部分照片';
  static const addMorePhotos = '添加更多照片';
  static const permissionDeniedTitle = '需要相册权限';
  static const permissionDeniedBody = '请在系统设置中允许访问相册，才能整理照片。';
  static const openSettings = '去设置';
  static const skip = '跳过';
  static const getStarted = '开始使用';
  static const footprintsTitle = '足迹';
  static const footprintsPrivacyNote = '位置信息仅在本地解析，地图瓦片联网加载，照片与坐标不会上传';
  static const footprintsPermissionBody =
      '我们需要读取照片位置信息以生成您的专属足迹，所有数据仅保存在本地。请在设置中允许完全访问相册。';
  static const footprintsEmptyBody = '相册中暂无带位置信息的照片，去记录你的第一步吧';
}
