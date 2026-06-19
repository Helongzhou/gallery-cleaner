abstract final class OrganizeMode {
  /// 仅删除模式，不写入目标相册
  static const deleteOnlyTargetId = '__delete_only__';

  static bool isDeleteOnly(String? targetId) =>
      targetId == null || targetId.isEmpty || targetId == deleteOnlyTargetId;
}
